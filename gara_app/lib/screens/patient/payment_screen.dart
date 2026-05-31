import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/payment_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/loading_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Uint8List? _screenshotBytes;
  final _amountCtl = TextEditingController(text: Constants.consultationFee.toString());
  final _phoneCtl = TextEditingController();
  final _picker = ImagePicker();

  Future<void> _pickScreenshot() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _screenshotBytes = bytes);
    }
  }

  Future<void> _pickFromCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _screenshotBytes = bytes);
    }
  }

  Future<void> _submit() async {
    if (_screenshotBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.uploadScreenshot)),
      );
      return;
    }
    final amount = double.tryParse(_amountCtl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.enterValidAmount)),
      );
      return;
    }

    final payment = context.read<PaymentProvider>();
    final success = await payment.createPayment(
      amount: amount,
      screenshotBytes: _screenshotBytes!,
      senderPhone: _phoneCtl.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.paymentSubmitted),
          backgroundColor: GaraTheme.accent,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocalizationService.payment)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: GaraTheme.primaryBlue.withAlpha(10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: GaraTheme.primaryBlue, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      LocalizationService.sendPaymentTo,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Constants.momoNumber,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: GaraTheme.primaryBlue,
                      ),
                    ),
                    Text('Network: ${Constants.momoNetwork}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountCtl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: LocalizationService.amount,
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: LocalizationService.senderPhone,
                hintText: LocalizationService.translate(en: 'If paid from a different number', rw: 'Niba yishyuye aturutse kuri numero itandukanye'),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              LocalizationService.uploadScreenshot,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (_screenshotBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_screenshotBytes!, height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickScreenshot,
                    icon: const Icon(Icons.photo_library),
                    label: Text(LocalizationService.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(LocalizationService.camera),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Consumer<PaymentProvider>(
              builder: (_, payment, __) => LoadingButton(
                loading: payment.loading,
                label: LocalizationService.submitPayment,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
