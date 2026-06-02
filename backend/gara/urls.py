from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.conf.urls.static import static
from django.views.static import serve

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/", include("accounts.urls")),
    path("api/intake/", include("intake.urls")),
    path("api/payments/", include("payments.urls")),
    path("api/consultations/", include("consultations.urls")),
    path("api/clinical/", include("clinical.urls")),
    path("api/notifications/", include("notifications.urls")),
]

# Serve media files in all environments (not just DEBUG)
urlpatterns += [
    re_path(r'^media/(?P<path>.*)$', serve, {'document_root': settings.MEDIA_ROOT}),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
