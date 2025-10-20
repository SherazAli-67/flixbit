import 'package:flutter/material.dart';

import '../res/app_colors.dart';
import '../res/apptextstyles.dart';

class AppTextFieldFilledWidget extends StatelessWidget{
  const AppTextFieldFilledWidget({super.key,
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }):
  _controller = controller,
  _label = label,
  _hint = hint,
  _maxLines = maxLines,
  _keyboardType = keyboardType,
  _validator = validator;

  final TextEditingController _controller;
  final String _label;
  final String _hint;
  final int _maxLines;
  final TextInputType? _keyboardType;
  final String? Function(String?)? _validator;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          _label,
          style: AppTextStyles.bodyTextStyle.copyWith( fontWeight: FontWeight.w600,),
        ),
        TextFormField(
          controller: _controller,
          maxLines: _maxLines,
          keyboardType: _keyboardType,
          style: AppTextStyles.bodyTextStyle,
          decoration: InputDecoration(
            hintText: _hint,
            hintStyle: AppTextStyles.bodyTextStyle.copyWith(color: AppColors.unSelectedGreyColor,),
            filled: true,
            fillColor: AppColors.cardBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: _validator,
        ),
      ],
    );
  }

}