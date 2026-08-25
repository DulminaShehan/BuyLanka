import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _compactFormatter = NumberFormat('#,##0', 'en_US');

  /// Formats numeric amount into Sri Lankan Rupee representation (e.g. "Rs. 1,250.00")
  static String format(num? amount) {
    if (amount == null) return 'Rs. 0.00';
    return 'Rs. ${_formatter.format(amount)}';
  }

  /// Compact formatting without decimals (e.g. "Rs. 1,250")
  static String formatCompact(num? amount) {
    if (amount == null) return 'Rs. 0';
    return 'Rs. ${_compactFormatter.format(amount)}';
  }

  /// Convenience alias for formatCompact (e.g. "Rs. 2,450")
  static String formatLKR(num? amount) {
    return formatCompact(amount);
  }
}
