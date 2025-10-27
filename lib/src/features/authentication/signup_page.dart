import 'dart:io';

import 'package:flixbit/src/providers/authentication_provider.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flixbit/src/service/deep_link_service.dart';
import 'package:flixbit/src/widgets/apptextfield_widget.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../res/app_constants.dart';
import '../../res/app_icons.dart';
import '../../res/spacing_constant.dart';
import '../../../l10n/app_localizations.dart';

class SignupPage extends StatefulWidget{
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();
  File? _imageFile;
  bool _referralCodeFromDeepLink = false;

  @override
  void initState() {
    super.initState();
    _loadPendingReferralCode();
  }

  /// Load pending referral code from deep link
  Future<void> _loadPendingReferralCode() async {
    final deepLinkService = DeepLinkService();
    final pendingCode = await deepLinkService.getPendingReferralCode();
    
    if (pendingCode != null && pendingCode.isNotEmpty) {
      setState(() {
        _referralCodeController.text = pendingCode;
        _referralCodeFromDeepLink = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signup, style: AppTextStyles.headingTextStyle3,),
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
                              onTap: _pickImage,
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
                    prefixIcon: AppIcons.icUser,
                    hintText: "i.e John Doe",
                    titleText: l10n.name),

                AppTextField(textController: _emailController,
                    prefixIcon: AppIcons.icEmail,
                    textInputType: TextInputType.emailAddress,
                    hintText: "iejohndoe@gmail.com",
                    titleText: l10n.email),

                AppTextField(textController: _passwordController,
                  prefixIcon: AppIcons.icPassword,
                  hintText: "**************",
                  titleText: l10n.password, isPassword: true,),

                // Referral Code Field (Optional)
                AppTextField(
                  textController: _referralCodeController,
                  prefixIcon: AppIcons.icUser,
                  hintText: "Enter referral code",
                  titleText: "Referral Code (Optional)",
                  suffixIcon: _referralCodeFromDeepLink 
                    ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                    : null,
                  isReadOnly: _referralCodeFromDeepLink,
                ),
                
                if (_referralCodeFromDeepLink)
                  Row(
                    children: [
                      Icon(Icons.link, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Have a referral code? Enter it here",
                          style: AppTextStyles.captionTextStyle.copyWith(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                RichText(text: TextSpan(
                    children: [
                      TextSpan(text: '*By tapping ', style: AppTextStyles.bodyTextStyle.copyWith(color: Colors.white, fontWeight: FontWeight.w400, fontFamily: AppConstants.appFontFamily)),
                      TextSpan(text: '‘Create Account’, ', style: AppTextStyles.bodyTextStyle.copyWith(color: AppColors.primaryColor, fontWeight: FontWeight.w400, fontFamily: AppConstants.appFontFamily)),
                      TextSpan(text: 'you’re cool with our Terms & Privacy. 💯*', style: AppTextStyles.bodyTextStyle.copyWith(color: Colors.white, fontWeight: FontWeight.w400, fontFamily: AppConstants.appFontFamily))
                    ]
                )),
                const SizedBox(height: 30,),
                Consumer<AuthenticationProvider>(
                  builder: (context, authProvider, child) {
                    return PrimaryBtn(
                      btnText: authProvider.isLoading ? l10n.loading : l10n.signup,
                      icon: '',
                      isLoading: authProvider.isLoading,
                      onTap: authProvider.isLoading ? () {} : () => _onSignupTap(),
                    );
                  },
                ),
                RichText(text: TextSpan(
                    children: [
                      TextSpan(text: "${l10n.alreadyHaveAccount} ", style: AppTextStyles.bodyTextStyle.copyWith(color: Colors.white, fontFamily: AppConstants.appFontFamily)),
                      TextSpan(
                          recognizer: TapGestureRecognizer()..onTap = (){
                            context.pushReplacement(RouterEnum.loginView.routeName);
                          },
                          text: l10n.login, style: AppTextStyles.bodyTextStyle.copyWith(color: AppColors.primaryColor, fontFamily: AppConstants.appFontFamily)),

                    ]
                ))
              ],
            ),
          ],
        ),
      ),),
    );
  }

  Future<void> _onSignupTap() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String name = _nameController.text.trim();
    String? referralCode = _referralCodeController.text.trim();
    if (referralCode.isEmpty) {
      referralCode = null;
    }

    // Validation
    if (email.isEmpty || password.isEmpty || name.isEmpty || _imageFile == null) {
      String errorMessage = '';
      if (_imageFile == null) {
        errorMessage = 'Please upload a profile image';
      } else if (name.isEmpty) {
        errorMessage = 'Please enter your full name';
      } else if (email.isEmpty) {
        errorMessage = 'Please enter your email address';
      } else if (password.isEmpty) {
        errorMessage = 'Please enter a password';
      }
      
      _showSnackBar(errorMessage, isError: true);
      return;
    }

    // Additional validation
    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters long', isError: true);
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('Please enter a valid email address', isError: true);
      return;
    }

    // Validate referral code format if provided
    if (referralCode != null && referralCode.isNotEmpty) {
      final deepLinkService = DeepLinkService();
      if (!deepLinkService.isValidReferralCodeFormat(referralCode.toUpperCase())) {
        _showSnackBar('Invalid referral code format', isError: true);
        return;
      }
    }

    // Get authentication provider
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    
    // Attempt to create account
    final success = await authProvider.signUpWithEmail(
      email: email,
      password: password,
      name: name,
      profileImage: _imageFile,
      referralCode: referralCode,
    );

    if (success) {
      _showSnackBar('Account created successfully!', isError: false);
      
      // Clear pending referral code after successful signup
      if (referralCode != null) {
        await DeepLinkService().clearPendingReferralCode();
      }
      
      // Navigate to home page
      if (mounted) {
        context.go(RouterEnum.homeView.routeName);
      }
    } else {
      _showSnackBar(authProvider.errorMessage ?? 'Failed to create account', isError: true);
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

  Future<void> _pickImage() async {
    final XFile? image =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      _imageFile = File(image.path);
      setState(() {});
    }
  }
}