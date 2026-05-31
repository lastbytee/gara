import 'package:flutter/material.dart';
import '../config/theme.dart';

class LanguageToggle extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String> onChanged;

  const LanguageToggle({
    super.key,
    required this.currentLanguage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GaraTheme.primaryBlue.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangButton('en', 'EN'),
          const SizedBox(width: 0),
          _buildLangButton('rw', 'RW'),
        ],
      ),
    );
  }

  Widget _buildLangButton(String lang, String label) {
    final isSelected = currentLanguage == lang;
    return GestureDetector(
      onTap: () => onChanged(lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GaraTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : GaraTheme.primaryBlue,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
