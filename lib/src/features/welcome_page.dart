import 'package:flutter/material.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

class WelcomePage extends StatelessWidget{
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Title
              Text(
                l10n.appTitle,
                style: AppTextStyles.headingTextStyle.copyWith(
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.welcome,
                style: AppTextStyles.headingTextStyle2,
              ),
              const SizedBox(height: 48),
              
              // Action Buttons
              Column(
                children: [
                  PrimaryBtn(
                    btnText: l10n.login,
                    icon: '',
                    onTap: () => context.push(RouterEnum.loginView.routeName),
                  ),
                  const SizedBox(height: 16),
                  PrimaryBtn(
                    btnText: l10n.signup,
                    icon: '',
                    onTap: () => context.push(RouterEnum.signupView.routeName),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}