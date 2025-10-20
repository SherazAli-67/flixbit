import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';
import '../res/spacing_constant.dart';
import 'loading_widget.dart';

class PrimaryBtn extends StatelessWidget {
  const PrimaryBtn({
    super.key,
    required String btnText,  String? icon, required VoidCallback onTap, bool isPrefix = false, bool isLoading = false, double borderRadius = SpacingConstants
        .btnBorderRadius, Color? iconColor,
    TextStyle textStyle = AppTextStyles.buttonTextStyle,
    Color bgColor = AppColors.primaryColor,
    Color? borderColor,
  })
      : _text = btnText,
        _icon = icon ?? '',
        _onTap = onTap,
        _isPrefix = isPrefix,
        _isLoading = isLoading,
        _borderRadius = borderRadius,
        _iconColor = iconColor,
        _textStyle = textStyle,
  _bgColor = bgColor,
  _borderColor = borderColor

  ;
  final String _text;
  final String _icon;
  final VoidCallback _onTap;
  final bool _isPrefix;
  final bool _isLoading;
  final double _borderRadius;
  final Color? _iconColor;
  final TextStyle _textStyle;
  final Color _bgColor;
  final Color? _borderColor;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _bgColor,
          // gradient: AppGradients.btnOuterGradient,
         /* boxShadow: [
            BoxShadow(
                color: Color.fromRGBO(201, 186, 255, 1),
                blurRadius: 17.6,
                offset: Offset(0, 6)
            )
          ],*/
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        // padding: EdgeInsets.all(2),
        child: Container(
          width: double.infinity,
          height: SpacingConstants.buttonHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_borderRadius),
            border: _borderColor != null ? Border.all(color: _borderColor) : null
          ),
          child: _isLoading ? LoadingWidget() : Row(
            spacing: _icon.isNotEmpty ? 10 : 0,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if(_isPrefix && _icon.isNotEmpty)
                SvgPicture.asset(_icon, colorFilter: _iconColor != null ? ColorFilter.mode(_iconColor, BlendMode.srcIn) :null,),
              Text(_text, style: _textStyle.copyWith(color: Colors.white),),
              if(!_isPrefix && _icon.isNotEmpty)
                SvgPicture.asset(_icon, colorFilter: _iconColor != null ? ColorFilter.mode(_iconColor, BlendMode.srcIn) :null,)
            ],
          ),
        ),
      ),
    );
  }
}