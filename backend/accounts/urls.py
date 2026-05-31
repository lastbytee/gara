from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from . import views

urlpatterns = [
    path("register/patient/", views.register_patient, name="register-patient"),
    path("register/doctor/", views.register_doctor, name="register-doctor"),
    path("login/", TokenObtainPairView.as_view(), name="token-obtain"),
    path("refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("me/", views.me, name="user-me"),
    path("me/update/", views.update_profile, name="user-update"),
    path("patients/", views.list_patients, name="list-patients"),
    path("password-reset/", views.password_reset_request, name="password-reset"),
    path("password-reset/confirm/", views.password_reset_confirm, name="password-reset-confirm"),
    path("google/", views.google_auth, name="google-auth"),
]
