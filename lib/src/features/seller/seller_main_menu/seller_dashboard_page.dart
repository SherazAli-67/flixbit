import 'package:cached_network_image/cached_network_image.dart';
import 'package:flixbit/src/features/seller/seller_registration_page.dart';
import 'package:flixbit/src/models/seller_model.dart';
import 'package:flixbit/src/providers/profile_provider.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/app_icons.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flixbit/src/service/qr_download_service.dart';
import 'package:flixbit/src/widgets/loading_widget.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../l10n/app_localizations.dart';

class SellerDashboardPage extends StatelessWidget{
  const SellerDashboardPage({super.key});


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    return provider.loading
        ? LoadingWidget()
        : provider.isRegisteredAsSeller
        ?  _buildSellerInfoWidget(context, provider.seller, l10n): _buildRegisterAsSellerWidget(context, l10n);
  }

  _buildRegisterAsSellerWidget(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 40,
          children: [
            Column(
              spacing: 15,
              children: [

                Text("404", style: AppTextStyles.headingTextStyle,),
                Text("Seller not found, Create Seller account first", style: AppTextStyles.smallTextStyle,),
              ],
            ),
            PrimaryBtn(btnText: "Register as Seller", icon: '', onTap: (){
              Navigator.of(context).push(MaterialPageRoute(builder: (_)=> SellerRegistrationPage()));
          /*    showModalBottomSheet(
                  backgroundColor: Colors.white,
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return FractionallySizedBox(
                      heightFactor: 0.82,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: SellerRegistrationPage(),
                      ),
                    );
                  });*/
            })
          ],
        ),
      ),
    );
  }

  _buildSellerInfoWidget(BuildContext context, Seller? seller, AppLocalizations l10n) {
    return seller != null ? Scaffold(

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            spacing: 20,
            children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(imageUrl: seller.coverImageUrl!, height: 200,)),
             Column(
               children: [
                 Text(seller.name, style: AppTextStyles.subHeadingTextStyle,),
                 Text(seller.email!, style: AppTextStyles.captionTextStyle,),
               ],
             ),
              
              Card(
                color: AppColors.cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    spacing: 10,
                    children: [
                      Text("Your Unique QR Code", style: AppTextStyles.tileTitleTextStyle,),
                      Text("Display this QR code at your business location for customers to scan, and receive special notification", style: AppTextStyles.captionTextStyle, textAlign: TextAlign.center,),

                      _buildQRImage(context, seller: seller),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryBtn(
                              btnText: "Download QR",
                              icon: '',
                              onTap: () => _downloadQRCode(context, seller),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PrimaryBtn(
                              btnText: "Share QR",
                              icon: '',
                              onTap: () => _shareQRCode(context, seller),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              
              // QR System Quick Actions
              Card(
                color: AppColors.cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    spacing: 10,
                    children: [
                      Text("QR System", style: AppTextStyles.tileTitleTextStyle,),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              context: context,
                              icon: Icons.people_outline,
                              label: "My Followers",
                              onTap: ()=> context.push(RouterEnum.sellerFollowersView.routeName),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildQuickActionButton(
                              context: context,
                              icon: Icons.analytics_outlined,
                              label: "QR Analytics",
                              onTap: ()=> context.push(RouterEnum.sellerQRCodeTrackingView.routeName),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Align(
                      alignment: Alignment.topLeft,
                      child: Text("Business Details", style: AppTextStyles.subHeadingTextStyle,)),
                  _buildSellerInfoItemWidget(title: 'Contact Number', value: seller.phone ?? ''),
                  
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(AppIcons.icLocationMap, fit: BoxFit.cover,),
                      ),
                      
                      Icon(Icons.location_pin, size: 45, color: Colors.white,)
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    ) : SizedBox();
  }

  Widget _buildSellerInfoItemWidget({required String title, required String value}) {
    return Card(
      color: AppColors.cardBgColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.tileTitleTextStyle,),
            Text(value, style: AppTextStyles.smallTextStyle,),
          ],
        ),
      ),
    );
  }

  Widget _buildQRImage(BuildContext context,{required Seller seller}) {
    // Generate QR code with correct format: flixbit:seller:{sellerId}
    final qrData = 'flixbit:seller:${seller.id}';
    return Card(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: SizedBox(
          height: 200,
          child: QrImageView(data: qrData),
        ),
      ),
    );
  }

  void _downloadQRCode(BuildContext context, Seller seller) async {
    final qrData = 'flixbit:seller:${seller.id}';
    final service = QRDownloadService();
    
    try {
      final path = await service.saveQRCodeToDevice(qrData, '${seller.name}_QR');
      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR code saved to: $path'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving QR code: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _shareQRCode(BuildContext context, Seller seller) async {
    final qrData = 'flixbit:seller:${seller.id}';
    final service = QRDownloadService();
    
    try {
      await service.shareQRCode(qrData, seller.name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code data copied to clipboard'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing QR code: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          spacing: 8,
          children: [
            Icon(
              icon,
              color: AppColors.primaryColor,
              size: 28,
            ),
            Text(
              label,
              style: AppTextStyles.smallTextStyle.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}