from django.urls import path
from . import views

urlpatterns = [
    path("create/", views.create_payment, name="create-payment"),
    path("my/", views.my_payments, name="my-payments"),
    path("pending/", views.pending_payments, name="pending-payments"),
    path("all/", views.all_payments, name="all-payments"),
    path("<int:payment_id>/review/", views.review_payment, name="review-payment"),
    path("daily-revenue/", views.daily_revenue, name="daily-revenue"),
]
