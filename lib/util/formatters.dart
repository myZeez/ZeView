import 'package:intl/intl.dart';

final _exactFormat = DateFormat('dd MMM yyyy, HH:mm:ss');
final _shortFormat = DateFormat('dd MMM, HH:mm');

/// Full precision timestamp — this is the app's core value: an exact
/// arrival time, unlike source apps (e.g. Gmail) that only show a date.
String formatExactDateTime(DateTime dt) => _exactFormat.format(dt);

String formatShortDateTime(DateTime dt) => _shortFormat.format(dt);

String formatRelative(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return formatShortDateTime(dt);
}
