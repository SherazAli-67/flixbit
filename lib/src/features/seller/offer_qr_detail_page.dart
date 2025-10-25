import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/offer_model.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../service/qr_download_service.dart';

class OfferQRDetailPage extends StatelessWidget {
  final Offer offer;

  const OfferQRDetailPage({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  spacing: 20,
                  children: [
                    // QR Code Display
                    _buildQRCodeSection(),

                    // Offer Details
                    _buildOfferDetailsSection(dateFormat),

                    // Action Buttons
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: ()=> context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.whiteColor,
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'Offer QR Code',
              style: AppTextStyles.headingTextStyle3,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 16,
        children: [
          Text(
            offer.title,
            style: AppTextStyles.subHeadingTextStyle,
            textAlign: TextAlign.center,
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: offer.qrCodeData,
              size: 250,
              backgroundColor: Colors.white,
            ),
          ),
          Text(
            'Scan this QR code to redeem the offer',
            style: AppTextStyles.captionTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOfferDetailsSection(DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const Text(
            'Offer Details',
            style: AppTextStyles.tileTitleTextStyle,
          ),
          const Divider(color: AppColors.unSelectedGreyColor),
          _buildDetailRow('Discount', offer.displayDiscount),
          _buildDetailRow('Valid From', dateFormat.format(offer.validFrom)),
          _buildDetailRow('Valid Until', dateFormat.format(offer.validUntil)),
          _buildDetailRow(
            'Redemptions',
            '${offer.currentRedemptions}${offer.maxRedemptions != null ? ' / ${offer.maxRedemptions}' : ''}',
          ),
          _buildDetailRow('Status', offer.isActive ? 'Active' : 'Inactive'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyTextStyle.copyWith(
            color: AppColors.unSelectedGreyColor,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        // Download Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: ()=> _downloadQRCode(context),
            icon: const Icon(Icons.download),
            label: const Text('Download QR Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.whiteColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        // Share Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: ()=> _shareQRCode(context),
            icon: const Icon(Icons.share),
            label: const Text('Share QR Code'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: const BorderSide(color: AppColors.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        // Copy QR Data Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: ()=> _copyQRData(context),
            icon: const Icon(Icons.copy),
            label: const Text('Copy QR Data'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.unSelectedGreyColor,
              side: const BorderSide(color: AppColors.unSelectedGreyColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _downloadQRCode(BuildContext context) async {
    final service = QRDownloadService();
    
    try {
      final path = await service.saveQRCodeToDevice(
        offer.qrCodeData,
        '${offer.title.replaceAll(' ', '_')}_QR',
      );
      
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

  void _shareQRCode(BuildContext context) async {
    final service = QRDownloadService();
    
    try {
      await service.shareQRCode(offer.qrCodeData, offer.title);
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

  void _copyQRData(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: offer.qrCodeData));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR data copied to clipboard'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying QR data: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }
}

