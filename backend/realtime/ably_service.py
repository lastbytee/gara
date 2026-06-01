import json
import asyncio
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

_client = None

def _get_client():
    global _client
    if _client is not None:
        return _client
    api_key = getattr(settings, "ABLY_API_KEY", None)
    if not api_key:
        logger.warning("ABLY_API_KEY not set — real-time disabled")
        return None
    try:
        import ably
        _client = ably.AblyRest(api_key)
        return _client
    except Exception as e:
        logger.error(f"Failed to init Ably: {e}")
        return None


def _publish(channel_name, event_name, data):
    client = _get_client()
    if client is None:
        return
    try:
        channel = client.channels.get(channel_name)
        payload = json.dumps(data, default=str)
        asyncio.run(channel.publish(event_name, payload))
    except Exception as e:
        logger.error(f"Ably publish failed: {e}")


def publish_consultation_message(consultation_id, message_data):
    _publish(f"consultation:{consultation_id}", "new_message", message_data)


def publish_consultation_status(consultation_id, status_data):
    _publish(f"consultation:{consultation_id}", "status_update", status_data)


def publish_user_notification(user_id, notification_data):
    _publish(f"user:{user_id}", "notification", notification_data)
