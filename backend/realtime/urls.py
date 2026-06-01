from django.urls import path
from . import views

urlpatterns = [
    path("token/", views.ably_token, name="ably-token"),
]
