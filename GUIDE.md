# Gara Development Guide

## Prerequisites

- **Flutter SDK** (see `gara_app/pubspec.yaml` for SDK constraints)
- **Python 3.10+** with pip
- **Windows**: PowerShell 5.1+
- **Phone**: Android device connected via USB or on same LAN

## Setup

### Backend (Django)

```powershell
cd backend
python -m venv venv
venv\Scripts\Activate.ps1
pip install -r requirements.txt
# Configure .env with GOOGLE_OAUTH_CLIENT_ID, ALLOWED_HOSTS, CORS_ALLOWED_ORIGINS
python manage.py migrate
python manage.py runserver 0.0.0.0:8000  # Must use 0.0.0.0 for LAN access
```

### Frontend (Flutter)

```powershell
cd gara_app
flutter pub get
flutter run -d chrome    # Web (Google Sign-In shows SnackBar "not available")
flutter run              # Android device (auto-detected)
```

## Architecture

- **Backend**: Django REST Framework at `http://<LAN_IP>:8000/api/`
- **Frontend**: Flutter with Provider state management
- **Auth**: JWT tokens + Google OAuth (client-side sign-in, backend verifies `id_token`)
- **Real-time**: Polling every 10s (notifications, consultations, messages)
- **i18n**: Custom `LocalizationService` with English/Kinyarwanda, 120+ keys
- **Encryption**: AES-256-CBC per-consultation key (`encrypt` package on Flutter)

## Key Configuration

| Setting | Location | Value |
|---------|----------|-------|
| API Base URL | `lib/config/api_config.dart` | `http://10.195.221.137:8000/api` |
| Google Client ID | `api_config.dart`, `web/index.html`, `.env` | `454865273682-...apps.googleusercontent.com` |
| Application ID | `web/index.html` | `com.gara.app` |

## Deployment

### Build APK

```powershell
cd gara_app
flutter build apk --debug
# APK at: build\app\outputs\flutter-apk\app-debug.apk
```

Transfer APK to phone and install. Ensure phone can reach `http://<LAN_IP>:8000`.

## Platform-Specific Notes

### Windows Firewall (Phone Hotspot)

When the phone creates a hotspot, the laptop's network profile is **Public**. Windows Firewall blocks `python.exe` on Public networks.

**Fix**: Run as Administrator:
```powershell
New-NetFirewallRule -DisplayName "Django 8000" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow -Profile Any
```

Or change network to **Private** in Settings > Network & Internet > Wi-Fi.

### Google Sign-In

- **Mobile (Android)**: Uses `authenticate()` with `serverClientId`. SHA-1 debug fingerprint (`8D:C2:85:A5:25:20:47:DF:8B:E6:9B:9B:D4:FF:88:F5:D8:5E:31:7E`) must be registered in Google Cloud Console.
- **Web (Chrome)**: Disabled — shows orange SnackBar "Google Sign-In not available on web".
- `google_sign_in` v7.2.0: `initialize()` is called once (static `_googleInitialized` guard), accepts both `clientId` and `serverClientId`.

### Password Reset

Password reset endpoint returns the 6-digit code in the response body (no email configured for dev).

## Testing

- `flutter analyze` must show **0 errors, 0 warnings** before committing
- Run Django tests: `cd backend && python manage.py test`
- No Flutter test suite configured yet

## Session Summary (May 30, 2026)

### Changes Made

1. **Notifications clickable** (both dashboards)
   - Added `onTap` to notification `ListTile` in `doctor/dashboard_screen.dart` and `patient/patient_dashboard_screen.dart`
   - Doctor: `PAYMENT_SUBMITTED` → `PaymentQueueScreen`; all other types → `ConsultationChatScreen`
   - Patient: `PRESCRIPTION_ADDED` → `MyPrescriptionsScreen`; `REFERRAL_ADDED` → `MyReferralsScreen`; `PAYMENT_APPROVED` → `PaymentScreen`; other types → `ConsultationChatScreen`
   - Marks notification as read before navigating

2. **Prescription/Referral opening & share**
   - `my_prescriptions_screen.dart`: Added `InkWell` onTap → detail dialog with share button; share icon on card
   - `my_referrals_screen.dart`: Same pattern — `InkWell` onTap → dialog + share
   - Uses `share_plus` 13.1.0 for text sharing

3. **Email & username validation**
   - Flutter `register_screen.dart`: Username regex `^[a-zA-Z0-9_]{3,30}$`; email regex `^[^\s@]+@[^\s@]+\.[^\s@]+$`
   - Flutter `forgot_password_screen.dart`: Email regex validation
   - Django `accounts/serializers.py`: `validate_username` with `re.match`; `validate_email` with Django's `EmailValidator`

4. **Message encryption**
   - Added `encrypt` 5.0.3 package
   - Created `lib/services/encryption_service.dart` with AES-256-CBC per-consultation key
   - `consultation_provider.dart`: Encrypts `text_content` in `sendTextMessage`; decrypts in `fetchMessages`
   - Format: `base64(ciphertext):base64(iv)` — decrypts gracefully if already plaintext

### Key Fixes from Google Sign-In v7 Migration

- `serverClientId` added to `initialize()` to fix Android error
- `kIsWeb` guard to skip `authenticate()` on web (throws `UnimplementedError`)
- Static `_googleInitialized` flag prevents double `initialize()`
- Error messages now show actual server error instead of generic "Connection error"

### Current Issues

- File encryption (images/audio) not yet implemented — only text content is encrypted
- No `CryptoKey` / key rotation strategy — deterministic key per consultation
- SHA-1 fingerprint registered in Google Cloud Console is the **debug** key — release build will need production SHA-1
