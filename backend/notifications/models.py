from django.db import models
from django.conf import settings


class Notification(models.Model):
    class Type(models.TextChoices):
        PAYMENT_SUBMITTED = "PAYMENT_SUBMITTED", "Payment Submitted"
        PAYMENT_APPROVED = "PAYMENT_APPROVED", "Payment Approved"
        PAYMENT_REJECTED = "PAYMENT_REJECTED", "Payment Rejected"
        CONSULTATION_CREATED = "CONSULTATION_CREATED", "Consultation Created"
        MESSAGE_SENT = "MESSAGE_SENT", "Message Sent"
        PRESCRIPTION_ADDED = "PRESCRIPTION_ADDED", "Prescription Added"
        REFERRAL_ADDED = "REFERRAL_ADDED", "Referral Added"

    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    title = models.CharField(max_length=255)
    message = models.TextField()
    type = models.CharField(max_length=30, choices=Type.choices)
    related_id = models.IntegerField(null=True, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"[{self.type}] {self.title}"
