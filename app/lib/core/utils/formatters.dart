import 'package:intl/intl.dart';

/// Formats an amount as money, e.g. `Rs. 1,250.5`.
///
/// The rupee symbol is passed in so it can follow the current locale
/// (`Rs.` for English, `रू` for Nepali).
String money(double value, {String symbol = 'Rs.'}) {
  final nf = NumberFormat('#,##0.##');
  final sign = value < 0 ? '-' : '';
  return '$sign$symbol ${nf.format(value.abs())}';
}

/// Same as [money] but always shows an explicit `+` or `-`.
String moneySigned(double value, {String symbol = 'Rs.'}) {
  final prefix = value < 0 ? '-' : '+';
  return '$prefix ${money(value.abs(), symbol: symbol)}';
}

/// Compact number for chart labels (e.g. `1.2k`, `3.4M`).
String compactMoney(double value, {String symbol = 'Rs.'}) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 10000000) return '$sign$symbol ${(abs / 10000000).toStringAsFixed(1)}Cr';
  if (abs >= 100000) return '$sign$symbol ${(abs / 100000).toStringAsFixed(1)}L';
  if (abs >= 1000) return '$sign$symbol ${(abs / 1000).toStringAsFixed(1)}k';
  return '$sign$symbol ${abs.toStringAsFixed(0)}';
}

/// First letter(s) used for avatar placeholders.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  String first(String s) => s.isEmpty ? '' : s.substring(0, 1).toUpperCase();
  if (parts.length == 1) return first(parts.first);
  return '${first(parts.first)}${first(parts.last)}';
}
