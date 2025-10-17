import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flixbit/src/models/seller_model.dart';
import 'package:flixbit/src/providers/profile_provider.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/app_icons.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/service/seller_service.dart';
import 'package:flixbit/src/widgets/apptextfield_widget.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SellerRegistrationPage extends StatefulWidget{
  const SellerRegistrationPage({super.key});

  @override
  State<SellerRegistrationPage> createState() => _SellerRegistrationPageState();
}

class _SellerRegistrationPageState extends State<SellerRegistrationPage> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailAddressController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _businessDescription = TextEditingController();

  String? _coverImage;

  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text("Seller Registration", style: AppTextStyles.headingTextStyle3,),
      ),
      body: SafeArea(child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 25),
        child: Column(
          spacing: 20,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryColor),
                  color: AppColors.primaryColor.withValues(alpha: 0.12)
                ),
                child: _coverImage != null ? Image.file(File(_coverImage!)) : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Icon(Icons.cloud_upload_outlined,size: 45, color: AppColors.primaryColor,),
                    Text("Click to upload", style: AppTextStyles.tileTitleTextStyle.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryColor),)
                  ],
                ),
              ),
            ),
            AppTextField(textController: _businessNameController, prefixIcon: '', hintText: 'Business Name', titleText: ''),
            AppTextField(textController: _contactNumberController, prefixIcon: '', hintText: 'Contact Number', titleText: '', textInputType: TextInputType.number,),
            AppTextField(textController: _emailAddressController, prefixIcon: '', hintText: 'Email Address', titleText: '', textInputType: TextInputType.emailAddress,),
            AppTextField(textController: _businessAddressController, prefixIcon: '', hintText: 'Business Address', titleText: ''),
            AppTextField(textController: _businessDescription, prefixIcon: '', hintText: 'Business Description', titleText: '', maxLines: 5,),

            PrimaryBtn(btnText: "Register", icon: '', onTap: _onRegisterTap, isLoading: _isLoading,)
          ],
        ),
      )),
    );
  }

  Future<void> _onRegisterTap() async {
    String userID = FirebaseAuth.instance.currentUser!.uid;
    String businessName = _businessNameController.text.trim();
    String emailAddress = _emailAddressController.text.trim();
    String contactNumber = _contactNumberController.text.trim();
    String businessAddress = _businessAddressController.text.trim();
    String businessDescription = _businessDescription.text.trim();
    DateTime createdAt = DateTime.now();
    setState(()=>  _isLoading = true);
    Seller seller = Seller(id: userID, name: businessName, category: '', isVerified: false, isActive: false, createdAt: createdAt, description: businessDescription, email: emailAddress, phone: contactNumber, location: businessAddress, coverImageUrl: AppIcons.icDummyImgUrl);
    final result = await SellerService.createSellerAccount(seller: seller);
    setState(()=>  _isLoading = false);
    if(result){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created successfully!'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
      _updateProfileWithSellerAccount();
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not create your account, Try again!'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if(file != null){
      setState(()=> _coverImage = file.path);
    }
  }

  void _updateProfileWithSellerAccount() {
    context.read<ProfileProvider>().initSellerInfo();
    Navigator.of(context).pop();
  }
}