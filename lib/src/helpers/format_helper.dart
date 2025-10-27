import 'package:intl/intl.dart';

class FormattingHelper {
  static String getFormattedAmount({required double amount}){
    return NumberFormat('#,##0').format(amount);
  }

  static String getFormattedDate({required DateTime timestamp}){
    return DateFormat('MMM dd, yyyy HH:mm').format(timestamp);
  }
}