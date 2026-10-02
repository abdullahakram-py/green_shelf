import 'package:flutter/material.dart';
import '../utils/expiry_calculator.dart';

class StatusBadge extends StatelessWidget {
  final DateTime expiryDate;
  final bool showIcon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.expiryDate,
    this.showIcon = false,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    final info = ExpiryCalculator.getExpiryInfo(expiryDate);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: info.badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(info.icon, size: fontSize + 2, color: info.textColor),
            const SizedBox(width: 4),
          ],
          Text(
            info.label,
            style: TextStyle(
              color: info.textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
