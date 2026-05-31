import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/intake_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/choice_chip_group.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/loading_button.dart';
import 'ai_summary_screen.dart';

class IntakeFormScreen extends StatefulWidget {
  const IntakeFormScreen({super.key});

  @override
  State<IntakeFormScreen> createState() => _IntakeFormScreenState();
}

class _IntakeFormScreenState extends State<IntakeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsCtl = TextEditingController();
  String _lang = 'en';
  String? _sex;
  String? _severity;
  String? _duration;

  final _sexOptions = ['MALE', 'FEMALE'];
  final _severityOptions = ['MILD', 'MODERATE', 'SEVERE', 'CRITICAL'];
  final _durationOptions = [
    'TODAY', 'FEW_DAYS', 'WEEK', 'TWO_WEEKS', 'MONTH', 'LONGER',
  ];

  @override
  void dispose() {
    _symptomsCtl.dispose();
    super.dispose();
  }

  String _translateSex(String s) {
    if (_lang == 'rw') {
      return s == 'MALE' ? 'Gabo' : 'Gore';
    }
    return s == 'MALE' ? 'Male' : 'Female';
  }

  String _translateSeverity(String s) {
    if (_lang == 'rw') {
      switch (s) {
        case 'MILD': return 'Byoroheje';
        case 'MODERATE': return 'Guhagaze';
        case 'SEVERE': return 'Gikomeye';
        case 'CRITICAL': return 'Gitinya ubuzima';
        default: return s;
      }
    }
    return s[0] + s.substring(1).toLowerCase();
  }

  String _translateDuration(String s) {
    if (_lang == 'rw') {
      switch (s) {
        case 'TODAY': return 'Uyu munsi';
        case 'FEW_DAYS': return 'Iminsi mike';
        case 'WEEK': return 'Icyumweru';
        case 'TWO_WEEKS': return 'Ibyumweru 2';
        case 'MONTH': return 'Ukwezi';
        case 'LONGER': return 'Ukwezi n\'irenze';
        default: return s;
      }
    }
    switch (s) {
      case 'TODAY': return 'Today';
      case 'FEW_DAYS': return 'Few days (2-3)';
      case 'WEEK': return 'About a week';
      case 'TWO_WEEKS': return 'Two weeks';
      case 'MONTH': return 'About a month';
      case 'LONGER': return 'Longer than a month';
      default: return s;
    }
  }

  Future<void> _submit() async {
    if (_sex == null || _severity == null || _duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.pleaseCompleteSelections)),
      );
      return;
    }
    if (_symptomsCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.pleaseDescribeSymptoms)),
      );
      return;
    }

    final intake = context.read<IntakeProvider>();
    final success = await intake.createIntake(
      sex: _sex!,
      severity: _severity!,
      duration: _duration!,
      symptomsDescription: _symptomsCtl.text.trim(),
    );

    if (success && mounted && intake.currentIntake != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AiSummaryScreen(intake: intake.currentIntake!),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.medicalIntake),
        actions: [
          LanguageToggle(
            currentLanguage: _lang,
            onChanged: (lang) {
              setState(() {
                _lang = lang;
                LocalizationService.setLocale(lang);
              });
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChoiceChipGroup(
                label: LocalizationService.selectSex,
                options: _sexOptions.map((e) => _translateSex(e)).toList(),
                selected: _sex != null ? _translateSex(_sex!) : null,
                onSelected: (v) {
                  setState(() {
                    _sex = _sexOptions[_sexOptions.indexWhere(
                      (o) => _translateSex(o) == v)];
                  });
                },
              ),
              const SizedBox(height: 24),
              ChoiceChipGroup(
                label: LocalizationService.selectSeverity,
                options: _severityOptions.map((e) => _translateSeverity(e)).toList(),
                selected: _severity != null ? _translateSeverity(_severity!) : null,
                onSelected: (v) {
                  setState(() {
                    _severity = _severityOptions[_severityOptions.indexWhere(
                      (o) => _translateSeverity(o) == v)];
                  });
                },
              ),
              const SizedBox(height: 24),
              ChoiceChipGroup(
                label: LocalizationService.selectDuration,
                options: _durationOptions.map((e) => _translateDuration(e)).toList(),
                selected: _duration != null ? _translateDuration(_duration!) : null,
                onSelected: (v) {
                  setState(() {
                    _duration = _durationOptions[_durationOptions.indexWhere(
                      (o) => _translateDuration(o) == v)];
                  });
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _symptomsCtl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: LocalizationService.symptomsDescription,
                  alignLabelWithHint: true,
                  hintText: LocalizationService.translate(en: 'e.g., Headache, fever, body aches...', rw: 'Urugero: Umutwe, umuriro, kubabara umubiri...'),
                ),
              ),
              const SizedBox(height: 32),
              Consumer<IntakeProvider>(
                builder: (_, intake, __) => LoadingButton(
                  loading: intake.loading,
                  label: LocalizationService.submitIntake,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
