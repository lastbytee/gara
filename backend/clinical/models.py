from django.db import models
from django.conf import settings


class Prescription(models.Model):
    consultation = models.ForeignKey(
        "consultations.Consultation",
        on_delete=models.CASCADE,
        related_name="prescriptions",
    )
    doctor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="prescriptions_written",
    )
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="prescriptions_received",
    )
    medication = models.CharField(max_length=255)
    dosage = models.CharField(max_length=255)
    frequency = models.CharField(max_length=255, help_text="e.g., Twice daily with meals")
    duration = models.CharField(max_length=255, help_text="e.g., 7 days")
    notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Rx: {self.medication} for {self.patient.get_full_name()}"


class Referral(models.Model):
    class Priority(models.TextChoices):
        STANDARD = "STANDARD", "Standard"
        URGENT = "URGENT", "Urgent"
        EMERGENCY = "EMERGENCY", "Emergency"

    consultation = models.ForeignKey(
        "consultations.Consultation",
        on_delete=models.CASCADE,
        related_name="referrals",
    )
    doctor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="referrals_made",
    )
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="referrals_received",
    )
    priority = models.CharField(
        max_length=10, choices=Priority.choices, default=Priority.STANDARD
    )
    referral_reason = models.TextField()
    referred_to = models.CharField(
        max_length=255,
        help_text="Hospital, clinic, or specialist name",
    )
    notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Referral: {self.patient.get_full_name()} -> {self.referred_to}"
