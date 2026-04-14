// lib/widgets/input_field.dart
// Reusable styled input widgets for the health data form

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Numeric Input Field ──────────────────────────────────────────────────────
/// A styled text field that accepts only numeric input
class NumericInputField extends StatelessWidget {
  final String label;
  final String hint;
  final String? unit;
  final TextEditingController controller;
  final bool allowDecimal;
  final String? Function(String?)? validator;

  const NumericInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.unit,
    this.allowDecimal = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        // Allow digits and optionally decimal points
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'[\d.]') : RegExp(r'\d'),
        ),
      ],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: unit,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
/// A section title widget used to group form fields visually
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Risk Badge ───────────────────────────────────────────────────────────────
/// Colored badge showing risk category (Low / Medium / High)
class RiskBadge extends StatelessWidget {
  final String prediction;

  const RiskBadge({super.key, required this.prediction});

  Color _getColor(BuildContext context) {
    if (prediction.toLowerCase().contains('high')) return const Color(0xFFE53935);
    if (prediction.toLowerCase().contains('medium')) return const Color(0xFFFB8C00);
    return const Color(0xFF43A047);
  }

  IconData _getIcon() {
    if (prediction.toLowerCase().contains('high')) return Icons.warning_rounded;
    if (prediction.toLowerCase().contains('medium')) return Icons.info_rounded;
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            prediction,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
