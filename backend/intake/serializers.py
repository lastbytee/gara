from rest_framework import serializers
from .models import ClinicalIntake


class ClinicalIntakeSerializer(serializers.ModelSerializer):
    triage_priority = serializers.SerializerMethodField()

    class Meta:
        model = ClinicalIntake
        fields = [
            "id", "patient", "sex", "severity", "duration",
            "symptoms_description", "ai_clinical_summary",
            "created_at", "updated_at", "is_submitted", "triage_priority",
        ]
        read_only_fields = ["id", "patient", "ai_clinical_summary", "created_at", "updated_at"]

    def get_triage_priority(self, obj):
        from .ai_service import get_triage_priority
        return get_triage_priority(obj.severity, obj.symptoms_description)


class ClinicalIntakeCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClinicalIntake
        fields = [
            "sex", "severity", "duration", "symptoms_description",
        ]

    def create(self, validated_data):
        patient = self.context["request"].user
        intake = ClinicalIntake.objects.create(patient=patient, **validated_data)

        from .ai_service import generate_clinical_summary
        summary = generate_clinical_summary(
            sex=intake.sex,
            severity=intake.severity,
            duration=intake.duration,
            symptoms_text=intake.symptoms_description,
        )
        intake.ai_clinical_summary = summary
        intake.is_submitted = True
        intake.save()
        return intake
