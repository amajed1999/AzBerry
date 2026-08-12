import 'package:intl/intl.dart';
import '../config/app_config.dart';

String money(num? value, {String? currency}) {
  final n = value ?? 0;
  final f = NumberFormat.decimalPattern('en');
  return '${f.format(n)} ${currency ?? AppConfig.currency}';
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
  return 'منذ ${diff.inDays} يوم';
}
