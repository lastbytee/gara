import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../providers/consultation_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/localization_service.dart';
import 'consultation_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<UserModel> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await ApiService.get(ApiConfig.patients);
      setState(() {
        _patients = (data['results'] as List? ?? [])
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _startConsultation(UserModel patient) {
    final cons = context.read<ConsultationProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService.startConsultationTitle),
        content: Text(LocalizationService.translate(en: 'Create a consultation with ${patient.fullName}?', rw: 'Tangira ijyanama na ${patient.fullName}?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await cons.getOrCreateConsultation(patient.id);
              if (result != null && mounted) {
                context.read<DashboardProvider>().fetchStats();
                context.read<DashboardProvider>().fetchNotifications();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConsultationChatScreen(consultation: result),
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to start consultation. Ensure patient has an approved payment.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: GaraTheme.accent),
            child: Text(LocalizationService.translate(en: 'Start', rw: 'Tangira')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocalizationService.allPatients)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? Center(child: Text(LocalizationService.noPatients))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _patients.length,
                    itemBuilder: (_, i) {
                      final p = _patients[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: GaraTheme.primaryBlue.withAlpha(25),
                            child: Text(
                              (p.fullName.isNotEmpty ? p.fullName[0] : '?').toUpperCase(),
                              style: const TextStyle(color: GaraTheme.primaryBlue, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            p.phoneNumber ?? 'No phone',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chat_bubble_outline, color: GaraTheme.primaryBlue),
                          onTap: () => _startConsultation(p),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
