import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';

/// A money value rendered with an optional explicit sign and theme color.
class AmountText extends StatelessWidget {
  const AmountText({
    required this.value,
    this.symbol = 'Rs.',
    this.color,
    this.showSign = false,
    this.style,
    super.key,
  });

  final double value;
  final String symbol;
  final Color? color;
  final bool showSign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.titleMedium!;
    final text = showSign
        ? moneySigned(value, symbol: symbol)
        : money(value, symbol: symbol);
    return Text(text, style: base.copyWith(color: color));
  }
}
