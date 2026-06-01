import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import '../../config/api_config.dart';

class WebGoogleSignIn {
  static Completer<String>? _pending;
  static bool _loaded = false;

  static Future<void> ensureInitialized() async {
    if (_loaded) return;
    final completer = Completer<void>();
    final script = html.ScriptElement()
      ..src = 'https://accounts.google.com/gsi/client'
      ..async = true;
    script.onLoad.listen((_) => completer.complete());
    html.document.body!.append(script);
    await completer.future;
    _loaded = true;
  }

  static Future<String?> signIn() async {
    if (!_loaded) await ensureInitialized();
    _pending = Completer<String>();

    final config = js.JsObject.jsify({
      'client_id': ApiConfig.googleWebClientId,
      'scope': 'openid profile email',
      'callback': js.JsFunction.withThis((_, response) {
        final resp = response as js.JsObject;
        final error = resp['error'];
        if (error != null) {
          _pending?.completeError('Google Sign-In error: $error');
          return;
        }
        final idToken = resp['id_token'] as String?;
        _pending?.complete(idToken ?? '');
      }),
    });

    final google = js.context['google'] as js.JsObject;
    final oauth2 = google['accounts']?['oauth2'] as js.JsObject?;
    if (oauth2 == null) {
      _pending?.completeError('Google Identity Services not loaded');
      return _pending?.future;
    }
    final tokenClient = oauth2.callMethod('initTokenClient', [config]);
    tokenClient.callMethod('requestAccessToken');

    return _pending!.future.timeout(const Duration(seconds: 60));
  }
}
