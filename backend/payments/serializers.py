from rest_framework import serializers
from .models import Payment


class PaymentSerializer(serializers.ModelSerializer):
    patient_name = serializers.SerializerMethodField()
    doctor_name = serializers.SerializerMethodField()
    doctor_momo_phone = serializers.SerializerMethodField()
    doctor_momo_network = serializers.SerializerMethodField()

    class Meta:
        model = Payment
        fields = [
            "id", "patient", "patient_name", "amount", "screenshot",
            "sender_phone", "status", "doctor_notes", "created_at", "approved_at",
            "doctor_name", "doctor_momo_phone", "doctor_momo_network",
        ]
        read_only_fields = ["id", "patient", "status", "doctor_notes", "created_at", "approved_at", "patient_name"]

    def get_patient_name(self, obj):
        return obj.patient.get_full_name() or obj.patient.username

    def get_doctor_name(self, obj):
        return None

    def get_doctor_momo_phone(self, obj):
        return None

    def get_doctor_momo_network(self, obj):
        return None


class PaymentCreateSerializer(serializers.ModelSerializer):
    intake_id = serializers.IntegerField(required=False, allow_null=True)

    class Meta:
        model = Payment
        fields = ["amount", "screenshot", "sender_phone", "intake_id"]

    def create(self, validated_data):
        validated_data.pop("intake_id", None)
        patient = self.context["request"].user
        return Payment.objects.create(patient=patient, **validated_data)


class PaymentReviewSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=["APPROVED", "REJECTED"])
    doctor_notes = serializers.CharField(required=False, allow_blank=True)
