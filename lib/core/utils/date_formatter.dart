import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  static String formatDate(dynamic date) {
    final parsed = _parseDateTime(date);
    if (parsed == null) return '—';
    return _dateFormat.format(parsed);
  }

  static String formatTime(dynamic date) {
    final parsed = _parseDateTime(date);
    if (parsed == null) return '—';
    return _timeFormat.format(parsed);
  }

  static String formatDateTime(dynamic date) {
    final parsed = _parseDateTime(date);
    if (parsed == null) return '—';
    return _dateTimeFormat.format(parsed);
  }

  static String formatRelative(dynamic date) {
    final parsed = _parseDateTime(date);
    if (parsed == null) return '—';

    final now = DateTime.now();
    final difference = now.difference(parsed);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return _dateFormat.format(parsed);
    }
  }

  static DateTime? _parseDateTime(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date is String) {
      try {
        return DateTime.parse(date).toLocal();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
