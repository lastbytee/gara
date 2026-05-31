from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Sum, Count
from django.contrib.auth import get_user_model
from .models import Payment
from .serializers import (
    PaymentSerializer,
    PaymentCreateSerializer,
    PaymentReviewSerializer,
)
from accounts.permissions import IsPatient, IsDoctor
from notifications.models import Notification

User = get_user_model()


@api_view(["POST"])
@permission_classes([IsAuthenticated, IsPatient])
def create_payment(request):
    serializer = PaymentCreateSerializer(
        data=request.data, context={"request": request}
    )
    if serializer.is_valid():
        payment = serializer.save()
        doctors = User.objects.filter(role="DOCTOR")
        for doctor in doctors:
            Notification.objects.create(
                recipient=doctor,
                title=f"New payment from {payment.patient.get_full_name() or payment.patient.username}",
                message=f"Payment of {payment.amount} RWF submitted. Tap to review.",
                type=Notification.Type.PAYMENT_SUBMITTED,
                related_id=payment.id,
            )
        out = PaymentSerializer(payment)
        return Response(out.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsPatient])
def my_payments(request):
    payments = Payment.objects.filter(patient=request.user)
    serializer = PaymentSerializer(payments, many=True)
    return Response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsDoctor])
def pending_payments(request):
    payments = Payment.objects.filter(status="PENDING")
    serializer = PaymentSerializer(payments, many=True)
    return Response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsDoctor])
def all_payments(request):
    payments = Payment.objects.all()
    serializer = PaymentSerializer(payments, many=True)
    return Response(serializer.data)


@api_view(["POST"])
@permission_classes([IsAuthenticated, IsDoctor])
def review_payment(request, payment_id):
    try:
        payment = Payment.objects.get(id=payment_id)
    except Payment.DoesNotExist:
        return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

    serializer = PaymentReviewSerializer(data=request.data)
    if serializer.is_valid():
        payment.status = serializer.validated_data["status"]
        payment.doctor_notes = serializer.validated_data.get("doctor_notes", "")
        if payment.status == "APPROVED":
            payment.approved_at = timezone.now()
        payment.save()

        Notification.objects.create(
            recipient=payment.patient,
            title="Payment "
            + ("Approved" if payment.status == "APPROVED" else "Rejected"),
            message=f"Your payment of {payment.amount} RWF has been {payment.status.lower()}.",
            type=(
                Notification.Type.PAYMENT_APPROVED
                if payment.status == "APPROVED"
                else Notification.Type.PAYMENT_REJECTED
            ),
            related_id=payment.id,
        )

        out = PaymentSerializer(payment)
        return Response(out.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsDoctor])
def daily_revenue(request):
    today = timezone.now().date()
    approved = Payment.objects.filter(status="APPROVED", approved_at__date=today)
    total = sum(p.amount for p in approved)
    count = approved.count()
    return Response({
        "date": today,
        "total_revenue": float(total),
        "approved_count": count,
    })
