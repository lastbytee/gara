import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/payment_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/patient_queue_card.dart';
import '../../services/localization_service.dart';
import 'consultation_screen.dart';

class PaymentQueueScreen extends StatefulWidget {
  const PaymentQueueScreen({super.key});

  @override
  State<PaymentQueueScreen> createState() => _PaymentQueueScreenState();
}

class _PaymentQueueScreenState extends State<PaymentQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().fetchPendingPayments();
    });
  }

  Future<void> _handleApprove(int paymentId, int patientId, String patientName) async {
    final payment = context.read<PaymentProvider>();
    final data = await payment.reviewPayment(paymentId, 'APPROVED');
    if (!mounted) return;

    if (data != null) {
      _promptStartConsultation(patientId, patientName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.failedToApprove), backgroundColor: Colors.red),
      );
    }
  }

  void _promptStartConsultation(int patientId, String patientName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService.paymentApproved),
        content: Text(LocalizationService.translate(en: 'Payment from $patientName approved. Start a consultation now?', rw: 'Kwishyura bya $patientName byemewe. Tangira ijyanama nonaha?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.later),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final cons = context.read<ConsultationProvider>();
              final result = await cons.getOrCreateConsultation(patientId);
              if (result != null && mounted) {
                context.read<DashboardProvider>().fetchStats();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConsultationChatScreen(consultation: result),
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LocalizationService.failedToStartConsultation),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: GaraTheme.accent),
            child: Text(LocalizationService.startConsultation),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReject(int paymentId) async {
    final payment = context.read<PaymentProvider>();
    await payment.reviewPayment(paymentId, 'REJECTED');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.paymentRejected), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocalizationService.paymentQueue)),
      body: Consumer<PaymentProvider>(
        builder: (_, payment, __) {
          if (payment.pendingPayments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: GaraTheme.accent),
                  SizedBox(height: 16),
                  Text(LocalizationService.allPaymentsReviewed, style: const TextStyle(fontSize: 16, color: GaraTheme.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: payment.pendingPayments.length,
            itemBuilder: (_, i) {
              final p = payment.pendingPayments[i];
              return PatientQueueCard(
                payment: p,
                onApprove: () => _handleApprove(p.id, p.patient, p.patientName),
                onReject: () => _handleReject(p.id),
              );
            },
          );
        },
      ),
    );
  }
}
