import random
from datetime import timedelta
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from .serializers import (
    RegisterPatientSerializer,
    RegisterDoctorSerializer,
    UserSerializer,
    PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer,
)
from .permissions import IsDoctor, IsPatient
from .models import PatientProfile, DoctorProfile, PasswordResetCode
from .rate_limit import rate_limit

User = get_user_model()


@api_view(["POST"])
@permission_classes([AllowAny])
@rate_limit(max_requests=5, window_seconds=300)
def register_patient(request):
    serializer = RegisterPatientSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        refresh = RefreshToken.for_user(user)

        # Notify all doctors about new patient
        try:
            from notifications.models import Notification
            doctors = User.objects.filter(role="DOCTOR")
            for doctor in doctors:
                Notification.objects.create(
                    recipient=doctor,
                    title="New patient registered",
                    message=f"{user.get_full_name() or user.username} has joined Gara as a patient.",
                    type=Notification.Type.NEW_PATIENT,
                    related_id=user.id,
                )
        except Exception:
            pass

        return Response(
            {
                "user": UserSerializer(user).data,
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            status=status.HTTP_201_CREATED,
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["POST"])
@permission_classes([AllowAny])
@rate_limit(max_requests=5, window_seconds=300)
def register_doctor(request):
    serializer = RegisterDoctorSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "user": UserSerializer(user).data,
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            status=status.HTTP_201_CREATED,
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


def _serialize_profile(user):
    serializer = UserSerializer(user)
    data = serializer.data
    data["phone_number"] = user.phone_number
    data["preferred_language"] = user.preferred_language
    if user.role == "PATIENT":
        profile = getattr(user, "patient_profile", None)
        data["date_of_birth"] = getattr(profile, "date_of_birth", None)
        data["sex"] = getattr(profile, "sex", None)
        data["profile_picture"] = (profile.profile_picture.url if profile and profile.profile_picture else None)
        data["address"] = getattr(profile, "address", None)
    elif user.role == "DOCTOR":
        profile = getattr(user, "doctor_profile", None)
        data["license_number"] = getattr(profile, "license_number", None)
        data["specialization"] = getattr(profile, "specialization", None)
        data["profile_picture"] = (profile.profile_picture.url if profile and profile.profile_picture else None)
        data["address"] = getattr(profile, "address", None)
        data["bio"] = getattr(profile, "bio", None)
        data["momo_phone_number"] = getattr(profile, "momo_phone_number", None)
        data["momo_network"] = getattr(profile, "momo_network", None)
    return data


@api_view(["GET"])
def me(request):
    return Response(_serialize_profile(request.user))


@api_view(["PATCH"])
def update_profile(request):
    user = request.user
    for field in ["first_name", "last_name", "phone_number", "preferred_language"]:
        if field in request.data:
            setattr(user, field, request.data[field])
    user.save()

    profile = None
    if user.role == "PATIENT":
        profile, _ = PatientProfile.objects.get_or_create(user=user)
        for f in ["date_of_birth", "sex", "address"]:
            if f in request.data:
                setattr(profile, f, request.data[f])
    elif user.role == "DOCTOR":
        profile, _ = DoctorProfile.objects.get_or_create(user=user)
        for f in ["license_number", "specialization", "address", "bio", "momo_phone_number", "momo_network"]:
            if f in request.data:
                setattr(profile, f, request.data[f])

    if "profile_picture" in request.FILES and profile is not None:
        profile.profile_picture = request.FILES["profile_picture"]

    if profile is not None:
        profile.save()

    return Response(_serialize_profile(user))


@api_view(["GET"])
def list_patients(request):
    if request.user.role != "DOCTOR":
        return Response(
            {"detail": "Only doctors can view patient list."},
            status=status.HTTP_403_FORBIDDEN,
        )
    patients = User.objects.filter(role="PATIENT")
    serializer = UserSerializer(patients, many=True)
    return Response(serializer.data)


@api_view(["POST"])
@permission_classes([AllowAny])
@rate_limit(max_requests=3, window_seconds=120)
def password_reset_request(request):
    serializer = PasswordResetRequestSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    email = serializer.validated_data["email"]
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({"detail": "If the email exists, a reset code has been sent."},
                        status=status.HTTP_200_OK)

    # Invalidate old unused codes
    PasswordResetCode.objects.filter(user=user, is_used=False).delete()

    code = f"{random.randint(100000, 999999)}"
    PasswordResetCode.objects.create(user=user, code=code)

    # In production, send this via email/SMS. For dev, return it.
    return Response({"detail": "Reset code sent.", "code": code},
                    status=status.HTTP_200_OK)


@api_view(["POST"])
@permission_classes([AllowAny])
@rate_limit(max_requests=5, window_seconds=120)
def password_reset_confirm(request):
    serializer = PasswordResetConfirmSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    email = serializer.validated_data["email"]
    code = serializer.validated_data["code"]
    new_password = serializer.validated_data["new_password"]

    try:
        user = User.objects.get(email=email)
        reset = PasswordResetCode.objects.filter(
            user=user, code=code, is_used=False
        ).latest("created_at")
    except (User.DoesNotExist, PasswordResetCode.DoesNotExist):
        return Response({"detail": "Invalid or expired reset code."},
                        status=status.HTTP_400_BAD_REQUEST)

    # Check expiry (24 hours)
    if timezone.now() - reset.created_at > timedelta(hours=24):
        return Response({"detail": "Reset code has expired."},
                        status=status.HTTP_400_BAD_REQUEST)

    user.set_password(new_password)
    user.save()
    reset.is_used = True
    reset.save()

    return Response({"detail": "Password has been reset successfully."},
                    status=status.HTTP_200_OK)



