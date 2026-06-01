import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../models/payment.dart';

class PatientQueueCard extends StatelessWidget {
  final PaymentModel payment;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const PatientQueueCard({
    super.key,
    required this.payment,
    required this.onApprove,
    required this.onReject,
  });

  void _showScreenshot(BuildContext context) {
    if (payment.screenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No screenshot uploaded')),
      );
      return;
    }
    final url = '${ApiConfig.baseUrl.replaceAll('/api', '')}media/${payment.screenshot}';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Padding(
            padding: EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.broken_image, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text('Screenshot not available'),
            ]),
          )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: GaraTheme.primaryBlue.withAlpha(25),
                  child: const Icon(Icons.person, color: GaraTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${payment.amount.toStringAsFixed(0)} RWF',
                        style: const TextStyle(
                          color: GaraTheme.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GaraTheme.warning.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: GaraTheme.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (payment.senderPhone != null) ...[
              const SizedBox(height: 8),
              Text('Sender: ${payment.senderPhone}', style: const TextStyle(fontSize: 13, color: GaraTheme.textSecondary)),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showScreenshot(context),
                icon: const Icon(Icons.image, size: 16),
                label: const Text('View Payment Screenshot'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GaraTheme.primaryBlue,
                  side: const BorderSide(color: GaraTheme.primaryBlue),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GaraTheme.error,
                      side: const BorderSide(color: GaraTheme.error),
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GaraTheme.accent,
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
