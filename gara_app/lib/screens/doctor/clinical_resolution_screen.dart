import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/consultation.dart';
import '../../providers/consultation_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../services/localization_service.dart';

class ClinicalResolutionScreen extends StatefulWidget {
  final ConsultationModel consultation;
  const ClinicalResolutionScreen({super.key, required this.consultation});

  @override
  State<ClinicalResolutionScreen> createState() => _ClinicalResolutionScreenState();
}

class _ClinicalResolutionScreenState extends State<ClinicalResolutionScreen> {
  final _medCtl = TextEditingController();
  final _dosageCtl = TextEditingController();
  final _freqCtl = TextEditingController();
  final _durCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  final _reasonCtl = TextEditingController();
  final _referredToCtl = TextEditingController();
  final _referralNotesCtl = TextEditingController();
  String _priority = 'STANDARD';

  Future<void> _createPrescription() async {
    if (_medCtl.text.isEmpty || _dosageCtl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.medicationDosageRequired)),
      );
      return;
    }
    try {
      await ApiService.post(ApiConfig.createPrescription(widget.consultation.id), body: {
        'medication': _medCtl.text.trim(),
        'dosage': _dosageCtl.text.trim(),
        'frequency': _freqCtl.text.trim(),
        'duration': _durCtl.text.trim(),
        'notes': _notesCtl.text.trim(),
      });
      await context.read<ConsultationProvider>().updateStatus(widget.consultation.id, 'RESOLVED');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.prescriptionCreated), backgroundColor: GaraTheme.accent),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _createReferral() async {
    if (_reasonCtl.text.isEmpty || _referredToCtl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.reasonFacilityRequired)),
      );
      return;
    }
    try {
      await ApiService.post(ApiConfig.createReferral(widget.consultation.id), body: {
        'priority': _priority,
        'referral_reason': _reasonCtl.text.trim(),
        'referred_to': _referredToCtl.text.trim(),
        'notes': _referralNotesCtl.text.trim(),
      });
      await context.read<ConsultationProvider>().updateStatus(widget.consultation.id, 'RESOLVED');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.referralCreated), backgroundColor: GaraTheme.accent),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _resolveConsultation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(LocalizationService.resolveConsultationTitle),
        content: Text(LocalizationService.resolveConfirmation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(LocalizationService.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(LocalizationService.confirm)),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<ConsultationProvider>().updateStatus(widget.consultation.id, 'RESOLVED');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.consultationResolved), backgroundColor: GaraTheme.accent),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _medCtl.dispose();
    _dosageCtl.dispose();
    _freqCtl.dispose();
    _durCtl.dispose();
    _notesCtl.dispose();
    _reasonCtl.dispose();
    _referredToCtl.dispose();
    _referralNotesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocalizationService.clinicalActions),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.medication), text: LocalizationService.prescriptionTab),
              Tab(icon: Icon(Icons.transfer_within_a_station), text: LocalizationService.referralTab),
              Tab(icon: Icon(Icons.check_circle), text: LocalizationService.resolveTab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _prescriptionTab(),
            _referralTab(),
            _resolveTab(),
          ],
        ),
      ),
    );
  }

  Widget _prescriptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(controller: _medCtl, decoration: InputDecoration(labelText: LocalizationService.medication, prefixIcon: Icon(Icons.medication))),
          const SizedBox(height: 12),
          TextFormField(controller: _dosageCtl, decoration: InputDecoration(labelText: LocalizationService.dosageHint, prefixIcon: Icon(Icons.science))),
          const SizedBox(height: 12),
          TextFormField(controller: _freqCtl, decoration: InputDecoration(labelText: LocalizationService.frequencyHint, prefixIcon: Icon(Icons.repeat))),
          const SizedBox(height: 12),
          TextFormField(controller: _durCtl, decoration: InputDecoration(labelText: LocalizationService.durationHint, prefixIcon: Icon(Icons.calendar_today))),
          const SizedBox(height: 12),
          TextFormField(controller: _notesCtl, maxLines: 3, decoration: InputDecoration(labelText: LocalizationService.notesOptional, alignLabelWithHint: true)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createPrescription,
            icon: const Icon(Icons.save),
            label: Text(LocalizationService.createPrescription),
          ),
        ],
      ),
    );
  }

  Widget _referralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(controller: _referredToCtl, decoration: InputDecoration(labelText: LocalizationService.referredToHint, prefixIcon: Icon(Icons.local_hospital))),
          const SizedBox(height: 12),
          TextFormField(controller: _reasonCtl, maxLines: 3, decoration: InputDecoration(labelText: LocalizationService.referralReason, alignLabelWithHint: true)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _priority,
            decoration: InputDecoration(labelText: LocalizationService.priority, prefixIcon: Icon(Icons.flag)),
            items: ['STANDARD', 'URGENT', 'EMERGENCY'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() => _priority = v ?? 'STANDARD'),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _referralNotesCtl, maxLines: 2, decoration: InputDecoration(labelText: LocalizationService.additionalNotesOptional, alignLabelWithHint: true)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createReferral,
            icon: const Icon(Icons.send),
            label: Text(LocalizationService.createReferral),
            style: ElevatedButton.styleFrom(backgroundColor: GaraTheme.warning),
          ),
        ],
      ),
    );
  }

  Widget _resolveTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: GaraTheme.accent),
            const SizedBox(height: 24),
            Text(
              LocalizationService.finalizeConsultation,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              LocalizationService.resolveDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: GaraTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _resolveConsultation,
              icon: const Icon(Icons.check),
              label: Text(LocalizationService.markAsResolved),
              style: ElevatedButton.styleFrom(backgroundColor: GaraTheme.accent),
            ),
          ],
        ),
      ),
    );
  }
}
