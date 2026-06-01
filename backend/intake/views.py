from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import ClinicalIntake
from .serializers import ClinicalIntakeSerializer, ClinicalIntakeCreateSerializer
from accounts.permissions import IsPatient, IsDoctor


@api_view(["POST"])
@permission_classes([IsAuthenticated, IsPatient])
def create_intake(request):
    serializer = ClinicalIntakeCreateSerializer(
        data=request.data, context={"request": request}
    )
    if serializer.is_valid():
        intake = serializer.save()
        out = ClinicalIntakeSerializer(intake)
        return Response(out.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsPatient])
def my_intakes(request):
    intakes = ClinicalIntake.objects.filter(patient=request.user)
    serializer = ClinicalIntakeSerializer(intakes, many=True)
    return Response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsPatient])
def intake_detail(request, intake_id):
    try:
        intake = ClinicalIntake.objects.get(id=intake_id, patient=request.user)
    except ClinicalIntake.DoesNotExist:
        return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
    serializer = ClinicalIntakeSerializer(intake)
    return Response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsDoctor])
def list_patient_intakes(request, patient_id):
    intakes = ClinicalIntake.objects.filter(patient_id=patient_id)
    serializer = ClinicalIntakeSerializer(intakes, many=True)
    return Response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsDoctor])
def all_intakes(request):
    status_filter = request.query_params.get("status")
    qs = ClinicalIntake.objects.all()
    if status_filter:
        qs = qs.filter(is_submitted=(status_filter == "submitted"))
    qs = qs.order_by("-created_at")
    intakes = list(qs)
    from .ai_service import get_triage_priority
    priority_order = {"emergency": 0, "high": 1, "medium": 2, "low": 3}
    intakes.sort(key=lambda i: priority_order.get(get_triage_priority(i.severity, i.symptoms_description), 99))
    serializer = ClinicalIntakeSerializer(intakes, many=True)
    return Response(serializer.data)
