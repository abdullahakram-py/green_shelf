import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'date_helpers.dart';

enum ExpiryStatus {
  expired,
  today,
  soon,
  fresh,
}

class ExpiryInfo {
  final ExpiryStatus status;
  final int daysDifference;
  final String label;
  final Color badgeColor;
  final Color textColor;
  final IconData icon;

  const ExpiryInfo({
    required this.status,
    required this.daysDifference,
    required this.label,
    required this.badgeColor,
    required this.textColor,
    required this.icon,
  });
}

class ExpiryCalculator {
  ExpiryCalculator._();

  /// Calculate ExpiryStatus as specified in TRD Section 2.5
  static ExpiryStatus statusFor(DateTime expiry, DateTime now, int soonDays) {
    final today = DateHelpers.stripTime(now);
    final exp = DateHelpers.stripTime(expiry);
    final days = exp.difference(today).inDays;

    if (days < 0) return ExpiryStatus.expired;
    if (days == 0) return ExpiryStatus.today;
    if (days <= soonDays) return ExpiryStatus.soon;
    return ExpiryStatus.fresh;
  }

  /// Formatted expiry label matching the exact UI design badges
  /// Examples: "Expired", "Today", "Tomorrow", "2 days", "5 days", "3 weeks", "8 months"
  static String formatExpiryLabel(DateTime expiry, DateTime now) {
    final today = DateHelpers.stripTime(now);
    final exp = DateHelpers.stripTime(expiry);
    final days = exp.difference(today).inDays;

    if (days < 0) {
      if (days == -1) return 'Expired yesterday';
      return 'Expired';
    }
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days < 7) return '$days days';
    if (days < 30) {
      final weeks = (days / 7).round();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'}';
    }
    final months = (days / 30.4).round();
    if (months < 12) {
      return '$months ${months == 1 ? 'month' : 'months'}';
    }
    final years = (days / 365).round();
    return '$years ${years == 1 ? 'year' : 'years'}';
  }

  /// Get comprehensive visual metadata for an item's expiry date
  static ExpiryInfo getExpiryInfo(DateTime expiry, {DateTime? now, int soonDays = 3}) {
    final current = now ?? DateTime.now();
    final status = statusFor(expiry, current, soonDays);
    final days = DateHelpers.stripTime(expiry).difference(DateHelpers.stripTime(current)).inDays;
    final label = formatExpiryLabel(expiry, current);

    switch (status) {
      case ExpiryStatus.expired:
        return ExpiryInfo(
          status: status,
          daysDifference: days,
          label: label,
          badgeColor: AppColors.statusExpiredBg,
          textColor: AppColors.statusExpired,
          icon: Icons.error_outline_rounded,
        );
      case ExpiryStatus.today:
        return ExpiryInfo(
          status: status,
          daysDifference: days,
          label: label,
          badgeColor: AppColors.statusTodayBg,
          textColor: AppColors.statusToday,
          icon: Icons.warning_amber_rounded,
        );
      case ExpiryStatus.soon:
        return ExpiryInfo(
          status: status,
          daysDifference: days,
          label: label,
          badgeColor: AppColors.statusSoonBg,
          textColor: const Color(0xFFB45309), // readable deep amber
          icon: Icons.schedule_rounded,
        );
      case ExpiryStatus.fresh:
        // Use soft sage/neutral for longer shelf-lives
        if (days > 14) {
          return ExpiryInfo(
            status: status,
            daysDifference: days,
            label: label,
            badgeColor: AppColors.statusNeutralBg,
            textColor: AppColors.statusNeutral,
            icon: Icons.check_circle_outline_rounded,
          );
        }
        return ExpiryInfo(
          status: status,
          daysDifference: days,
          label: label,
          badgeColor: AppColors.statusFreshBg,
          textColor: AppColors.statusFresh,
          icon: Icons.check_circle_outline_rounded,
        );
    }
  }
}
