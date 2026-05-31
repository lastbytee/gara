from django.urls import path
from . import views

urlpatterns = [
    path("my-prescriptions/", views.my_prescriptions, name="my-prescriptions"),
    path("my-referrals/", views.my_referrals, name="my-referrals"),
    path(
        "consultation/<int:consultation_id>/prescriptions/",
        views.create_prescription,
        name="create-prescription",
    ),
    path(
        "consultation/<int:consultation_id>/prescriptions/list/",
        views.get_prescriptions,
        name="get-prescriptions",
    ),
    path(
        "consultation/<int:consultation_id>/referrals/",
        views.create_referral,
        name="create-referral",
    ),
    path(
        "consultation/<int:consultation_id>/referrals/list/",
        views.get_referrals,
        name="get-referrals",
    ),
]
