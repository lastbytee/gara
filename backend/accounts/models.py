from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    class Role(models.TextChoices):
        DOCTOR = "DOCTOR", "Doctor"
        PATIENT = "PATIENT", "Patient"

    role = models.CharField(max_length=10, choices=Role.choices, default=Role.PATIENT)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    preferred_language = models.CharField(
        max_length=10, default="en", choices=[("en", "English"), ("rw", "Kinyarwanda")]
    )

    def __str__(self):
        return f"{self.get_full_name() or self.username} ({self.get_role_display()})"


class PatientProfile(models.Model):
    class Sex(models.TextChoices):
        MALE = "MALE", "Male"
        FEMALE = "FEMALE", "Female"

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="patient_profile")
    date_of_birth = models.DateField(null=True, blank=True)
    sex = models.CharField(max_length=10, choices=Sex.choices, null=True, blank=True)
    profile_picture = models.ImageField(upload_to="profiles/", blank=True, null=True)
    address = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"Patient: {self.user.get_full_name() or self.user.username}"


class DoctorProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="doctor_profile")
    license_number = models.CharField(max_length=50, blank=True, null=True)
    specialization = models.CharField(max_length=100, blank=True, null=True)
    profile_picture = models.ImageField(upload_to="profiles/", blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    bio = models.TextField(blank=True, null=True)
    momo_phone_number = models.CharField(max_length=20, blank=True, null=True)
    momo_network = models.CharField(max_length=10, blank=True, null=True, default="MTN")

    def __str__(self):
        return f"Dr. {self.user.get_full_name() or self.user.username}"


class PasswordResetCode(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="reset_codes")
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    is_used = models.BooleanField(default=False)

    def __str__(self):
        return f"Reset code {self.code} for {self.user.username}"
