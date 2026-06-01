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
        intake_id = validated_data.pop("intake_id", None)
        patient = self.context["request"].user
        payment = Payment.objects.create(patient=patient, **validated_data)
        if intake_id:
            try:
                from intake.models import ClinicalIntake
                intake = ClinicalIntake.objects.get(id=intake_id, patient=patient)
                payment.intake = intake
                payment.save()
            except ClinicalIntake.DoesNotExist:
                pass
        return payment


class PaymentReviewSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=["APPROVED", "REJECTED"])
    doctor_notes = serializers.CharField(required=False, allow_blank=True)
