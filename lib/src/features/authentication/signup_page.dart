import 'dart:io';

import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flixbit/src/widgets/apptextfield_widget.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../res/app_constants.dart';
import '../../res/app_icons.dart';
import '../../res/spacing_constant.dart';

class SignupPage extends StatefulWidget{
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  File? _imageFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registration", style: AppTextStyles.headingTextStyle3,),
        centerTitle: false,
      ),
      body: SafeArea(child:   SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: SpacingConstants.screenHorizontalPadding, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 28,
          children: [
            Column(
              spacing: 16,
              children: [
                Center(
                  child: Stack(
                    children: [
                      _imageFile != null
                          ? CircleAvatar(
                        radius: 45,
                        backgroundImage: MemoryImage(_imageFile!.readAsBytesSync(),),
                      )
                          : CircleAvatar(
                          radius: 45,
                          backgroundColor: AppColors.primaryColor,
                          child: SvgPicture.asset(AppIcons.icUser, colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn))),
                      Positioned(
                          right: 0,
                          bottom: 2,
                          child: GestureDetector(
                              onTap: (){},
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
                                child: CircleAvatar(
                                  radius: 13,
                                  backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      AppIcons.icCamera,
                                      colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                      height: 15,
                                    ),
                                  ),
                                ),
                              )))
                    ],
                  ),
                ),
                AppTextField(textController: _nameController,
                    prefixIcon: AppIcons.icEmail,
                    hintText: "i.e John Doe",
                    titleText: "Full name"),

                AppTextField(textController: _emailController,
                    prefixIcon: AppIcons.icEmail,
                    textInputType: TextInputType.emailAddress,
                    hintText: "iejohndoe@gmail.com",
                    titleText: "Email/Username"),

                AppTextField(textController: _passwordController,
                  prefixIcon: AppIcons.icPassword,
                  hintText: "**************",
                  titleText: "Password", isPassword: true,),

                RichText(text: TextSpan(
                    children: [
                      TextSpan(text: '*By tapping ', style: AppTextStyles.bodyTextStyle.copyWith(color: Colors.white, fontWeight: FontWeight.w400, fontFamily: AppConstants.appFontFamily)),
                      TextSpan(text: '‘Create Account’, ', style: AppTextStyles.bodyTextStyle.copyWith(color: AppColors.primaryColor, fontWeight: FontWeight.w400, fontFamily: AppConstants.appFontFamily)),
                      TextSpan(text: 'you’re cool with our Terms & Privacy. 💯*', style: AppTextStyles.bodyTextStyle.copyWith(color: Colors.white, fontWeight: FontWeight.w400, fontFamily: AppConstants.appFontFamily))
                    ]
                )),
                const SizedBox(height: 30,),
                PrimaryBtn(btnText: 'Sign up', icon: '', onTap: (){
                  context.go(RouterEnum.homeView.routeName);
                }),
                RichText(text: TextSpan(
                    children: [
                      TextSpan(text: "Already have any account? ", style: AppTextStyles.bodyTextStyle.copyWith(color: Colors.white, fontFamily: AppConstants.appFontFamily)),
                      TextSpan(
                          recognizer: TapGestureRecognizer()..onTap = (){
                            context.pushReplacement(RouterEnum.loginView.routeName);
                          },
                          text: "Sign in!", style: AppTextStyles.bodyTextStyle.copyWith(color: AppColors.primaryColor, fontFamily: AppConstants.appFontFamily)),

                    ]
                ))
              ],
            ),
          ],
        ),
      ),),
    );
  }
}