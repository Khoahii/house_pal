import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Loại bỏ tất cả ký tự không phải số
    String chars = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (chars.isEmpty) return newValue.copyWith(text: '');

    double value = double.parse(chars);
    final formatter = NumberFormat.decimalPattern('vi_VN');
    String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
