import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../models/referral.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../services/localization_service.dart';

class MyReferralsScreen extends StatefulWidget {
  const MyReferralsScreen({super.key});

  @override
  State<MyReferralsScreen> createState() => _MyReferralsScreenState();
}

class _MyReferralsScreenState extends State<MyReferralsScreen> {
  List<ReferralModel> _referrals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await ApiService.get(ApiConfig.myReferrals);
      setState(() {
        _referrals = (data['results'] as List? ?? [])
            .map((e) => ReferralModel.fromJson(e as Map<String, dynamic>))
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
      appBar: AppBar(title: Text(LocalizationService.myReferrals)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _referrals.isEmpty
              ? Center(child: Text(LocalizationService.noReferralsYet))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _referrals.length,
                    itemBuilder: (_, i) {
                      final r = _referrals[i];
                      final urgencyColor = r.priority == 'EMERGENCY'
                          ? Colors.red
                          : (r.priority == 'URGENT' ? GaraTheme.warning : GaraTheme.accent);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _showDetail(r),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.transfer_within_a_station, color: urgencyColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(r.referredTo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: urgencyColor.withAlpha(30),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(r.priority, style: TextStyle(fontSize: 10, color: urgencyColor, fontWeight: FontWeight.bold)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share, size: 20),
                                      onPressed: () => _share(r),
                                      tooltip: LocalizationService.translate(en: 'Share', rw: 'Sangira'),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Text(LocalizationService.reasonLabel, style: const TextStyle(fontSize: 12, color: GaraTheme.textSecondary, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(r.referralReason, style: const TextStyle(fontSize: 13)),
                                if (r.notes != null && r.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(LocalizationService.notesLabelRef, style: const TextStyle(fontSize: 12, color: GaraTheme.textSecondary, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(r.notes!, style: const TextStyle(fontSize: 13)),
                                ],
                                const SizedBox(height: 8),
                                Text(LocalizationService.translate(en: 'From: Dr. ${r.doctorName}', rw: 'Biva kwa: Dr. ${r.doctorName}'), style: const TextStyle(fontSize: 12, color: GaraTheme.textSecondary)),
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

  void _showDetail(ReferralModel r) {
    final urgencyColor = r.priority == 'EMERGENCY'
        ? Colors.red
        : (r.priority == 'URGENT' ? GaraTheme.warning : GaraTheme.accent);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.transfer_within_a_station, color: urgencyColor),
            const SizedBox(width: 8),
            Expanded(child: Text(r.referredTo)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${LocalizationService.translate(en: 'Priority:', rw: "Iby'urutare:")} ${r.priority}', style: TextStyle(color: urgencyColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(LocalizationService.reasonLabel, style: const TextStyle(fontSize: 12, color: GaraTheme.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(r.referralReason, style: const TextStyle(fontSize: 13)),
            if (r.notes != null && r.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(LocalizationService.notesLabelRef, style: const TextStyle(fontSize: 12, color: GaraTheme.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(r.notes!, style: const TextStyle(fontSize: 13)),
            ],
            const SizedBox(height: 8),
            Text(LocalizationService.translate(en: 'From: Dr. ${r.doctorName}', rw: 'Biva kwa: Dr. ${r.doctorName}'), style: const TextStyle(fontSize: 13, color: GaraTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LocalizationService.cancel)),
          FilledButton.icon(
            icon: const Icon(Icons.share, size: 18),
            label: Text(LocalizationService.translate(en: 'Share', rw: 'Sangira')),
            onPressed: () { Navigator.pop(ctx); _share(r); },
          ),
        ],
      ),
    );
  }

  Future<void> _share(ReferralModel r) async {
    final text = '${LocalizationService.translate(en: "Referral", rw: "Kwohereza")}: ${r.referredTo}\n'
        '${LocalizationService.translate(en: "Priority", rw: "Iby\u2019urutare")}: ${r.priority}\n'
        '${LocalizationService.reasonLabel}: ${r.referralReason}\n'
        '${LocalizationService.translate(en: "Dr.", rw: "Dr.")}: ${r.doctorName}';
    await SharePlus.instance.share(ShareParams(text: text));
  }
}
