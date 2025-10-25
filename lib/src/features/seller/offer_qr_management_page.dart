import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/offer_model.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../service/qr_download_service.dart';
import '../../service/offer_service.dart';

class OfferQRManagementPage extends StatefulWidget {
  final Offer offer;

  const OfferQRManagementPage({super.key, required this.offer});

  @override
  State<OfferQRManagementPage> createState() => _OfferQRManagementPageState();
}

class _OfferQRManagementPageState extends State<OfferQRManagementPage> {
  final OfferService _offerService = OfferService();
  Map<String, dynamic> _analytics = {};
  bool _isLoadingAnalytics = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(()=> _isLoadingAnalytics = true);
    
    final analytics = await _offerService.getOfferAnalytics(widget.offer.id);
    
    if (mounted) {
      setState(() {
        _analytics = analytics;
        _isLoadingAnalytics = false;
      });
    }
  }

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
              child: RefreshIndicator(
                onRefresh: _loadAnalytics,
                color: AppColors.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    spacing: 20,
                    children: [
                      // QR Code Display Section
                      _buildQRCodeSection(),

                      // Offer Details Section
                      _buildOfferDetailsSection(dateFormat),

                      // Analytics Section
                      _buildAnalyticsSection(),

                      // QR Actions Section
                      _buildQRActionsSection(context),

                      // QR Settings Section
                      _buildQRSettingsSection(),
                    ],
                  ),
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
              'QR Management',
              style: AppTextStyles.headingTextStyle3,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(
              Icons.refresh,
              color: AppColors.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 16,
        children: [
          // Offer Image
          if (widget.offer.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: widget.offer.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          // Title
          Text(
            widget.offer.title,
            style: AppTextStyles.subHeadingTextStyle,
            textAlign: TextAlign.center,
          ),

          // Discount Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.offer.displayDiscount,
              style: AppTextStyles.tileTitleTextStyle.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),

          // QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: widget.offer.qrCodeData,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),

          Text(
            'Customers scan this code to redeem',
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
          _buildDetailRow('Valid From', dateFormat.format(widget.offer.validFrom)),
          _buildDetailRow('Valid Until', dateFormat.format(widget.offer.validUntil)),
          _buildDetailRow(
            'Redemptions',
            '${widget.offer.currentRedemptions}${widget.offer.maxRedemptions != null ? ' / ${widget.offer.maxRedemptions}' : ' / Unlimited'}',
          ),
          _buildDetailRow(
            'Status',
            widget.offer.isActive ? 'Active' : 'Inactive',
            valueColor: widget.offer.isActive ? Colors.green : Colors.red,
          ),
          _buildDetailRow(
            'Approval',
            widget.offer.status.name.toUpperCase(),
            valueColor: widget.offer.isApproved ? Colors.green : Colors.orange,
          ),
          if (widget.offer.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Description',
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.unSelectedGreyColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.offer.description,
              style: AppTextStyles.bodyTextStyle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
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
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection() {
    if (_isLoadingAnalytics) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        ),
      );
    }

    final views = _analytics['views'] ?? 0;
    final redemptions = _analytics['redemptions'] ?? 0;
    final qrRedemptions = _analytics['qrRedemptions'] ?? 0;
    final digitalRedemptions = _analytics['digitalRedemptions'] ?? 0;
    final conversionRate = _analytics['conversionRate'] ?? '0%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          const Text(
            'Analytics',
            style: AppTextStyles.tileTitleTextStyle,
          ),
          const Divider(color: AppColors.unSelectedGreyColor),
          
          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Views', '$views', Icons.visibility, AppColors.primaryColor),
              _buildStatCard('Redemptions', '$redemptions', Icons.shopping_bag, Colors.green),
              _buildStatCard('QR Scans', '$qrRedemptions', Icons.qr_code_scanner, Colors.orange),
              _buildStatCard('Digital', '$digitalRedemptions', Icons.phone_android, Colors.purple),
            ],
          ),

          const SizedBox(height: 8),

          // Conversion Rate
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                    const Text(
                      'Conversion Rate',
                      style: AppTextStyles.bodyTextStyle,
                    ),
                  ],
                ),
                Text(
                  conversionRate,
                  style: AppTextStyles.tileTitleTextStyle.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 6,
        children: [
          Icon(icon, color: color, size: 24),
          Text(
            value,
            style: AppTextStyles.subHeadingTextStyle.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.captionTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQRActionsSection(BuildContext context) {
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
            'QR Actions',
            style: AppTextStyles.tileTitleTextStyle,
          ),
          const Divider(color: AppColors.unSelectedGreyColor),
          
          _buildActionButton(
            icon: Icons.download,
            label: 'Download QR Code',
            onTap: ()=> _downloadQRCode(context),
          ),
          _buildActionButton(
            icon: Icons.share,
            label: 'Share QR Code',
            onTap: ()=> _shareQRCode(context),
          ),
          _buildActionButton(
            icon: Icons.copy,
            label: 'Copy QR Data',
            onTap: ()=> _copyQRData(context),
          ),
          _buildActionButton(
            icon: Icons.print,
            label: 'Generate Printable Flyer',
            onTap: ()=> _generateFlyer(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          spacing: 12,
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 20),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyTextStyle,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.unSelectedGreyColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRSettingsSection() {
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
            'QR Settings',
            style: AppTextStyles.tileTitleTextStyle,
          ),
          const Divider(color: AppColors.unSelectedGreyColor),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'QR Code Status',
                style: AppTextStyles.bodyTextStyle,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.offer.isActive 
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.offer.isActive ? 'Active' : 'Inactive',
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: widget.offer.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'QR Code ID: ${widget.offer.id.substring(0, 8)}...',
            style: AppTextStyles.captionTextStyle,
          ),

          Text(
            'Created: ${DateFormat('MMM dd, yyyy').format(widget.offer.createdAt)}',
            style: AppTextStyles.captionTextStyle,
          ),
        ],
      ),
    );
  }

  void _downloadQRCode(BuildContext context) async {
    final service = QRDownloadService();
    
    try {
      final path = await service.saveQRCodeToDevice(
        widget.offer.qrCodeData,
        '${widget.offer.title.replaceAll(' ', '_')}_QR',
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
      await service.shareQRCode(widget.offer.qrCodeData, widget.offer.title);
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
      await Clipboard.setData(ClipboardData(text: widget.offer.qrCodeData));
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

  void _generateFlyer(BuildContext context) {
    // TODO: Implement PDF generation for printable flyer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Printable flyer generation coming soon'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }
}

