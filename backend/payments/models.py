from django.db import models
from django.conf import settings


class Payment(models.Model):
    intake = models.ForeignKey(
        "intake.ClinicalIntake",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="payments",
    )
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        APPROVED = "APPROVED", "Approved"
        REJECTED = "REJECTED", "Rejected"

    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="payments",
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    screenshot = models.ImageField(upload_to="payments/")
    sender_phone = models.CharField(
        max_length=20,
        blank=True,
        null=True,
        help_text="Alternative MoMo number used for payment",
    )
    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.PENDING
    )
    doctor_notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    approved_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Payment #{self.id} - {self.patient.get_full_name()} - {self.amount} RWF"
