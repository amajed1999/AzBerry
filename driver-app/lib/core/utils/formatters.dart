import 'package:intl/intl.dart';
import '../config/app_config.dart';

String money(num? v) {
  final n = v ?? 0;
  return '${NumberFormat.decimalPattern('en').format(n)} ${AppConfig.currency}';
}

String timeAgo(DateTime dt) {
  final d = DateTime.now().difference(dt);
  if (d.inMinutes < 1) return 'الآن';
  if (d.inMinutes < 60) return 'منذ ${d.inMinutes} د';
  if (d.inHours < 24) return 'منذ ${d.inHours} س';
  return 'منذ ${d.inDays} يوم';
}
