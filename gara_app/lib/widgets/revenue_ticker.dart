import 'package:flutter/material.dart';
import '../config/theme.dart';

class RevenueTicker extends StatelessWidget {
  final double totalRevenue;
  final int approvedCount;

  const RevenueTicker({
    super.key,
    required this.totalRevenue,
    required this.approvedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet, size: 40, color: GaraTheme.accent),
            const SizedBox(height: 12),
            const Text(
              "Today's Revenue",
              style: TextStyle(
                fontSize: 14,
                color: GaraTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${totalRevenue.toStringAsFixed(0)} RWF',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: GaraTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$approvedCount consultation${approvedCount == 1 ? '' : 's'} approved',
              style: const TextStyle(
                fontSize: 13,
                color: GaraTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
