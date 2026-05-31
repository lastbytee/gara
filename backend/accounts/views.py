import random
from datetime import timedelta
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from .serializers import (
    RegisterPatientSerializer,
    RegisterDoctorSerializer,
    UserSerializer,
    PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer,
    GoogleAuthSerializer,
)
from .permissions import IsDoctor, IsPatient
from .models import PatientProfile, DoctorProfile, PasswordResetCode

User = get_user_model()


@api_view(["POST"])
@permission_classes([AllowAny])
def register_patient(request):
    serializer = RegisterPatientSerializer(data=request.data)
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


@api_view(["POST"])
@permission_classes([AllowAny])
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


@api_view(["GET"])
def me(request):
    serializer = UserSerializer(request.user)
    data = serializer.data
    if request.user.role == "PATIENT":
        profile = getattr(request.user, "patient_profile", None)
        data["date_of_birth"] = getattr(profile, "date_of_birth", None)
        data["sex"] = getattr(profile, "sex", None)
    elif request.user.role == "DOCTOR":
        profile = getattr(request.user, "doctor_profile", None)
        data["license_number"] = getattr(profile, "license_number", None)
        data["specialization"] = getattr(profile, "specialization", None)
    return Response(data)


@api_view(["PATCH"])
def update_profile(request):
    user = request.user
    for field in ["first_name", "last_name", "phone_number", "preferred_language"]:
        if field in request.data:
            setattr(user, field, request.data[field])
    user.save()

    if user.role == "PATIENT":
        profile, _ = PatientProfile.objects.get_or_create(user=user)
        if "date_of_birth" in request.data:
            profile.date_of_birth = request.data["date_of_birth"]
        if "sex" in request.data:
            profile.sex = request.data["sex"]
        profile.save()

    return Response(UserSerializer(user).data)


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


@api_view(["POST"])
@permission_classes([AllowAny])
def google_auth(request):
    serializer = GoogleAuthSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    id_token_str = serializer.validated_data["id_token"]

    try:
        from django.conf import settings
        client_id = settings.GOOGLE_OAUTH_CLIENT_ID or None
        info = id_token.verify_oauth2_token(id_token_str, google_requests.Request(), audience=client_id)
        if info.get("iss") not in ["accounts.google.com", "https://accounts.google.com"]:
            return Response({"detail": "Invalid token issuer."},
                            status=status.HTTP_400_BAD_REQUEST)
    except ValueError:
        return Response({"detail": "Invalid or expired token."},
                        status=status.HTTP_400_BAD_REQUEST)

    email = info.get("email")
    if not email:
        return Response({"detail": "Email not provided by Google."},
                        status=status.HTTP_400_BAD_REQUEST)

    given_name = info.get("given_name", "")
    family_name = info.get("family_name", "")
    google_sub = info.get("sub", "")

    user = User.objects.filter(email=email).first()

    if not user:
        # Create new user
        username = email.split("@")[0]
        base_username = username
        counter = 1
        while User.objects.filter(username=username).exists():
            username = f"{base_username}{counter}"
            counter += 1

        user = User.objects.create(
            username=username,
            email=email,
            first_name=given_name,
            last_name=family_name,
            role=User.Role.PATIENT,
        )
        user.set_password(User.objects.make_random_password())
        user.save()

        PatientProfile.objects.create(user=user)

    refresh = RefreshToken.for_user(user)
    return Response(
        {
            "user": UserSerializer(user).data,
            "access": str(refresh.access_token),
            "refresh": str(refresh),
        },
        status=status.HTTP_200_OK,
    )
