import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../services/localization_service.dart';
import '../../models/consultation.dart';
import '../../models/notification.dart';
import 'queue_screen.dart';
import 'consultation_screen.dart';
import 'patient_list_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  Timer? _pollTimer;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${LocalizationService.dashboard} - ${context.read<AuthProvider>().user?.fullName ?? ''}',
          style: const TextStyle(fontSize: 16),
        ),
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
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${dash.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
              Consumer<DashboardProvider>(
                builder: (_, dash, __) => _statsGrid(dash.stats),
              ),
              const SizedBox(height: 20),
              _quickActions(),
              const SizedBox(height: 24),
              _sectionTitle(LocalizationService.activeConsultations),
              const SizedBox(height: 8),
              Consumer<ConsultationProvider>(
                builder: (_, cons, __) {
                  if (cons.loading && cons.consultations.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final active = cons.activeConsultations;
                  if (active.isEmpty) {
                    return _emptyCard(LocalizationService.translate(en: 'No active consultations', rw: 'Nta jyanama rikora'));
                  }
                  return Column(
                    children: active.map((c) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: GaraTheme.primaryBlue.withAlpha(25),
                          child: Text(
                            c.patientName.isNotEmpty ? c.patientName[0].toUpperCase() : '?',
                            style: const TextStyle(color: GaraTheme.primaryBlue),
                          ),
                        ),
                        title: Text(c.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Started ${c.createdAt.split('T')[0]}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          cons.setCurrentConsultation(c);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConsultationChatScreen(consultation: c),
                            ),
                          );
                        },
                      ),
                    )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color, {VoidCallback? onTap, Widget? badge}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 28, color: color),
                  if (badge != null) ...[
                    const SizedBox(width: 4),
                    badge,
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: GaraTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToConsultationList(BuildContext context, {bool activeOnly = false}) {
    final cons = context.read<ConsultationProvider>();
    final list = activeOnly
        ? cons.activeConsultations
        : cons.consultations.where((c) => !c.isActive).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationListScreen(filteredList: list, title: activeOnly ? LocalizationService.activeConsultations : LocalizationService.translate(en: 'Completed Consultations', rw: 'Ijyanama byarangiye')),
      ),
    );
  }

  Widget _changeBadge(double change, {Color? color}) {
    final isUp = change >= 0;
    final c = color ?? (isUp ? Colors.green : Colors.red);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
          color: c,
        ),
        Text(
          '${change.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c,
          ),
        ),
      ],
    );
  }

  Widget _statsGrid(stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Income row: Daily + Monthly
        Row(
          children: [
            Expanded(
              child: Card(
                color: GaraTheme.primaryBlue.withAlpha(25),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService.translate(en: "Today's Income", rw: 'Amafaranga y\'uyu munsi'),
                        style: const TextStyle(fontSize: 11, color: GaraTheme.primaryBlue),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.dailyIncome.toStringAsFixed(0)} RWF',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: GaraTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                color: GaraTheme.primaryBlue.withAlpha(20),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            LocalizationService.monthlyIncome,
                            style: const TextStyle(fontSize: 11, color: GaraTheme.primaryBlue),
                          ),
                          const Spacer(),
                          _changeBadge(stats.incomeChange, color: GaraTheme.primaryBlue),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.monthlyIncome.toStringAsFixed(0)} RWF',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: GaraTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Stat cards: Patients, Completed, In Progress, Pending
        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.people,
                LocalizationService.patients,
                '${stats.totalPatients}',
                GaraTheme.primaryBlue,
                badge: _changeBadge(stats.patientChange),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientListScreen()),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                Icons.check_circle,
                LocalizationService.completed,
                '${stats.completedConsultations}',
                GaraTheme.accent,
                onTap: () => _navigateToConsultationList(context, activeOnly: false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                Icons.chat_bubble,
                LocalizationService.inProgress,
                '${stats.inProgressConsultations}',
                GaraTheme.warning,
                onTap: () {
                  final cons = context.read<ConsultationProvider>();
                  final active = cons.activeConsultations;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConsultationListScreen(filteredList: active, title: LocalizationService.activeConsultations),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                Icons.pending_actions,
                LocalizationService.pending,
                '${stats.pendingPayments}',
                Colors.red,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentQueueScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            icon: Icons.pending_actions,
            label: LocalizationService.verifyPayments,
            subtitle: LocalizationService.approveOrReject,
            color: GaraTheme.warning,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentQueueScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Consumer<ConsultationProvider>(
            builder: (_, cons, __) => _actionCard(
              icon: Icons.chat,
              label: LocalizationService.consultations,
              subtitle: '${cons.activeConsultations.length} active',
              color: GaraTheme.primaryBlue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConsultationListScreen(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
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
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: GaraTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: GaraTheme.textPrimary,
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: GaraTheme.textSecondary),
          ),
        ),
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
                      Text(
                        LocalizationService.notifications,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (dash.unreadCount > 0)
                        TextButton(
                          onPressed: () => dash.markAllRead(),
                          child: Text(LocalizationService.markAllRead),
                        ),
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
                                onTap: () => _onNotificationTap(ctx, n),
                                leading: CircleAvatar(
                                  backgroundColor: n.isRead
                                      ? Colors.grey.withAlpha(30)
                                      : GaraTheme.primaryBlue.withAlpha(30),
                                  child: Icon(
                                    _iconForType(n.type),
                                    size: 20,
                                    color: n.isRead ? Colors.grey : GaraTheme.primaryBlue,
                                  ),
                                ),
                                title: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  n.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: n.isRead
                                    ? null
                                    : GestureDetector(
                                        onTap: () => dash.markRead(n.id),
                                        child: const Icon(Icons.check_circle_outline,
                                            size: 20, color: GaraTheme.primaryBlue),
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

  void _onNotificationTap(BuildContext ctx, NotificationModel n) {
    if (!n.isRead) {
      ctx.read<DashboardProvider>().markRead(n.id);
    }
    Navigator.pop(ctx);
    final relatedId = n.relatedId;
    if (relatedId == null) return;
    if (n.type == 'PAYMENT_SUBMITTED') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentQueueScreen()));
    } else {
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
      case 'PAYMENT_SUBMITTED':
        return Icons.payment;
      case 'PAYMENT_APPROVED':
        return Icons.check_circle;
      case 'PAYMENT_REJECTED':
        return Icons.cancel;
      case 'CONSULTATION_CREATED':
        return Icons.chat;
      case 'MESSAGE_SENT':
        return Icons.message;
      case 'PRESCRIPTION_ADDED':
        return Icons.medication;
      case 'REFERRAL_ADDED':
        return Icons.transfer_within_a_station;
      default:
        return Icons.notifications;
    }
  }
}

class ConsultationListScreen extends StatefulWidget {
  final List<ConsultationModel>? filteredList;
  final String title;
  const ConsultationListScreen({super.key, this.filteredList, this.title = 'Consultations'});

  @override
  State<ConsultationListScreen> createState() => _ConsultationListScreenState();
}

class _ConsultationListScreenState extends State<ConsultationListScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.filteredList == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ConsultationProvider>().fetchMyConsultations();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Consumer<ConsultationProvider>(
        builder: (_, cons, __) {
          final list = widget.filteredList ?? cons.consultations;
          if (cons.loading && cons.consultations.isEmpty && widget.filteredList != null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (list.isEmpty) {
            return Center(child: Text(LocalizationService.translate(en: 'No consultations yet', rw: 'Nta jyanama biracyari')));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.isActive
                        ? GaraTheme.primaryBlue.withAlpha(25)
                        : Colors.green.withAlpha(25),
                    child: Text(
                      c.patientName.isNotEmpty ? c.patientName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: c.isActive ? GaraTheme.primaryBlue : Colors.green,
                      ),
                    ),
                  ),
                  title: Text(c.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${c.status} - ${c.createdAt.split('T')[0]}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    cons.setCurrentConsultation(c);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConsultationChatScreen(consultation: c),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
