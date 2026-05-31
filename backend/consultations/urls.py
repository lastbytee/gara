from django.urls import path
from . import views

urlpatterns = [
    path("dashboard/", views.dashboard_stats, name="dashboard-stats"),
    path("create/", views.create_consultation, name="create-consultation"),
    path("my/", views.my_consultations, name="my-consultations"),
    path("<int:consultation_id>/", views.consultation_detail, name="consultation-detail"),
    path("<int:consultation_id>/messages/", views.consultation_messages, name="consultation-messages"),
    path("<int:consultation_id>/send/", views.send_message, name="send-message"),
    path("<int:consultation_id>/status/", views.update_consultation_status, name="update-status"),
]
