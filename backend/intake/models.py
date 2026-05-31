from django.db import models
from django.conf import settings


class ClinicalIntake(models.Model):
    class Sex(models.TextChoices):
        MALE = "MALE", "Male"
        FEMALE = "FEMALE", "Female"

    class Severity(models.TextChoices):
        MILD = "MILD", "Mild"
        MODERATE = "MODERATE", "Moderate"
        SEVERE = "SEVERE", "Severe"
        CRITICAL = "CRITICAL", "Critical"

    class Duration(models.TextChoices):
        TODAY = "TODAY", "Today"
        FEW_DAYS = "FEW_DAYS", "Few days (2-3)"
        WEEK = "WEEK", "About a week"
        TWO_WEEKS = "TWO_WEEKS", "Two weeks"
        MONTH = "MONTH", "About a month"
        LONGER = "LONGER", "Longer than a month"

    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="intakes",
    )
    sex = models.CharField(max_length=10, choices=Sex.choices)
    severity = models.CharField(max_length=10, choices=Severity.choices)
    duration = models.CharField(max_length=10, choices=Duration.choices)
    symptoms_description = models.TextField(help_text="Free-text description of symptoms")
    ai_clinical_summary = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_submitted = models.BooleanField(default=False)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Intake #{self.id} - {self.patient.get_full_name()} ({self.severity})"
