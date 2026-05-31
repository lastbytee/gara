class LocalizationService {
  static String _locale = 'en';

  static String get locale => _locale;

  static void setLocale(String lang) {
    _locale = lang;
  }

  static String translate({
    required String en,
    String? rw,
  }) {
    if (_locale == 'rw' && rw != null) return rw;
    return en;
  }

  // ── General ──
  static String get appTitle => translate(en: 'Gara', rw: 'Gara');
  static String get tagline => translate(
    en: 'Fast. Structured. Reliable. Healthcare at your fingertips.',
    rw: 'Byihuta. Biteganyijwe. Biringiye. Ubuvuzi bukugeraho.',
  );
  static String get login => translate(en: 'Login', rw: 'Injira');
  static String get register => translate(en: 'Register', rw: 'Iyandikishe');
  static String get email => translate(en: 'Email', rw: 'Imeri');
  static String get password => translate(en: 'Password', rw: 'Ijambo ry\'ibanga');
  static String get confirmPassword => translate(en: 'Confirm Password', rw: 'Emeza ijambo ry\'ibanga');
  static String get username => translate(en: 'Username', rw: 'Izina ry\'ukoresha');
  static String get firstName => translate(en: 'First Name', rw: 'Izina');
  static String get lastName => translate(en: 'Last Name', rw: 'Irikurikira');
  static String get phoneNumber => translate(en: 'Phone Number', rw: 'Numero ya telefoni');
  static String get submit => translate(en: 'Submit', rw: 'Ohereza');
  static String get cancel => translate(en: 'Cancel', rw: 'Guhagarika');
  static String get confirm => translate(en: 'Confirm', rw: 'Emeza');
  static String get loading => translate(en: 'Loading...', rw: 'Birakorera...');
  static String get error => translate(en: 'Error', rw: 'Ikosa');
  static String get success => translate(en: 'Success', rw: 'Byagenze neza');
  static String get save => translate(en: 'Save', rw: 'Bika');
  static String get delete => translate(en: 'Delete', rw: 'Siba');
  static String get back => translate(en: 'Back', rw: 'Inyuma');
  static String get next => translate(en: 'Next', rw: 'Ikurikira');
  static String get done => translate(en: 'Done', rw: 'Birangiye');
  static String get required => translate(en: 'Required', rw: 'Birakenewe');
  static String get optional => translate(en: 'Optional', rw: 'Bishoboka');
  static String get send => translate(en: 'Send', rw: 'Ohereza');
  static String get stop => translate(en: 'Stop', rw: 'Hagarika');
  static String get preview => translate(en: 'Preview', rw: 'Reba');
  static String get play => translate(en: 'Play', rw: 'Kina');
  static String get noData => translate(en: 'No data', rw: 'Nta makuru');

  // ── Auth ──
  static String get rememberMe => translate(en: 'Remember Me', rw: 'Nunvikire');
  static String get forgotPassword => translate(en: 'Forgot Password?', rw: 'Wibagiwe ijambo ry\'ibanga?');
  static String get orContinueWith => translate(en: 'Or continue with', rw: 'Cyangwa ukomeze ukoresheje');
  static String get continueWithGoogle => translate(en: 'Continue with Google', rw: 'Komeza na Google');
  static String get registerAsDoctor => translate(en: 'Register as Doctor', rw: 'Iyandikishe nk\'umuganga');
  static String get registerAsPatient => translate(en: 'Register as Patient', rw: 'Iyandikishe nk\'umurwayi');
  static String get alreadyHaveAccount => translate(en: 'Already have an account? Login', rw: 'Ufite konti? Injira');
  static String get newPatientRegister => translate(en: 'New Patient? Register here', rw: 'Umurwayi mushya? Iyandikishe hano');
  static String get doctorLabel => translate(en: 'Doctor?', rw: 'Muganga?');
  static String get allUsersLogin => translate(
    en: 'All users (Patients & Doctors) login here',
    rw: 'Abakoresha bose (Abarwayi n\'abaganga) injira hano',
  );
  static String get passwordStrength => translate(en: 'Password Strength', rw: 'Ubukomeye bw\'ijambo ry\'ibanga');
  static String get weak => translate(en: 'Weak', rw: 'Rwoshye');
  static String get medium => translate(en: 'Medium', rw: 'Rwagati');
  static String get strong => translate(en: 'Strong', rw: 'Gikomeye');
  static String get minChars => translate(en: 'Min 6 chars', rw: 'Byibura inyuguti 6');
  static String get passwordsDoNotMatch => translate(en: 'Passwords do not match', rw: 'Ijambo ry\'ibanga ntabwo rihuye');
  static String get doctorRegistrationToken => translate(en: 'Doctor Registration Token', rw: 'Ikibonobono cy\'iyandikisha');
  static String get requiredForDoctor => translate(en: 'Required for doctor', rw: 'Birakenewe kwa muganga');
  static String get forgotPasswordTitle => translate(en: 'Forgot Password', rw: 'Wibagiwe ijambo ry\'ibanga');
  static String get forgotPasswordSubtitle => translate(
    en: 'Enter your email address and we\'ll send you a reset code.',
    rw: 'Shyiramo imeri yawe tuzohereza kode yo gutunganya.',
  );
  static String get resetCodeSent => translate(en: 'Reset code sent! Check your email.', rw: 'Kode yoherejwe! Reba imeri yawe.');
  static String get enterResetCode => translate(en: 'Enter reset code', rw: 'Shyiramo kode');
  static String get newPassword => translate(en: 'New Password', rw: 'Ijambo ry\'ibanga rishya');
  static String get confirmNewPassword => translate(en: 'Confirm New Password', rw: 'Emeza ijambo ry\'ibanga rishya');
  static String get resetPassword => translate(en: 'Reset Password', rw: 'Tunganya ijambo ry\'ibanga');
  static String get passwordResetSuccess => translate(en: 'Password reset successfully!', rw: 'Ijambo ry\'ibanga ryatunganyijwe!');
  static String get invalidResetCode => translate(en: 'Invalid or expired reset code.', rw: 'Kode ntabwo ikora cyangwa yarangiye.');
  static String get googleSignInFailed => translate(en: 'Google Sign-In failed', rw: 'Kwinjira na Google byananiwe');

  // ── Roles ──
  static String get patient => translate(en: 'Patient', rw: 'Umurwayi');
  static String get doctor => translate(en: 'Doctor', rw: 'Muganga');

  // ── Dashboard ──
  static String get dashboard => translate(en: 'Dashboard', rw: 'Ikibaho');
  static String get queue => translate(en: 'Queue', rw: 'Urutonde');
  static String get consultations => translate(en: 'Consultations', rw: 'Ijyanama');
  static String get prescriptions => translate(en: 'Prescriptions', rw: 'Imiti');
  static String get referrals => translate(en: 'Referrals', rw: 'Indangamuntu');
  static String get revenue => translate(en: "Today's Revenue", rw: 'Amafaranga y\'uyu munsi');
  static String get pendingApprovals => translate(en: 'Pending Approvals', rw: 'Gutegereza kwemeza');
  static String get activeConsultations => translate(en: 'Active Consultations', rw: 'Ijyanama rikora');
  static String get patients => translate(en: 'Patients', rw: 'Abarwayi');
  static String get completed => translate(en: 'Completed', rw: 'Byarangiye');
  static String get inProgress => translate(en: 'In Progress', rw: 'Birakorwa');
  static String get pending => translate(en: 'Pending', rw: 'Birategereje');
  static String get verifyPayments => translate(en: 'Verify Payments', rw: 'Genzura amafarangwa');
  static String get approveOrReject => translate(en: 'Approve or reject', rw: 'Emeza cyangwa hakanwa');
  static String get monthlyIncome => translate(en: 'Monthly Income', rw: 'Amafaranga y\'ukwezi');
  static String get welcomeBack => translate(en: 'Welcome,', rw: 'Murakaza neza,');

  // ── Patient Dashboard ──
  static String get newIntake => translate(en: 'New Intake', rw: 'Intake nshya');
  static String get submitSymptoms => translate(en: 'Submit symptoms', rw: 'Ohereza ibimenyetso');
  static String get makePayment => translate(en: 'Make Payment', rw: 'Is hyura');
  static String get forConsultation => translate(en: 'For consultation', rw: 'Kubijyanye n\'ijyanama');
  static String get viewAllPrescriptions => translate(en: 'View all prescriptions', rw: 'Reba imiti yose');
  static String get viewAllReferrals => translate(en: 'View all referrals', rw: 'Reba indangamuntu zose');
  static String get noConsultationsYet => translate(en: 'No consultations yet. Submit an intake to get started.', rw: 'Nta jyanama biracyari. Ohereza intake utangire.');
  static String get noPrescriptionsYet => translate(en: 'No prescriptions yet', rw: 'Nta miti biracyari');
  static String get noReferralsYet => translate(en: 'No referrals yet', rw: 'Nta ndangamuntu biracyari');

  // ── Medical Intake ──
  static String get symptomsDescription => translate(en: 'Describe your symptoms', rw: 'Sobanura ibimenyetso');
  static String get selectSex => translate(en: 'Biological Sex', rw: 'Igitsina');
  static String get selectSeverity => translate(en: 'Severity Level', rw: 'Urwego rw\'ubukomeye');
  static String get selectDuration => translate(en: 'Duration', rw: 'Igihe');
  static String get aiSummary => translate(en: 'AI Clinical Summary', rw: 'Incamake y\'ubuvuzi ya AI');
  static String get medicalIntake => translate(en: 'Medical Intake', rw: 'Intake y\'ubuvuzi');
  static String get submitIntake => translate(en: 'Submit Intake', rw: 'Ohereza intake');
  static String get pleaseCompleteSelections => translate(en: 'Please complete all selections', rw: 'Uzuza byose');
  static String get pleaseDescribeSymptoms => translate(en: 'Please describe your symptoms', rw: 'Sobanura ibimenyetso');

  // ── Severity ──
  static String get severityMild => translate(en: 'Mild', rw: 'Byoroheje');
  static String get severityModerate => translate(en: 'Moderate', rw: 'Guhagaze');
  static String get severitySevere => translate(en: 'Severe', rw: 'Gikomeye');
  static String get severityCritical => translate(en: 'Critical', rw: 'Gitinya ubuzima');

  // ── Duration ──
  static String get durationToday => translate(en: 'Today', rw: 'Uyu munsi');
  static String get durationFewDays => translate(en: 'Few days (2-3)', rw: 'Iminsi mike (2-3)');
  static String get durationWeek => translate(en: 'About a week', rw: 'Icyumweru');
  static String get durationTwoWeeks => translate(en: 'Two weeks', rw: 'Ibyumweru bibiri');
  static String get durationMonth => translate(en: 'About a month', rw: 'Ukwezi');
  static String get durationLonger => translate(en: 'Longer than a month', rw: 'Ukwezi n\'irenze');

  // ── Sex ──
  static String get sexMale => translate(en: 'Male', rw: 'Gabo');
  static String get sexFemale => translate(en: 'Female', rw: 'Gore');

  // ── Payment ──
  static String get payment => translate(en: 'Payment', rw: 'Kwishyura');
  static String get uploadScreenshot => translate(en: 'Upload Payment Screenshot', rw: 'Shyira screenshot y\'ishyura');
  static String get amount => translate(en: 'Amount (RWF)', rw: 'Amafaranga (RWF)');
  static String get senderPhone => translate(en: 'Sender Phone (optional)', rw: 'Telefoni yohereje (ushaka)');
  static String get payNow => translate(en: 'Pay Now', rw: 'Shyura Nonaha');
  static String get sendPaymentTo => translate(en: 'Send payment via Mobile Money to:', rw: 'Ohereza amafaranga ukoresheje Mobile Money kuri:');
  static String get paymentSubmitted => translate(en: 'Payment submitted! Waiting for doctor approval.', rw: 'Kwishyura byoherejwe! Tegereza kwemererwa n\'umuganga.');
  static String get uploadScreenshotHint => translate(en: 'Upload Payment Screenshot', rw: 'Shyira screenshot y\'ishyura');
  static String get gallery => translate(en: 'Gallery', rw: 'Iname');
  static String get camera => translate(en: 'Camera', rw: 'Kamera');
  static String get submitPayment => translate(en: 'Submit Payment', rw: 'Ohereza ishyura');
  static String get enterValidAmount => translate(en: 'Enter a valid amount', rw: 'Shyiramo amafaranga y\'ukuri');

  // ── Queue (Doctor) ──
  static String get paymentQueue => translate(en: 'Payment Queue', rw: 'Urutonde rwo kwishyura');
  static String get allPaymentsReviewed => translate(en: 'All payments reviewed!', rw: 'Kwishyura byose byagenzuwe!');
  static String get paymentApproved => translate(en: 'Payment Approved', rw: 'Kwishyura byemewe');
  static String get startConsultationNow => translate(en: 'Start a consultation now?', rw: 'Tangira ijyanama nonaha?');
  static String get later => translate(en: 'Later', rw: 'Nyuma');
  static String get startConsultation => translate(en: 'Start Consultation', rw: 'Tangira ijyanama');
  static String get paymentRejected => translate(en: 'Payment rejected', rw: 'Kwishyura byahakanwe');
  static String get failedToApprove => translate(en: 'Failed to approve payment', rw: 'Kwemeza kwishyura byananive');
  static String get failedToStartConsultation => translate(en: 'Failed to start consultation', rw: 'Kutangira ijyanama byananive');
  static String get viewPaymentScreenshot => translate(en: 'View Payment Screenshot', rw: 'Reba screenshot y\'ishyura');

  // ── Clinical Actions ──
  static String get clinicalActions => translate(en: 'Clinical Actions', rw: 'Ibikorwa by\'ubuvuzi');
  static String get prescriptionTab => translate(en: 'Prescription', rw: 'Imiti');
  static String get referralTab => translate(en: 'Referral', rw: 'Indangamuntu');
  static String get resolveTab => translate(en: 'Resolve', rw: 'Gukemura');
  static String get medication => translate(en: 'Medication', rw: 'Imiti');
  static String get dosage => translate(en: 'Dosage', rw: 'Ingano');
  static String get dosageHint => translate(en: 'Dosage (e.g., 500mg)', rw: 'Ingano (urugero: 500mg)');
  static String get frequency => translate(en: 'Frequency', rw: 'Inshuro');
  static String get frequencyHint => translate(en: 'Frequency (e.g., Twice daily)', rw: 'Inshuro (urugero: Insabibiri ku munsi)');
  static String get durationRx => translate(en: 'Duration', rw: 'Igihe');
  static String get durationHint => translate(en: 'Duration (e.g., 7 days)', rw: 'Igihe (urugero: Iminsi 7)');
  static String get notes => translate(en: 'Notes', rw: 'Ibisobanuro');
  static String get notesOptional => translate(en: 'Notes (optional)', rw: 'Ibisobanuro (bishoboka)');
  static String get createPrescription => translate(en: 'Create Prescription', rw: 'Kora imiti');
  static String get referralReason => translate(en: 'Referral Reason', rw: 'Impamvu yo kwohereza');
  static String get referredTo => translate(en: 'Referred To', rw: 'Woherejwe kwa');
  static String get referredToHint => translate(en: 'Refer To (Hospital/Clinic/Specialist)', rw: 'Ohereza kuri (Ibitaro/Isoko/y\'inzobere)');
  static String get priority => translate(en: 'Priority', rw: 'Agaciro');
  static String get additionalNotesOptional => translate(en: 'Additional Notes (optional)', rw: 'Ibisobanuro by\'inyongera (bishoboka)');
  static String get createReferral => translate(en: 'Create Referral', rw: 'Kora indangamuntu');
  static String get finalizeConsultation => translate(en: 'Finalize this consultation', rw: 'Kemura iyi jyanama');
  static String get resolveDescription => translate(en: 'Mark as resolved after completing clinical assessment', rw: 'Shyira ikimenyetso ko byakemuwe nyuma yo gusesengura');
  static String get markAsResolved => translate(en: 'Mark as Resolved', rw: 'Shyira ikimenyetso ko byakemuwe');
  static String get resolveConsultationTitle => translate(en: 'Resolve Consultation', rw: 'Kemura ijyanama');
  static String get resolveConfirmation => translate(en: 'Mark this consultation as resolved?', rw: 'Shyira ikimenyetso ko iyi jyanama yakemuwe?');
  static String get consultationResolved => translate(en: 'Consultation resolved', rw: 'Ijyanama ryakemuwe');
  static String get medicationDosageRequired => translate(en: 'Medication and dosage required', rw: 'Imiti n\'ingano birakenewe');
  static String get prescriptionCreated => translate(en: 'Prescription created. Consultation resolved.', rw: 'Imiti yarakozwe. Ijyanama ryakemuwe.');
  static String get reasonFacilityRequired => translate(en: 'Reason and facility required', rw: 'Impamvu n\'ahantu birakenewe');
  static String get referralCreated => translate(en: 'Referral created. Consultation updated.', rw: 'Indangamuntu yarakozwe. Ijyanama ryavuguruwe.');

  // ── Consultation / Chat ──
  static String get clinicalActionsTooltip => translate(en: 'Clinical Actions', rw: 'Ibikorwa by\'ubuvuzi');
  static String get noMessagesYet => translate(en: 'No messages yet. Start the consultation.', rw: 'Nta ubutumwa buracyari. Tangira ijyanama.');
  static String get typeMessage => translate(en: 'Type a message...', rw: 'Andika ubutumwa...');
  static String get recordingLabel => translate(en: 'Recording...', rw: 'Birafata amajwi...');
  static String get voiceNote => translate(en: 'Voice Note', rw: 'Amajwi');
  static String get playing => translate(en: 'Playing...', rw: 'Birakina...');
  static String get failedToSendPhoto => translate(en: 'Failed to send photo', rw: 'Kohereza ifoto byananive');
  static String get failedToSendImage => translate(en: 'Failed to send image', rw: 'Kohereza ishusho byananive');
  static String get failedToSendVoice => translate(en: 'Failed to send voice note', rw: 'Kohereza amajwi byananive');
  static String get microphonePermissionDenied => translate(en: 'Microphone permission denied', rw: 'Uburenganzira bwa mikoro bwakanwe');
  static String get galleryTooltip => translate(en: 'Gallery', rw: 'Iname');
  static String get cameraTooltip => translate(en: 'Camera', rw: 'Kamera');
  static String get voiceNoteTooltip => translate(en: 'Voice note', rw: 'Amajwi');

  // ── Patient List ──
  static String get allPatients => translate(en: 'All Patients', rw: 'Abarwayi bose');
  static String get noPatients => translate(en: 'No patients registered', rw: 'Nta barwayi biyandikishije');
  static String get startConsultationTitle => translate(en: 'Start Consultation', rw: 'Tangira ijyanama');
  static String get createConsultationWith => translate(en: 'Create a consultation with @name?', rw: 'Tangira ijyanama na @name?');

  // ── My Prescriptions (Patient) ──
  static String get myPrescriptions => translate(en: 'My Prescriptions', rw: 'Imiti yanjye');
  static String get dosageLabel => translate(en: 'Dosage', rw: 'Ingano');
  static String get frequencyLabel => translate(en: 'Frequency', rw: 'Inshuro');
  static String get durationLabel => translate(en: 'Duration', rw: 'Igihe');
  static String get notesLabel => translate(en: 'Notes', rw: 'Ibisobanuro');

  // ── My Referrals (Patient) ──
  static String get myReferrals => translate(en: 'My Referrals', rw: 'Indangamuntu zanjye');
  static String get reasonLabel => translate(en: 'Reason:', rw: 'Impamvu:');
  static String get notesLabelRef => translate(en: 'Notes:', rw: 'Ibisobanuro:');
  static String get fromDoctor => translate(en: 'From: Dr. @name', rw: 'Biva kwa: Dr. @name');

  // ── Notifications ──
  static String get notifications => translate(en: 'Notifications', rw: 'Imenyesha');
  static String get markAllRead => translate(en: 'Mark all read', rw: 'Shyira byose nk\'ibisomwe');
  static String get noNotifications => translate(en: 'No notifications', rw: 'Nta menyesha');

  // ── Submitted Info ──
  static String get submittedInformation => translate(en: 'Submitted Information', rw: 'Amakuru yoherejwe');
  static String get sexLabel => translate(en: 'Sex', rw: 'Igitsina');
  static String get severityLabel => translate(en: 'Severity', rw: 'Ubukomeye');
  static String get durationLabelShort => translate(en: 'Duration', rw: 'Igihe');
  static String get symptomsLabel => translate(en: 'Symptoms', rw: 'Ibimenyetso');
  static String get generatingSummary => translate(en: 'Generating summary...', rw: 'Bitegura incamake...');

  // ── Errors ──
  static String get connectionError => translate(en: 'Connection error. Check your network.', rw: 'Ikosa ry\'itumanaho. Reba network yawe.');
  static String get anErrorOccurred => translate(en: 'An error occurred', rw: 'Habaye ikosa');
  static String get unknownError => translate(en: 'Unknown error', rw: 'Ikosa ritazwi');
}
