import 'package:flixbit/src/providers/authentication_provider.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flixbit/src/widgets/apptextfield_widget.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../res/app_icons.dart';

class LoginPage extends StatefulWidget{
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(
        spacing: 20,
        children: [
          Image.asset(AppIcons.signInHeaderImg),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              spacing: 10,
              children: [
                AppTextField(textController: _emailController, prefixIcon: AppIcons.icEmail, hintText: 'Enter your email', titleText: 'Email address'),
                AppTextField(textController: _passwordController, prefixIcon: AppIcons.icPassword, hintText: 'Enter your password', titleText: 'Password'),
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(onPressed: (){}, child: Text("Forget Password?")),
                ),
                const SizedBox(height: 20,),
                Consumer<AuthenticationProvider>(
                  builder: (context, authProvider, child) {
                    return PrimaryBtn(
                      btnText: authProvider.isLoading ? 'Signing In...' : 'Login',
                      icon: '',
                      onTap: authProvider.isLoading ? () {} : () => _onLoginTap(),
                    );
                  },
                ),
                RichText(

                    text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Don't have an account? ",
                      style: AppTextStyles.smallTextStyle
                    ),
                    TextSpan(
                      recognizer: TapGestureRecognizer()..onTap = (){
                        context.push(RouterEnum.signupView.routeName);
                      },
                        text: "Create Here",
                        style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.primaryColor)
                    )
                  ]
                ))
              ],
            ),
          )
        ],
      )),
    );
  }

  Future<void> _onLoginTap() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty) {
      String errorMessage = '';
      if (email.isEmpty) {
        errorMessage = 'Please enter your email address';
      } else if (password.isEmpty) {
        errorMessage = 'Please enter your password';
      }
      
      _showSnackBar(errorMessage, isError: true);
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('Please enter a valid email address', isError: true);
      return;
    }

    // Get authentication provider
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    
    // Attempt to sign in
    final success = await authProvider.signInWithEmail(
      email: email,
      password: password,
    );

    if (success) {
      _showSnackBar('Signed in successfully!', isError: false);
      // Navigate to home page
      if (mounted) {
        context.go(RouterEnum.homeView.routeName);
      }
    } else {
      _showSnackBar(authProvider.errorMessage ?? 'Failed to sign in', isError: true);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}