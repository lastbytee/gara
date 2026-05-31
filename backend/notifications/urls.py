from django.urls import path
from . import views

urlpatterns = [
    path("my/", views.my_notifications, name="my-notifications"),
    path("unread-count/", views.unread_count, name="unread-count"),
    path("<int:notification_id>/read/", views.mark_read, name="mark-read"),
    path("read-all/", views.mark_all_read, name="mark-all-read"),
]
