import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/intake.dart';
import '../../services/localization_service.dart';
import 'payment_screen.dart';

class AiSummaryScreen extends StatelessWidget {
  final IntakeModel intake;

  const AiSummaryScreen({super.key, required this.intake});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocalizationService.aiSummary)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology, color: GaraTheme.primaryBlue),
                        const SizedBox(width: 8),
                        Text(
                          LocalizationService.aiSummary,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: GaraTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      intake.aiClinicalSummary ?? LocalizationService.generatingSummary,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: GaraTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.submittedInformation,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow(LocalizationService.sexLabel, intake.sex),
                    _infoRow(LocalizationService.severityLabel, intake.severity),
                    _infoRow(LocalizationService.durationLabelShort, intake.duration),
                    _infoRow(LocalizationService.symptomsLabel, intake.symptomsDescription, maxLines: 3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentScreen()),
              ),
              icon: const Icon(Icons.payment),
              label: Text(LocalizationService.payNow),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: GaraTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: GaraTheme.textPrimary),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
