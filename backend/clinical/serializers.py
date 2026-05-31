from rest_framework import serializers
from .models import Prescription, Referral


class PrescriptionSerializer(serializers.ModelSerializer):
    doctor_name = serializers.SerializerMethodField()
    patient_name = serializers.SerializerMethodField()

    class Meta:
        model = Prescription
        fields = [
            "id", "consultation", "doctor", "doctor_name",
            "patient", "patient_name", "medication", "dosage",
            "frequency", "duration", "notes", "created_at",
        ]
        read_only_fields = ["id", "doctor", "created_at"]

    def get_doctor_name(self, obj):
        return obj.doctor.get_full_name() or obj.doctor.username

    def get_patient_name(self, obj):
        return obj.patient.get_full_name() or obj.patient.username


class PrescriptionCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Prescription
        fields = [
            "medication", "dosage", "frequency", "duration", "notes",
        ]

    def create(self, validated_data):
        consultation_id = self.context["consultation_id"]
        from consultations.models import Consultation
        consultation = Consultation.objects.get(id=consultation_id)
        return Prescription.objects.create(
            consultation=consultation,
            doctor=self.context["request"].user,
            patient=consultation.patient,
            **validated_data,
        )


class ReferralSerializer(serializers.ModelSerializer):
    doctor_name = serializers.SerializerMethodField()
    patient_name = serializers.SerializerMethodField()

    class Meta:
        model = Referral
        fields = [
            "id", "consultation", "doctor", "doctor_name",
            "patient", "patient_name", "priority",
            "referral_reason", "referred_to", "notes", "created_at",
        ]
        read_only_fields = ["id", "doctor", "created_at"]

    def get_doctor_name(self, obj):
        return obj.doctor.get_full_name() or obj.doctor.username

    def get_patient_name(self, obj):
        return obj.patient.get_full_name() or obj.patient.username


class ReferralCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Referral
        fields = ["priority", "referral_reason", "referred_to", "notes"]

    def create(self, validated_data):
        consultation_id = self.context["consultation_id"]
        from consultations.models import Consultation
        consultation = Consultation.objects.get(id=consultation_id)
        return Referral.objects.create(
            consultation=consultation,
            doctor=self.context["request"].user,
            patient=consultation.patient,
            **validated_data,
        )
