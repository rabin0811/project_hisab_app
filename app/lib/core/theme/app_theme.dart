import 'package:flutter/material.dart';

/// Semantic color tokens used across the app.
///
/// Widgets must never hardcode a [Color]; they read these tokens from the
/// theme instead, so everything adapts to light/dark and to a custom accent.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.income,
    required this.expense,
    required this.profit,
    required this.positive,
    required this.negative,
    required this.neutral,
    required this.bank,
    required this.wallet,
    required this.cash,
  });

  /// Money in that is not profit (salary, sales, ...).
  final Color income;

  /// Money out.
  final Color expense;

  /// Booked profit.
  final Color profit;

  /// Positive balance — someone owes me.
  final Color positive;

  /// Negative balance — I owe someone.
  final Color negative;

  /// Neither positive nor negative (settled / secondary text).
  final Color neutral;

  /// Account-type accents.
  final Color bank;
  final Color wallet;
  final Color cash;

  static const light = AppColors(
    income: Color(0xFF1B873F),
    expense: Color(0xFFC0362C),
    profit: Color(0xFF0E7490),
    positive: Color(0xFF1B873F),
    negative: Color(0xFFC0362C),
    neutral: Color(0xFF5F6368),
    bank: Color(0xFF3949AB),
    wallet: Color(0xFF7B1FA2),
    cash: Color(0xFF1B873F),
  );

  static const dark = AppColors(
    income: Color(0xFF5DD39E),
    expense: Color(0xFFFF8A80),
    profit: Color(0xFF67E8F9),
    positive: Color(0xFF5DD39E),
    negative: Color(0xFFFF8A80),
    neutral: Color(0xFFB0B4BA),
    bank: Color(0xFF9FA8DA),
    wallet: Color(0xFFCE93D8),
    cash: Color(0xFF5DD39E),
  );

  @override
  AppColors copyWith({
    Color? income,
    Color? expense,
    Color? profit,
    Color? positive,
    Color? negative,
    Color? neutral,
    Color? bank,
    Color? wallet,
    Color? cash,
  }) {
    return AppColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      profit: profit ?? this.profit,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      neutral: neutral ?? this.neutral,
      bank: bank ?? this.bank,
      wallet: wallet ?? this.wallet,
      cash: cash ?? this.cash,
    );
  }

  @override
  AppColors lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      profit: Color.lerp(profit, other.profit, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      bank: Color.lerp(bank, other.bank, t)!,
      wallet: Color.lerp(wallet, other.wallet, t)!,
      cash: Color.lerp(cash, other.cash, t)!,
    );
  }
}

/// Selectable accent seeds offered in Settings. `null` value means "use the
/// app default seed".
const Map<String, Color> kAccentSeeds = {
  'Teal': Color(0xFF0F766E),
  'Indigo': Color(0xFF4338CA),
  'Blue': Color(0xFF2563EB),
  'Green': Color(0xFF15803D),
  'Orange': Color(0xFFC2410C),
  'Pink': Color(0xFFBE185D),
  'Purple': Color(0xFF7E22CE),
  'Slate': Color(0xFF334155),
};

/// The default accent used when the user has not chosen one.
const Color kDefaultSeed = Color(0xFF0F766E);

/// Builds the light and dark [ThemeData] from a seed color.
class AppTheme {
  const AppTheme._();

  static ThemeData light({Color? seed}) =>
      _build(Brightness.light, seed ?? kDefaultSeed);

  static ThemeData dark({Color? seed}) =>
      _build(Brightness.dark, seed ?? kDefaultSeed);

  static ThemeData _build(Brightness brightness, Color seed) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: <ThemeExtension<dynamic>>[
        isDark ? AppColors.dark : AppColors.light,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
    );
  }
}

/// Convenient, terse access to theme values.
extension AppThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
