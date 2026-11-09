import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';

/// Helpers for showing Bikram Sambat (BS) and Gregorian (AD) dates together.
///
/// The BS calendar is not a fixed offset, so conversion is delegated to
/// `nepali_utils`.
class DualDate {
  DualDate(this.ad);

  final DateTime ad;

  NepaliDateTime get bs => ad.toNepaliDateTime();

  static DualDate today() {
    final now = DateTime.now();
    return DualDate(DateTime(now.year, now.month, now.day));
  }

  /// Removes the time component, keeping the local calendar day.
  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// e.g. `2083 Asoj 12` / `2083 असोज १२`.
  String bsLong(Language language) =>
      NepaliDateFormat('d MMMM y', language).format(bs);

  /// e.g. `Asoj 2083` / `असोज २०८३`.
  String bsMonthYear(Language language) =>
      NepaliDateFormat('MMMM y', language).format(bs);

  /// e.g. `12 Oct 2026`.
  String get adLong => DateFormat('d MMM y').format(ad);

  /// e.g. `October 2026`.
  String get adMonthYear => DateFormat('MMMM y').format(ad);

  /// e.g. `Mon, 12 Oct 2026`.
  String get adFull => DateFormat('EEE, d MMM y').format(ad);
}

/// Maps an app locale to the matching `nepali_utils` language.
Language languageForLocale(String languageCode) =>
    languageCode == 'ne' ? Language.nepali : Language.english;
