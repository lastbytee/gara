import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../models/prescription.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../services/localization_service.dart';

class MyPrescriptionsScreen extends StatefulWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  State<MyPrescriptionsScreen> createState() => _MyPrescriptionsScreenState();
}

class _MyPrescriptionsScreenState extends State<MyPrescriptionsScreen> {
  List<PrescriptionModel> _prescriptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await ApiService.get(ApiConfig.myPrescriptions);
      setState(() {
        _prescriptions = (data['results'] as List? ?? [])
            .map((e) => PrescriptionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocalizationService.myPrescriptions)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? Center(child: Text(LocalizationService.noPrescriptionsYet))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _prescriptions.length,
                    itemBuilder: (_, i) {
                      final rx = _prescriptions[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _showDetail(rx),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.medication, color: GaraTheme.primaryBlue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(rx.medication, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share, size: 20),
                                      onPressed: () => _share(rx),
                                      tooltip: LocalizationService.translate(en: 'Share', rw: 'Sangira'),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                _row(LocalizationService.dosageLabel, rx.dosage),
                                _row(LocalizationService.frequencyLabel, rx.frequency),
                                _row(LocalizationService.durationLabel, rx.duration),
                                if (rx.notes != null && rx.notes!.isNotEmpty) _row(LocalizationService.notesLabel, rx.notes!),
                                const SizedBox(height: 8),
                                Text('${LocalizationService.translate(en: 'Dr.', rw: 'Dr.')} ${rx.doctorName}', style: const TextStyle(fontSize: 12, color: GaraTheme.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showDetail(PrescriptionModel rx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.medication, color: GaraTheme.primaryBlue),
            const SizedBox(width: 8),
            Expanded(child: Text(rx.medication)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(LocalizationService.dosageLabel, rx.dosage),
            _row(LocalizationService.frequencyLabel, rx.frequency),
            _row(LocalizationService.durationLabel, rx.duration),
            if (rx.notes != null && rx.notes!.isNotEmpty) _row(LocalizationService.notesLabel, rx.notes!),
            const SizedBox(height: 8),
            Text('${LocalizationService.translate(en: 'Dr.', rw: 'Dr.')} ${rx.doctorName}', style: const TextStyle(fontSize: 13, color: GaraTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LocalizationService.cancel)),
          FilledButton.icon(
            icon: const Icon(Icons.share, size: 18),
            label: Text(LocalizationService.translate(en: 'Share', rw: 'Sangira')),
            onPressed: () { Navigator.pop(ctx); _share(rx); },
          ),
        ],
      ),
    );
  }

  Future<void> _share(PrescriptionModel rx) async {
    final text = '${LocalizationService.translate(en: "Prescription", rw: "Imiti")}: ${rx.medication}\n'
        '${LocalizationService.dosageLabel}: ${rx.dosage}\n'
        '${LocalizationService.frequencyLabel}: ${rx.frequency}\n'
        '${LocalizationService.durationLabel}: ${rx.duration}\n'
        '${LocalizationService.translate(en: "Dr.", rw: "Dr.")}: ${rx.doctorName}';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: GaraTheme.textSecondary, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
