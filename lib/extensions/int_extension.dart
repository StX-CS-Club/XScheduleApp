/// An extension on Dart's [int] type for display formatting.
///
/// Responsibilities:
/// - Formatting integers as zero-padded strings with a minimum width of 2 digits
extension IntegerExtension on int {
  /// Returns this integer as a string, zero-padded to at least 2 digits.
  ///
  /// Values with 2 or more digits are returned as-is; single-digit values
  /// are prefixed with `'0'` (e.g. `5` → `'05'`, `12` → `'12'`).
  ///
  /// Returns: A [String] of at least 2 characters
  String multiDecimal() {
    // Single-digit values (string length of 1) need a leading zero
    if (toString().length > 1) {
      return toString();
    }
    return '0$this';
  }
}