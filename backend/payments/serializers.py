from rest_framework import serializers
from .models import Payment


class PaymentSerializer(serializers.ModelSerializer):
    patient_name = serializers.SerializerMethodField()

    class Meta:
        model = Payment
        fields = [
            "id", "patient", "patient_name", "amount", "screenshot",
            "sender_phone", "status", "doctor_notes", "created_at", "approved_at",
        ]
        read_only_fields = ["id", "patient", "status", "doctor_notes", "created_at", "approved_at", "patient_name"]

    def get_patient_name(self, obj):
        return obj.patient.get_full_name() or obj.patient.username


class PaymentCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = ["amount", "screenshot", "sender_phone"]

    def create(self, validated_data):
        patient = self.context["request"].user
        return Payment.objects.create(patient=patient, **validated_data)


class PaymentReviewSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=["APPROVED", "REJECTED"])
    doctor_notes = serializers.CharField(required=False, allow_blank=True)
