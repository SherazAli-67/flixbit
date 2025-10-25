import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/service/qr_scan_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScanHistoryPage extends StatefulWidget {
  const QRScanHistoryPage({super.key});

  @override
  State<QRScanHistoryPage> createState() => _QRScanHistoryPageState();
}

class _QRScanHistoryPageState extends State<QRScanHistoryPage> {
  final QRScanService _scanService = QRScanService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBgColor,
        body: const Center(
          child: Text(
            'Please sign in to view scan history',
            style: AppTextStyles.bodyTextStyle,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Scan History List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _scanService.getUserScans(_userId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint("Error: ${snapshot.error}");
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.errorColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: AppTextStyles.bodyTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final scans = snapshot.data ?? [];

                  if (scans.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 64,
                            color: AppColors.unSelectedGreyColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No scan history yet',
                            style: AppTextStyles.subHeadingTextStyle.copyWith(
                              color: AppColors.unSelectedGreyColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan a seller\'s QR code to get started',
                            style: AppTextStyles.bodyTextStyle.copyWith(
                              color: AppColors.unSelectedGreyColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: scans.length,
                    itemBuilder: (context, index) {
                      return _buildScanCard(scans[index]);
                    },
                  );
                },
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
              'Scan History',
              style: AppTextStyles.headingTextStyle3,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan) {
    final scannedAt = (scan['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final pointsAwarded = scan['pointsAwarded'] ?? 0;
    final sellerId = scan['sellerId'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Main Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // QR Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),

                // Scan Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seller Scan',
                        style: AppTextStyles.tileTitleTextStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${sellerId.substring(0, 8)}...',
                        style: AppTextStyles.captionTextStyle,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.unSelectedGreyColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(scannedAt),
                            style: AppTextStyles.captionTextStyle,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.unSelectedGreyColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeFormat.format(scannedAt),
                            style: AppTextStyles.captionTextStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Points Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+$pointsAwarded',
                        style: AppTextStyles.bodyTextStyle.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Location Info (if available)
          if (scan['location'] != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkBgColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Location tracked',
                    style: AppTextStyles.captionTextStyle.copyWith(
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
}

