import 'package:flutter/material.dart';
import '../theme/pastel_theme.dart';

enum VintageAlertVariant { info, success, warning, error }

/// A vintage pastel floating alert toast for bottom notifications and errors
void showVintageAlert(
  BuildContext context, {
  required String message,
  VintageAlertVariant variant = VintageAlertVariant.info,
  IconData? icon,
  Duration duration = const Duration(milliseconds: 2500),
}) {
  Color accentColor;
  IconData defaultIcon;

  switch (variant) {
    case VintageAlertVariant.success:
      accentColor = PastelColors.mint;
      defaultIcon = Icons.check_circle_rounded;
      break;
    case VintageAlertVariant.warning:
      accentColor = PastelColors.butter;
      defaultIcon = Icons.warning_amber_rounded;
      break;
    case VintageAlertVariant.error:
      accentColor = PastelColors.pinkDeep;
      defaultIcon = Icons.error_outline_rounded;
      break;
    case VintageAlertVariant.info:
      accentColor = PastelColors.lavender;
      defaultIcon = Icons.info_outline_rounded;
      break;
  }

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: PastelColors.surfaceDark.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon ?? defaultIcon, size: 16, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: PastelColors.textLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
