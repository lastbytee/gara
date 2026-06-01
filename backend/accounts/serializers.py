import re
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.validators import EmailValidator
from .models import PatientProfile, DoctorProfile

User = get_user_model()
email_validator = EmailValidator()


class RegisterPatientSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    confirm_password = serializers.CharField(write_only=True)
    date_of_birth = serializers.DateField(required=False, allow_null=True)
    sex = serializers.ChoiceField(
        choices=PatientProfile.Sex.choices, required=False, allow_null=True
    )

    class Meta:
        model = User
        fields = [
            "username", "email", "password", "confirm_password", "first_name", "last_name",
            "phone_number", "preferred_language", "date_of_birth", "sex",
        ]

    def validate_username(self, value):
        if not re.match(r'^[a-zA-Z0-9_]{3,30}$', value):
            raise serializers.ValidationError("Username must be 3-30 characters: letters, numbers, underscore.")
        return value

    def validate_email(self, value):
        email_validator(value)
        return value

    def validate(self, attrs):
        if attrs["password"] != attrs.pop("confirm_password"):
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        return attrs

    def create(self, validated_data):
        dob = validated_data.pop("date_of_birth", None)
        sex = validated_data.pop("sex", None)
        password = validated_data.pop("password")
        user = User(**validated_data)
        user.role = User.Role.PATIENT
        user.set_password(password)
        user.save()
        PatientProfile.objects.create(user=user, date_of_birth=dob, sex=sex)
        return user


class RegisterDoctorSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    confirm_password = serializers.CharField(write_only=True)
    registration_token = serializers.CharField(write_only=True)
    license_number = serializers.CharField(required=False, allow_blank=True)
    specialization = serializers.CharField(required=False, allow_blank=True)
    momo_phone_number = serializers.CharField(required=False, allow_blank=True)
    momo_network = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = [
            "username", "email", "password", "confirm_password", "first_name", "last_name",
            "phone_number", "registration_token", "license_number", "specialization",
            "momo_phone_number", "momo_network",
        ]

    def validate_username(self, value):
        if not re.match(r'^[a-zA-Z0-9_]{3,30}$', value):
            raise serializers.ValidationError("Username must be 3-30 characters: letters, numbers, underscore.")
        return value

    def validate_email(self, value):
        email_validator(value)
        return value

    def validate(self, attrs):
        if attrs["password"] != attrs.pop("confirm_password"):
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        return attrs

    def validate_registration_token(self, value):
        from django.conf import settings
        if value != settings.DOCTOR_REGISTRATION_TOKEN:
            raise serializers.ValidationError("Invalid registration token.")
        return value

    def create(self, validated_data):
        validated_data.pop("registration_token")
        license_number = validated_data.pop("license_number", "")
        specialization = validated_data.pop("specialization", "")
        momo_phone_number = validated_data.pop("momo_phone_number", "")
        momo_network = validated_data.pop("momo_network", "")
        password = validated_data.pop("password")
        user = User(**validated_data)
        user.role = User.Role.DOCTOR
        user.set_password(password)
        user.save()
        DoctorProfile.objects.create(
            user=user, license_number=license_number, specialization=specialization,
            momo_phone_number=momo_phone_number, momo_network=momo_network,
        )
        return user


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id", "username", "email", "first_name", "last_name",
            "phone_number", "role", "preferred_language",
        ]


class PatientProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = PatientProfile
        fields = ["user", "date_of_birth", "sex"]


class DoctorProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = DoctorProfile
        fields = ["user", "license_number", "specialization"]


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()


class PasswordResetConfirmSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=6)
    new_password = serializers.CharField(write_only=True, validators=[validate_password])
    confirm_new_password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        if attrs["new_password"] != attrs.pop("confirm_new_password"):
            raise serializers.ValidationError({"confirm_new_password": "Passwords do not match."})
        return attrs


class GoogleAuthSerializer(serializers.Serializer):
    id_token = serializers.CharField()
