class ApiConfig {
  // Override with --dart-define=BASE_URL=https://your-api.com/api for production builds
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://jethrona.pythonanywhere.com/api',
  );
  static const String registerPatient = '/auth/register/patient/';
  static const String registerDoctor = '/auth/register/doctor/';
  static const String login = '/auth/login/';
  static const String refresh = '/auth/refresh/';
  static const String me = '/auth/me/';
  static const String updateProfile = '/auth/me/update/';
  static const String patients = '/auth/patients/';
  static const String createIntake = '/intake/create/';
  static const String myIntakes = '/intake/my/';
  static const String allIntakes = '/intake/all/';
  static const String createPayment = '/payments/create/';
  static const String myPayments = '/payments/my/';
  static const String pendingPayments = '/payments/pending/';
  static const String allPayments = '/payments/all/';
  static const String dailyRevenue = '/payments/daily-revenue/';
  static const String createConsultation = '/consultations/create/';
  static const String myConsultations = '/consultations/my/';

  static String reviewPayment(int id) => '/payments/$id/review/';
  static String consultationDetail(int id) => '/consultations/$id/';
  static String consultationMessages(int id) => '/consultations/$id/messages/';
  static String sendMessage(int id) => '/consultations/$id/send/';
  static String updateStatus(int id) => '/consultations/$id/status/';
  static const String myPrescriptions = '/clinical/my-prescriptions/';
  static const String myReferrals = '/clinical/my-referrals/';
  static String createPrescription(int id) => '/clinical/consultation/$id/prescriptions/';
  static String getPrescriptions(int id) => '/clinical/consultation/$id/prescriptions/list/';
  static String createReferral(int id) => '/clinical/consultation/$id/referrals/';
  static String getReferrals(int id) => '/clinical/consultation/$id/referrals/list/';

  // Dashboard & Notifications
  static const String dashboardStats = '/consultations/dashboard/';
  static const String myNotifications = '/notifications/my/';
  static const String unreadCount = '/notifications/unread-count/';
  static String markNotificationRead(int id) => '/notifications/$id/read/';
  static const String markAllRead = '/notifications/read-all/';

  // Auth additions
  static const String passwordReset = '/auth/password-reset/';
  static const String passwordResetConfirm = '/auth/password-reset/confirm/';
  static const String googleAuth = '/auth/google/';

  // Real-time
  static const String ablyToken = '/realtime/token/';

  // Google OAuth
  // On Android: this should be a Google Cloud Web client ID (NOT Android client ID).
  // The Web client ID is what gets sent to your backend for verification.
  // The Android client ID (with SHA-1) goes in android/app/src/main/res/values/strings.xml as default_web_client_id.
  // If you don't have a Web client ID, create one:
  //   Google Cloud Console → APIs & Services → Credentials → Create OAuth client ID → Web application
  static const String googleClientId = '782011715209-2p1b2og72drkhcpqrnbq5rt9jqts13iu.apps.googleusercontent.com';
  // Web client ID for Flutter web (same as above, but must be a Web application type in Google Cloud Console)
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '782011715209-2p1b2og72drkhcpqrnbq5rt9jqts13iu.apps.googleusercontent.com',
  );
}
