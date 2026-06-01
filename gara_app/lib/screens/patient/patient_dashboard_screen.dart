import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../models/consultation.dart';
import '../../models/notification.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/prescription.dart';
import '../../models/referral.dart';
import '../doctor/consultation_screen.dart';
import 'intake_form_screen.dart';
import '../../services/localization_service.dart';
import 'payment_screen.dart';
import 'my_prescriptions_screen.dart';
import 'my_referrals_screen.dart';
import '../profile_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  Timer? _pollTimer;
  List<PrescriptionModel> _prescriptions = [];
  List<ReferralModel> _referrals = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final dash = context.read<DashboardProvider>();
    await Future.wait([
      dash.fetchStats(),
      dash.fetchNotifications(),
      context.read<ConsultationProvider>().fetchMyConsultations(),
    ]);
    _fetchMyData();
  }

  Future<void> _fetchMyData() async {
    try {
      final rxData = await ApiService.get(ApiConfig.myPrescriptions);
      setState(() {
        _prescriptions = (rxData['results'] as List? ?? [])
            .map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {}
    try {
      final refData = await ApiService.get(ApiConfig.myReferrals);
      setState(() {
        _referrals = (refData['results'] as List? ?? [])
            .map((e) => ReferralModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.translate(en: 'Patient Dashboard', rw: 'Ikibaho cy\'umurwayi')),
        actions: [
          Consumer<DashboardProvider>(
            builder: (_, dash, __) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => _showNotifications(context),
                ),
                if (dash.unreadCount > 0)
                  Positioned(
                    right: 6, top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle,
                      ),
                      child: Text('${dash.unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _greeting(),
              const SizedBox(height: 20),
              _quickActions(),
              const SizedBox(height: 24),
              _sectionTitle(LocalizationService.translate(en: 'My Consultations', rw: 'Ijyanama zanjye')),
              const SizedBox(height: 8),
              Consumer<ConsultationProvider>(
                builder: (_, cons, __) {
                  if (cons.loading && cons.consultations.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = cons.consultations;
                  if (list.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(LocalizationService.noConsultationsYet,
                            style: const TextStyle(color: GaraTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: list.map((c) => _consultationCard(c)).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              _sectionTitle('${LocalizationService.prescriptions} (${_prescriptions.length})'),
              const SizedBox(height: 8),
              if (_prescriptions.isEmpty) _emptyCard(LocalizationService.noPrescriptionsYet),
              if (_prescriptions.isNotEmpty) ..._prescriptions.take(3).map((rx) => _prescriptionTile(rx)),
              if (_prescriptions.length > 3)
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPrescriptionsScreen())),
                  child: Text(LocalizationService.viewAllPrescriptions),
                ),
              const SizedBox(height: 24),
              _sectionTitle('${LocalizationService.referrals} (${_referrals.length})'),
              const SizedBox(height: 8),
              if (_referrals.isEmpty) _emptyCard(LocalizationService.noReferralsYet),
              if (_referrals.isNotEmpty) ..._referrals.take(3).map((r) => _referralTile(r)),
              if (_referrals.length > 3)
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReferralsScreen())),
                  child: Text(LocalizationService.viewAllReferrals),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _greeting() {
    final user = context.watch<AuthProvider>().user;
    return Card(
      color: GaraTheme.primaryBlue.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: GaraTheme.primaryBlue,
              child: Text(
                (user?.fullName ?? 'P')[0].toUpperCase(),
                style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LocalizationService.welcomeBack, style: const TextStyle(fontSize: 14, color: GaraTheme.textSecondary)),
                Text(user?.fullName ?? 'Patient', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: GaraTheme.primaryBlue)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(child: _actionCard(Icons.assignment, LocalizationService.newIntake, LocalizationService.submitSymptoms, GaraTheme.primaryBlue, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const IntakeFormScreen()));
        })),
        const SizedBox(width: 12),
        Expanded(child: _actionCard(Icons.payment, LocalizationService.makePayment, LocalizationService.forConsultation, GaraTheme.accent, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen()));
        })),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, String subtitle, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: GaraTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GaraTheme.textPrimary));
  }

  Widget _emptyCard(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(text, style: const TextStyle(color: GaraTheme.textSecondary))),
      ),
    );
  }

  Widget _consultationCard(ConsultationModel c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: c.isActive ? GaraTheme.primaryBlue.withAlpha(25) : Colors.green.withAlpha(25),
          child: Icon(c.isActive ? Icons.chat : Icons.check_circle, color: c.isActive ? GaraTheme.primaryBlue : Colors.green, size: 20),
        ),
        title: Text('Dr. ${c.doctorName}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${c.status} - ${c.createdAt.split('T')[0]}', style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.read<ConsultationProvider>().setCurrentConsultation(c);
          Navigator.push(context, MaterialPageRoute(builder: (_) => ConsultationChatScreen(consultation: c)));
        },
      ),
    );
  }

  Widget _prescriptionTile(PrescriptionModel rx) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.medication, color: GaraTheme.primaryBlue),
        title: Text('${rx.medication} - ${rx.dosage}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text('${rx.frequency} for ${rx.duration}', style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _referralTile(ReferralModel r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.transfer_within_a_station, color: r.priority == 'EMERGENCY' ? Colors.red : GaraTheme.warning),
        title: Text('To: ${r.referredTo}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text(r.referralReason, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final dash = context.read<DashboardProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(LocalizationService.notifications, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (dash.unreadCount > 0)
                        TextButton(onPressed: () => dash.markAllRead(), child: Text(LocalizationService.markAllRead)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: dash.notifications.isEmpty
                        ? Center(child: Text(LocalizationService.noNotifications))
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: dash.notifications.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final n = dash.notifications[i];
                              return ListTile(
                                onTap: () => _onNotificationTap(n),
                                leading: CircleAvatar(
                                  backgroundColor: n.isRead ? Colors.grey.withAlpha(30) : GaraTheme.primaryBlue.withAlpha(30),
                                  child: Icon(
                                    _iconForType(n.type), size: 20,
                                    color: n.isRead ? Colors.grey : GaraTheme.primaryBlue,
                                  ),
                                ),
                                title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600, fontSize: 13)),
                                subtitle: Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                                trailing: n.isRead
                                    ? null
                                    : GestureDetector(
                                        onTap: () => dash.markRead(n.id),
                                        child: const Icon(Icons.check_circle_outline, size: 20, color: GaraTheme.primaryBlue),
                                      ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => dash.fetchStats());
  }

  void _onNotificationTap(NotificationModel n) {
    if (!n.isRead) {
      context.read<DashboardProvider>().markRead(n.id);
    }
    Navigator.pop(context);
    final relatedId = n.relatedId;
    if (relatedId == null) return;
    switch (n.type) {
      case 'PRESCRIPTION_ADDED':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPrescriptionsScreen()));
        break;
      case 'REFERRAL_ADDED':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReferralsScreen()));
        break;
      case 'PAYMENT_APPROVED':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen()));
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConsultationChatScreen(
              consultation: ConsultationModel(
                id: relatedId, patient: 0, patientName: '', doctor: 0,
                doctorName: '', status: '', createdAt: '', updatedAt: '',
              ),
            ),
          ),
        );
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'PAYMENT_SUBMITTED': return Icons.payment;
      case 'PAYMENT_APPROVED': return Icons.check_circle;
      case 'PAYMENT_REJECTED': return Icons.cancel;
      case 'CONSULTATION_CREATED': return Icons.chat;
      case 'MESSAGE_SENT': return Icons.message;
      case 'PRESCRIPTION_ADDED': return Icons.medication;
      case 'REFERRAL_ADDED': return Icons.transfer_within_a_station;
      default: return Icons.notifications;
    }
  }
}
