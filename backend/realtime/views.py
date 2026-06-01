import json
from django.conf import settings
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def ably_token(request):
    api_key = getattr(settings, "ABLY_API_KEY", None)
    if not api_key:
        return Response({"detail": "Real-time not configured."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
    try:
        import ably
        client = ably.AblyRest(api_key)
        token_params = {"clientId": str(request.user.id)}
        token_request = client.auth.create_token_request(token_params)
        return Response({
            "key_name": token_request["keyName"],
            "client_id": token_request["clientId"],
            "capability": token_request["capability"],
            "ttl": token_request["ttl"],
            "timestamp": token_request["timestamp"],
            "nonce": token_request["nonce"],
            "mac": token_request["mac"],
        })
    except Exception as e:
        return Response({"detail": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
