from rest_framework import serializers
from .models import Consultation, Message


class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = [
            "id", "consultation", "sender", "sender_name",
            "message_type", "text_content", "audio_file", "image_file",
            "created_at",
        ]
        read_only_fields = ["id", "sender", "created_at"]

    def get_sender_name(self, obj):
        return obj.sender.get_full_name() or obj.sender.username


class ConsultationSerializer(serializers.ModelSerializer):
    patient_name = serializers.SerializerMethodField()
    doctor_name = serializers.SerializerMethodField()
    recent_messages = serializers.SerializerMethodField()

    class Meta:
        model = Consultation
        fields = [
            "id", "patient", "patient_name", "doctor", "doctor_name",
            "intake", "status", "created_at", "updated_at", "recent_messages",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def get_patient_name(self, obj):
        return obj.patient.get_full_name() or obj.patient.username

    def get_doctor_name(self, obj):
        return obj.doctor.get_full_name() or obj.doctor.username

    def get_recent_messages(self, obj):
        messages = obj.messages.all()[:5]
        return MessageSerializer(messages, many=True).data


class SendMessageSerializer(serializers.Serializer):
    text_content = serializers.CharField(required=False, allow_blank=True)
    audio_file = serializers.FileField(required=False)
    image_file = serializers.ImageField(required=False)
    message_type = serializers.ChoiceField(
        choices=["TEXT", "AUDIO", "IMAGE"], default="TEXT"
    )

    def validate(self, data):
        msg_type = data.get("message_type")
        if msg_type == "TEXT" and not data.get("text_content"):
            raise serializers.ValidationError("Text content required for text messages.")
        if msg_type == "AUDIO" and not data.get("audio_file"):
            raise serializers.ValidationError("Audio file required for audio messages.")
        if msg_type == "IMAGE" and not data.get("image_file"):
            raise serializers.ValidationError("Image file required for image messages.")
        return data


class CreateConsultationSerializer(serializers.Serializer):
    patient_id = serializers.IntegerField()
    intake_id = serializers.IntegerField(required=False, allow_null=True)
