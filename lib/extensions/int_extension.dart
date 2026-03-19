/*
  * int_extension.dart
  Provides basic methods for displaying integers.
 */

/// int extension <p>
/// Provides basic methods for displaying integers.
extension IntegerExtension on int {
  /// int extension <p>
  /// Returns the value displayed as a string with >= 2 decimals
  String multiDecimal(){
    if(toString().length > 1){
      return toString();
    }
    return '0$this';
  }
}