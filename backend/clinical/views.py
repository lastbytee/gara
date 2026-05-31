from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Prescription, Referral
from .serializers import (
    PrescriptionSerializer,
    PrescriptionCreateSerializer,
    ReferralSerializer,
    ReferralCreateSerializer,
)
from accounts.permissions import IsDoctor
from notifications.models import Notification


@api_view(["POST"])
@permission_classes([IsAuthenticated, IsDoctor])
def create_prescription(request, consultation_id):
    serializer = PrescriptionCreateSerializer(
        data=request.data,
        context={"request": request, "consultation_id": consultation_id},
    )
    if serializer.is_valid():
        prescription = serializer.save()
        from consultations.models import Consultation
        consultation = Consultation.objects.get(id=consultation_id)
        Notification.objects.create(
            recipient=consultation.patient,
            title="Prescription added",
            message=f"A prescription has been added to your consultation.",
            type=Notification.Type.PRESCRIPTION_ADDED,
            related_id=consultation_id,
        )
        out = PrescriptionSerializer(prescription)
        return Response(out.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_prescriptions(request, consultation_id):
    from consultations.models import Consultation
    try:
        consultation = Consultation.objects.get(id=consultation_id)
    except Consultation.DoesNotExist:
        return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

    if request.user not in [consultation.patient, consultation.doctor]:
        return Response({"detail": "Access denied."}, status=status.HTTP_403_FORBIDDEN)

    prescriptions = consultation.prescriptions.all()
    serializer = PrescriptionSerializer(prescriptions, many=True)
    return Response(serializer.data)


@api_view(["POST"])
@permission_classes([IsAuthenticated, IsDoctor])
def create_referral(request, consultation_id):
    serializer = ReferralCreateSerializer(
        data=request.data,
        context={"request": request, "consultation_id": consultation_id},
    )
    if serializer.is_valid():
        referral = serializer.save()
        from consultations.models import Consultation
        consultation = Consultation.objects.get(id=consultation_id)
        consultation.status = "REFERRED"
        consultation.save()
        Notification.objects.create(
            recipient=consultation.patient,
            title="Referral created",
            message=f"You have been referred to {referral.referred_to}.",
            type=Notification.Type.REFERRAL_ADDED,
            related_id=consultation_id,
        )
        out = ReferralSerializer(referral)
        return Response(out.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def my_prescriptions(request):
    prescriptions = Prescription.objects.filter(patient=request.user)
    serializer = PrescriptionSerializer(prescriptions, many=True)
    return Response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def my_referrals(request):
    referrals = Referral.objects.filter(patient=request.user)
    serializer = ReferralSerializer(referrals, many=True)
    return Response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_referrals(request, consultation_id):
    from consultations.models import Consultation
    try:
        consultation = Consultation.objects.get(id=consultation_id)
    except Consultation.DoesNotExist:
        return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

    if request.user not in [consultation.patient, consultation.doctor]:
        return Response({"detail": "Access denied."}, status=status.HTTP_403_FORBIDDEN)

    referrals = consultation.referrals.all()
    serializer = ReferralSerializer(referrals, many=True)
    return Response(serializer.data)
