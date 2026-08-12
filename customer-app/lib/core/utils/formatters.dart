import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../i18n.dart';

String money(num? value, {String? currency}) {
  final n = value ?? 0;
  final f = NumberFormat.decimalPattern('en');
  final cur = currency ?? (AppLocale.isEn ? 'IQD' : AppConfig.currency);
  return '${f.format(n)} $cur';
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (AppLocale.isEn) {
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
  return 'منذ ${diff.inDays} يوم';
}
