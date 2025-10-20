import 'package:flutter/material.dart';

import '../res/app_colors.dart';
import '../res/apptextstyles.dart';

class DatePickerWidget extends StatelessWidget{
  const DatePickerWidget({
    super.key, required DateTime validFrom, required Function(DateTime datePicked) onValidFromDatePicked, required DateTime validUntil, required Function(DateTime datePicked) onValidUntilDatePicked,})
      : _validFrom = validFrom,
        _onValidFromPicked = onValidFromDatePicked,
        _validUntil = validUntil,
        _onValidUntilPicked = onValidUntilDatePicked;
  final DateTime _validFrom;
  final Function(DateTime datePicked) _onValidFromPicked;
  final DateTime _validUntil;
  final Function(DateTime datePicked) _onValidUntilPicked;


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDatePickerField(
          label: 'Valid From',
          date: _validFrom,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _validFrom,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primaryColor,
                      surface: AppColors.cardBgColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              _onValidFromPicked(picked);
            }
          },
        ),
        const SizedBox(height: 16),
        _buildDatePickerField(
          label: 'Valid Until',
          date: _validUntil,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _validUntil,
              firstDate: _validFrom,
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primaryColor,
                      surface: AppColors.cardBgColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              _onValidUntilPicked(picked);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(label, style: AppTextStyles.bodyTextStyle.copyWith(fontWeight: FontWeight.w600,),),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primaryColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: AppTextStyles.bodyTextStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}