import 'package:flutter/material.dart';

/// Brand & semantic colors. The surface/background/text/border colors adapt to
/// the active [mode] (light/dark) so the whole app supports dark mode without
/// threading Theme through every widget.
class AppColors {
  /// Set by the app root from the effective theme brightness.
  static Brightness mode = Brightness.light;
  static bool get _d => mode == Brightness.dark;

  // ---- Brand & semantic (constant across themes) ----
  // AzBerry logo orange (matches admin dashboard `brand`/`primary`).
  static const brand = Color(0xFFE4531C);
  static const brandLight = Color(0xFFF26430);
  static const brandDark = Color(0xFFBC4116);
  static const amber = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);

  // Canonical order-status palette — MUST stay in sync with the admin
  // dashboard (admin-dashboard/src/lib/constants.ts › ORDER_STATUS_COLOR).
  // pending=amber · confirmed=blue · preparing=indigo · ready=purple ·
  // on_the_way=cyan · delivered=green · cancelled=red.
  static const statusPending = Color(0xFFF59E0B);
  static const statusConfirmed = Color(0xFF2563EB);
  static const statusPreparing = Color(0xFF6366F1);
  static const statusReady = Color(0xFF9333EA);
  static const statusOnWay = Color(0xFF06B6D4);
  static const statusDelivered = Color(0xFF16A34A);
  static const statusCancelled = Color(0xFFDC2626);

  // ---- Theme-varying (light / dark) ----
  static Color get bg => _d ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);
  static Color get surface => _d ? const Color(0xFF1A2436) : Colors.white;
  static Color get textDark => _d ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  static Color get textMuted => _d ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color get border => _d ? const Color(0xFF2A3750) : const Color(0xFFE2E8F0);
  static Color get brandSurface => _d ? const Color(0xFF3A2113) : const Color(0xFFFFF4ED);
}
