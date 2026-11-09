import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_app/core/utils/formatters.dart';

void main() {
  group('money', () {
    test('formats whole numbers with grouping', () {
      expect(money(1234567), 'Rs. 1,234,567');
    });

    test('keeps up to two decimals and drops trailing zeros', () {
      expect(money(1250.5), 'Rs. 1,250.5');
      expect(money(10.25), 'Rs. 10.25');
      expect(money(10.00), 'Rs. 10');
    });

    test('moves the sign before the symbol', () {
      expect(money(-42), '-Rs. 42');
    });

    test('honours a custom currency symbol', () {
      expect(money(500, symbol: 'रू'), 'रू 500');
    });
  });

  group('moneySigned', () {
    test('always shows a sign', () {
      expect(moneySigned(5), '+ Rs. 5');
      expect(moneySigned(-5), '- Rs. 5');
    });
  });

  group('initialsOf', () {
    test('uses first letters of first and last name', () {
      expect(initialsOf('Ram Bahadur'), 'RB');
      expect(initialsOf('Sita'), 'S');
      expect(initialsOf('  '), '?');
    });
  });
}
