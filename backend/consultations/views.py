from datetime import timedelta
from django.utils import timezone
from django.db.models import Count, Sum
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from .models import Consultation, Message
from .serializers import (
    ConsultationSerializer,
    MessageSerializer,
    SendMessageSerializer,
    CreateConsultationSerializer,
)
from accounts.permissions import IsDoctor
from payments.models import Payment
from notifications.models import Notification
User = get_user_model()


def _publish_consultation_message(*a, **kw):
    try:
        from realtime.ably_service import publish_consultation_message as f
        f(*a, **kw)
    except ImportError:
        pass


def _publish_consultation_status(*a, **kw):
    try:
        from realtime.ably_service import publish_consultation_status as f
        f(*a, **kw)
    except ImportError:
        pass


def _publish_user_notification(*a, **kw):
    try:
        from realtime.ably_service import publish_user_notification as f
        f(*a, **kw)
    except ImportError:
        pass


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsDoctor])
def dashboard_stats(request):
    today = timezone.now()
    month_start = today.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    last_month_start = (month_start - timedelta(days=1)).replace(day=1)
    last_month_end = month_start
    doctor = request.user

    # Daily income (today)
    daily_income = (
        Payment.objects.filter(
            status="APPROVED",
            approved_at__date=today.date(),
        ).aggregate(total=Sum("amount"))["total"]
        or 0
    )

    # Monthly income (this month)
    monthly_income = (
        Payment.objects.filter(
            status="APPROVED",
            approved_at__gte=month_start,
        ).aggregate(total=Sum("amount"))["total"]
        or 0
    )

    # Last month income (for comparison)
    last_month_income = (
        Payment.objects.filter(
            status="APPROVED",
            approved_at__gte=last_month_start,
            approved_at__lt=last_month_end,
        ).aggregate(total=Sum("amount"))["total"]
        or 0
    )

    total_patients = User.objects.filter(role="PATIENT").count()

    # New patients this period vs previous period
    thirty_days_ago = today - timedelta(days=30)
    sixty_days_ago = today - timedelta(days=60)
    new_patients_recent = User.objects.filter(
        role="PATIENT", date_joined__gte=thirty_days_ago
    ).count()
    new_patients_previous = User.objects.filter(
        role="PATIENT", date_joined__gte=sixty_days_ago, date_joined__lt=thirty_days_ago
    ).count()

    completed = Consultation.objects.filter(doctor=doctor, status="RESOLVED").count()
    in_progress = Consultation.objects.filter(doctor=doctor, status="ACTIVE").count()
    pending = Payment.objects.filter(status="PENDING").count()
    unread_notifications = Notification.objects.filter(
        recipient=doctor, is_read=False
    ).count()

    # Percentage changes
    def pct_change(current, previous):
        if previous == 0:
            return 100.0 if current > 0 else 0.0
        return round(((current - previous) / previous) * 100, 1)

    patient_change = pct_change(new_patients_recent, new_patients_previous)
    income_change = pct_change(monthly_income, last_month_income)

    return Response({
        "daily_income": float(daily_income),
        "monthly_income": float(monthly_income),
        "total_patients": total_patients,
        "patient_change": patient_change,
        "income_change": income_change,
        "completed_consultations": completed,
        "in_progress_consultations": in_progress,
        "pending_payments": pending,
        "unread_notifications": unread_notifications,
    })


@api_view(["POST"])
@permission_classes([IsAuthenticated, IsDoctor])
def create_consultation(request):
    serializer = CreateConsultationSerializer(data=request.data)
    if serializer.is_valid():
        try:
            patient = User.objects.get(
                id=serializer.validated_data["patient_id"], role="PATIENT"
            )
        except User.DoesNotExist:
            return Response(
                {"detail": "Patient not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        has_paid = Payment.objects.filter(
            patient=patient, status="APPROVED"
        ).exists()
        if not has_paid:
            return Response(
                {"detail": "Patient has no approved payment. Verify payment first."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        existing = Consultation.objects.filter(
            patient=patient, doctor=request.user, status="ACTIVE"
        ).first()
        if existing:
            out = ConsultationSerializer(existing)
            return Response(out.data, status=status.HTTP_200_OK)

        consultation = Consultation.objects.create(
            patient=patient,
            doctor=request.user,
            intake_id=serializer.validated_data.get("intake_id"),
        )

        Notification.objects.create(
            recipient=patient,
            title="Consultation started",
            message=f"Dr. {request.user.get_full_name() or request.user.username} has started a consultation with you.",
            type=Notification.Type.CONSULTATION_CREATED,
            related_id=consultation.id,
        )
        _publish_user_notification(patient.id, {
            "title": "Consultation started",
            "message": f"Dr. {request.user.get_full_name() or request.user.username} has started a consultation with you.",
            "type": "CONSULTATION_CREATED",
            "related_id": consultation.id,
        })

        out = ConsultationSerializer(consultation)
        return Response(out.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def my_consultations(request):
    if request.user.role == "DOCTOR":
        consultations = Consultation.objects.filter(doctor=request.user)
    else:
        consultations = Consultation.objects.filter(patient=request.user)
    serializer = ConsultationSerializer(consultations, many=True)
    return Response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def consultation_detail(request, consultation_id):
    try:
        consultation = Consultation.objects.get(id=consultation_id)
    except Consultation.DoesNotExist:
        return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

    if request.user not in [consultation.patient, consultation.doctor]:
        return Response(
            {"detail": "Access denied."}, status=status.HTTP_403_FORBIDDEN
        )
    serializer = ConsultationSerializer(consultation)
    return Response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def consultation_messages(request, consultation_id):
    try:
        consultation = Consultation.objects.get(id=consultation_id)
    except Consultation.DoesNotExist:
        return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

    if request.user not in [consultation.patient, consultation.doctor]:
        return Response(
            {"detail": "Access denied."}, status=status.HTTP_403_FORBIDDEN
        )

    after_id = request.query_params.get("after_id")
    messages = consultation.messages.all()
    if after_id:
        try:
            messages = messages.filter(id__gt=int(after_id))
        except ValueError:
            pass
    serializer = MessageSerializer(messages, many=True)
    return Response(serializer.data)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def send_message(request, consultation_id):
    try:
        consultation = Consultation.objects.get(id=consultation_id)
    except Consultation.DoesNotExist:
        return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

    if request.user not in [consultation.patient, consultation.doctor]:
        return Response(
            {"detail": "Access denied."}, status=status.HTTP_403_FORBIDDEN
        )

    serializer = SendMessageSerializer(data=request.data)
    if serializer.is_valid():
        message = Message.objects.create(
            consultation=consultation,
            sender=request.user,
            message_type=serializer.validated_data.get(
                "message_type", "TEXT"
            ),
            text_content=serializer.validated_data.get("text_content"),
            audio_file=serializer.validated_data.get("audio_file"),
            image_file=serializer.validated_data.get("image_file"),
        )

        recipient = consultation.patient if request.user == consultation.doctor else consultation.doctor
        msg_preview = "Sent an image" if message.message_type == "IMAGE" else (message.text_content or "Sent an audio message")
        Notification.objects.create(
            recipient=recipient,
            title=f"New message from {request.user.get_full_name() or request.user.username}",
            message=msg_preview,
            type=Notification.Type.MESSAGE_SENT,
            related_id=consultation.id,
        )
        _publish_user_notification(recipient.id, {
            "title": f"New message from {request.user.get_full_name() or request.user.username}",
            "message": msg_preview,
            "type": "MESSAGE_SENT",
            "related_id": consultation.id,
        })

        out = MessageSerializer(message)
        _publish_consultation_message(consultation_id, out.data)
        return Response(out.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["PATCH"])
@permission_classes([IsAuthenticated, IsDoctor])
def update_consultation_status(request, consultation_id):
    try:
        consultation = Consultation.objects.get(id=consultation_id)
    except Consultation.DoesNotExist:
        return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

    new_status = request.data.get("status")
    if new_status not in ["ACTIVE", "RESOLVED", "REFERRED"]:
        return Response(
            {"detail": "Invalid status."}, status=status.HTTP_400_BAD_REQUEST
        )

    consultation.status = new_status
    if new_status in ["RESOLVED", "REFERRED"]:
        consultation.completed_at = timezone.now()
        Notification.objects.create(
            recipient=consultation.patient,
            title="Consultation completed",
            message=f"Your consultation with Dr. {request.user.get_full_name() or request.user.username} has been marked as {new_status.lower()}.",
            type=Notification.Type.CONSULTATION_CREATED,
            related_id=consultation.id,
        )
    consultation.save()
    serializer = ConsultationSerializer(consultation)
    _publish_consultation_status(consultation_id, serializer.data)
    return Response(serializer.data)
