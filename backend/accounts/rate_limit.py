from functools import wraps
from django.core.cache import cache
from rest_framework import status
from rest_framework.response import Response


def rate_limit(max_requests=10, window_seconds=60):
    """Simple in-memory rate limiter per IP."""
    def decorator(view):
        @wraps(view)
        def wrapped(request, *args, **kwargs):
            ip = request.META.get("REMOTE_ADDR", "unknown")
            key = f"ratelimit:{ip}:{view.__name__}"
            count = cache.get(key, 0)
            if count >= max_requests:
                return Response(
                    {"detail": f"Too many requests. Try again in {window_seconds} seconds."},
                    status=status.HTTP_429_TOO_MANY_REQUESTS,
                )
            cache.set(key, count + 1, window_seconds)
            return view(request, *args, **kwargs)
        return wrapped
    return decorator
