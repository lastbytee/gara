from rest_framework import serializers
from .models import ClinicalIntake


class ClinicalIntakeSerializer(serializers.ModelSerializer):
    triage_priority = serializers.SerializerMethodField()
    assigned_doctor_name = serializers.SerializerMethodField()
    assigned_doctor_momo_phone = serializers.SerializerMethodField()
    assigned_doctor_momo_network = serializers.SerializerMethodField()

    class Meta:
        model = ClinicalIntake
        fields = [
            "id", "patient", "assigned_doctor", "assigned_doctor_name",
            "assigned_doctor_momo_phone", "assigned_doctor_momo_network",
            "sex", "severity", "duration",
            "symptoms_description", "ai_clinical_summary",
            "created_at", "updated_at", "is_submitted", "triage_priority",
            "payment_status",
        ]
        read_only_fields = ["id", "patient", "ai_clinical_summary", "created_at", "updated_at"]

    def get_assigned_doctor_name(self, obj):
        if obj.assigned_doctor:
            return obj.assigned_doctor.get_full_name() or obj.assigned_doctor.username
        return None

    def get_assigned_doctor_momo_phone(self, obj):
        if obj.assigned_doctor:
            profile = getattr(obj.assigned_doctor, "doctor_profile", None)
            return getattr(profile, "momo_phone_number", None) if profile else None
        return None

    def get_assigned_doctor_momo_network(self, obj):
        if obj.assigned_doctor:
            profile = getattr(obj.assigned_doctor, "doctor_profile", None)
            return getattr(profile, "momo_network", None) if profile else None
        return None

    def get_triage_priority(self, obj):
        from .ai_service import get_triage_priority
        return get_triage_priority(obj.severity, obj.symptoms_description)

    def get_payment_status(self, obj):
        payment = obj.payments.first()
        if not payment:
            return "none"
        return payment.status.lower()

    payment_status = serializers.SerializerMethodField()


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
