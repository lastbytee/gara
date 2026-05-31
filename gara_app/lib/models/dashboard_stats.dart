class DashboardStats {
  final double dailyIncome;
  final double monthlyIncome;
  final int totalPatients;
  final double patientChange;
  final double incomeChange;
  final int completedConsultations;
  final int inProgressConsultations;
  final int pendingPayments;
  final int unreadNotifications;

  DashboardStats({
    required this.dailyIncome,
    required this.monthlyIncome,
    required this.totalPatients,
    required this.patientChange,
    required this.incomeChange,
    required this.completedConsultations,
    required this.inProgressConsultations,
    required this.pendingPayments,
    required this.unreadNotifications,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      dailyIncome: (json['daily_income'] as num?)?.toDouble() ?? 0,
      monthlyIncome: (json['monthly_income'] as num).toDouble(),
      totalPatients: json['total_patients'] as int,
      patientChange: (json['patient_change'] as num?)?.toDouble() ?? 0,
      incomeChange: (json['income_change'] as num?)?.toDouble() ?? 0,
      completedConsultations: json['completed_consultations'] as int,
      inProgressConsultations: json['in_progress_consultations'] as int,
      pendingPayments: json['pending_payments'] as int,
      unreadNotifications: json['unread_notifications'] as int,
    );
  }

  DashboardStats.initial()
      : dailyIncome = 0,
        monthlyIncome = 0,
        totalPatients = 0,
        patientChange = 0,
        incomeChange = 0,
        completedConsultations = 0,
        inProgressConsultations = 0,
        pendingPayments = 0,
        unreadNotifications = 0;
}
