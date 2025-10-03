import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flixbit/src/widgets/apptextfield_widget.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                PrimaryBtn(btnText: 'Login', icon: '', onTap: (){}),
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
}