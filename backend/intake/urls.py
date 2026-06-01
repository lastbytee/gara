from django.urls import path
from . import views

urlpatterns = [
    path("create/", views.create_intake, name="create-intake"),
    path("my/", views.my_intakes, name="my-intakes"),
    path("my/<int:intake_id>/", views.intake_detail, name="intake-detail"),
    path("all/", views.all_intakes, name="all-intakes"),
    path("patient/<int:patient_id>/", views.list_patient_intakes, name="patient-intakes"),
    path("<int:intake_id>/assign/", views.assign_doctor, name="assign-doctor"),
    path("<int:intake_id>/doctor-info/", views.intake_doctor_info, name="intake-doctor-info"),
]
