import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class QuantityStepper extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final double max;
  final String? unit;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 1.0,
    this.min = 0.1,
    this.max = 9999.0,
    this.unit,
  });

  String _formatValue(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2ED),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 20, color: AppColors.textPrimary),
            onPressed: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
            splashRadius: 20,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              unit != null ? '${_formatValue(value)} $unit' : _formatValue(value),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20, color: AppColors.primaryDark),
            onPressed: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
            splashRadius: 20,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
