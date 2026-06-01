import '../config/api_config.dart';
import 'api_service.dart';

typedef MessageCallback = void Function(Map<String, dynamic> data);

class AblyService {
  static bool _initialized = false;
  static final Map<String, List<MessageCallback>> _listeners = {};

  static Future<bool> init() async {
    if (_initialized) return true;
    try {
      await ApiService.get(ApiConfig.ablyToken);
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  static void subscribe(String channelName, MessageCallback callback) {
    _listeners.putIfAbsent(channelName, () => []);
    _listeners[channelName]!.add(callback);
  }

  static void unsubscribe(String channelName, MessageCallback callback) {
    _listeners[channelName]?.remove(callback);
  }

  static void fire(String channelName, Map<String, dynamic> data) {
    final cbs = _listeners[channelName];
    if (cbs != null) {
      for (final cb in cbs) {
        cb(data);
      }
    }
  }

  static void dispose() {
    _listeners.clear();
    _initialized = false;
  }
}
