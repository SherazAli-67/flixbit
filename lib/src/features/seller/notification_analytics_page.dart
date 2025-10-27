import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../service/qr_notification_service.dart';
import '../../models/qr_notification_campaign_model.dart';
import '../../service/notification_quota_service.dart';

class NotificationAnalyticsPage extends StatefulWidget {
  const NotificationAnalyticsPage({super.key});

  @override
  State<NotificationAnalyticsPage> createState() => _NotificationAnalyticsPageState();
}

class _NotificationAnalyticsPageState extends State<NotificationAnalyticsPage> {
  final QRNotificationService _notificationService = QRNotificationService();
  final NotificationQuotaService _quotaService = NotificationQuotaService();
  
  List<QRNotificationCampaign> _campaigns = [];
  QuotaInfo? _quotaInfo;
  bool _isLoading = true;
  String _selectedTimeRange = '30d';
  
  // Analytics data
  int _totalCampaigns = 0;
  int _totalSent = 0;
  int _totalDelivered = 0;
  int _totalOpened = 0;
  double _averageDeliveryRate = 0.0;
  double _averageOpenRate = 0.0;
  Map<String, int> _campaignsByStatus = {};
  Map<String, int> _campaignsByAudience = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final sellerId = FirebaseAuth.instance.currentUser?.uid;
      if (sellerId == null) return;

      // Load campaigns
      _notificationService.getCampaigns(sellerId).listen((campaigns) {
        if (mounted) {
          setState(() {
            _campaigns = campaigns;
            _calculateAnalytics();
          });
        }
      });

      // Load quota info
      final quotaInfo = await _quotaService.getSellerQuota(sellerId);
      if (mounted) {
        setState(() => _quotaInfo = quotaInfo);
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateAnalytics() {
    _totalCampaigns = _campaigns.length;
    _totalSent = _campaigns.fold(0, (sum, campaign) => sum + campaign.sentCount);
    _totalDelivered = _campaigns.fold(0, (sum, campaign) => sum + campaign.deliveredCount);
    _totalOpened = _campaigns.fold(0, (sum, campaign) => sum + campaign.openedCount);
    
    _averageDeliveryRate = _totalSent > 0 ? (_totalDelivered / _totalSent) * 100 : 0.0;
    _averageOpenRate = _totalDelivered > 0 ? (_totalOpened / _totalDelivered) * 100 : 0.0;
    
    // Count by status
    _campaignsByStatus.clear();
    for (final campaign in _campaigns) {
      _campaignsByStatus[campaign.status.name] = (_campaignsByStatus[campaign.status.name] ?? 0) + 1;
    }
    
    // Count by audience
    _campaignsByAudience.clear();
    for (final campaign in _campaigns) {
      _campaignsByAudience[campaign.audience.name] = (_campaignsByAudience[campaign.audience.name] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        title: const Text(
          'Notification Analytics',
          style: AppTextStyles.headingTextStyle3,
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.whiteColor),
            onSelected: (value) {
              if (value == 'campaigns') {
                context.go('/notification_campaign_list_view');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'campaigns',
                child: Text('Manage Campaigns'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                spacing: 24,
                children: [
                  // Time Range Selector
                  _buildTimeRangeSelector(),
                  
                  // Summary Cards
                  _buildSummaryCards(),
                  
                  // Quota Information
                  if (_quotaInfo != null) _buildQuotaCard(),
                  
                  // Charts Section
                  _buildChartsSection(),
                  
                  // Recent Campaigns
                  _buildRecentCampaigns(),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFieldBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Time Range',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          Row(
            spacing: 8,
            children: [
              _buildTimeRangeButton('7d', '7 Days'),
              _buildTimeRangeButton('30d', '30 Days'),
              _buildTimeRangeButton('90d', '90 Days'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String value, String label) {
    final isSelected = _selectedTimeRange == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeRange = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.unSelectedGreyColor,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyTextStyle.copyWith(
            color: isSelected ? AppColors.whiteColor : AppColors.unSelectedGreyColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Campaigns',
            value: _totalCampaigns.toString(),
            icon: Icons.campaign,
            color: AppColors.primaryColor,
          ),
        ),
        Expanded(
          child: _buildSummaryCard(
            title: 'Notifications Sent',
            value: _totalSent.toString(),
            icon: Icons.send,
            color: AppColors.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFieldBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        spacing: 8,
        children: [
          Icon(icon, color: color, size: 24),
          Text(
            value,
            style: AppTextStyles.headingTextStyle3.copyWith(color: color),
          ),
          Text(
            title,
            style: AppTextStyles.hintTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _quotaInfo!.isNearLimit 
            ? Colors.orange.withValues(alpha: 0.1)
            : AppColors.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _quotaInfo!.isNearLimit 
              ? Colors.orange.withValues(alpha: 0.3)
              : AppColors.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        spacing: 12,
        children: [
          Row(
            children: [
              Icon(
                _quotaInfo!.isNearLimit ? Icons.warning : Icons.check_circle,
                color: _quotaInfo!.isNearLimit ? Colors.orange : AppColors.successColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Notification Quota',
                style: AppTextStyles.subHeadingTextStyle,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Used: ${_quotaInfo!.usedQuota}/${_quotaInfo!.totalQuota}',
                style: AppTextStyles.bodyTextStyle,
              ),
              Text(
                _quotaInfo!.usageDisplayText,
                style: AppTextStyles.bodyTextStyle.copyWith(
                  color: _quotaInfo!.isNearLimit ? Colors.orange : AppColors.successColor,
                ),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: _quotaInfo!.usagePercentage / 100,
            backgroundColor: AppColors.unSelectedGreyColor.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _quotaInfo!.isNearLimit ? Colors.orange : AppColors.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      spacing: 16,
      children: [
        // Delivery Rate Chart
        _buildDeliveryRateChart(),
        
        // Campaign Status Chart
        _buildCampaignStatusChart(),
        
        // Audience Distribution Chart
        _buildAudienceDistributionChart(),
      ],
    );
  }

  Widget _buildDeliveryRateChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFieldBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery & Open Rates',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('Delivery', style: AppTextStyles.hintTextStyle);
                          case 1:
                            return const Text('Open', style: AppTextStyles.hintTextStyle);
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: AppTextStyles.hintTextStyle,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: _averageDeliveryRate,
                        color: AppColors.primaryColor,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: _averageOpenRate,
                        color: AppColors.successColor,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignStatusChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFieldBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campaigns by Status',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _campaignsByStatus.entries.map((entry) {
                  final color = _getStatusColor(entry.key);
                  return PieChartSectionData(
                    color: color,
                    value: entry.value.toDouble(),
                    title: '${entry.value}',
                    radius: 50,
                    titleStyle: AppTextStyles.bodyTextStyle.copyWith(
                      color: AppColors.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _campaignsByStatus.entries.map((entry) {
              final color = _getStatusColor(entry.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusDisplayName(entry.key),
                    style: AppTextStyles.hintTextStyle,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceDistributionChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFieldBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campaigns by Audience',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          ..._campaignsByAudience.entries.map((entry) {
            final percentage = _totalCampaigns > 0 
                ? (entry.value / _totalCampaigns) * 100 
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _getAudienceDisplayName(entry.key),
                      style: AppTextStyles.bodyTextStyle,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: AppColors.unSelectedGreyColor.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                    style: AppTextStyles.hintTextStyle,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentCampaigns() {
    final recentCampaigns = _campaigns.take(5).toList();
    
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Campaigns',
              style: AppTextStyles.subHeadingTextStyle,
            ),
            TextButton(
              onPressed: () => context.go('/notification_campaign_list_view'),
              child: const Text('View All'),
            ),
          ],
        ),
        ...recentCampaigns.map((campaign) => _buildCampaignCard(campaign)).toList(),
      ],
    );
  }

  Widget _buildCampaignCard(QRNotificationCampaign campaign) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFieldBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(campaign.status.name).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  campaign.title,
                  style: AppTextStyles.tileTitleTextStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(campaign.status.name).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  campaign.statusDisplayName,
                  style: AppTextStyles.hintTextStyle.copyWith(
                    color: _getStatusColor(campaign.status.name),
                  ),
                ),
              ),
            ],
          ),
          Text(
            campaign.message,
            style: AppTextStyles.bodyTextStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sent: ${campaign.sentCount}',
                style: AppTextStyles.hintTextStyle,
              ),
              Text(
                'Delivery: ${campaign.deliveryRate.toStringAsFixed(1)}%',
                style: AppTextStyles.hintTextStyle,
              ),
              Text(
                'Open: ${campaign.openRate.toStringAsFixed(1)}%',
                style: AppTextStyles.hintTextStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'sent':
        return AppColors.successColor;
      case 'scheduled':
        return Colors.orange;
      case 'sending':
        return AppColors.primaryColor;
      case 'failed':
        return Colors.red;
      case 'draft':
        return AppColors.unSelectedGreyColor;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppColors.primaryColor;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'sent':
        return 'Sent';
      case 'scheduled':
        return 'Scheduled';
      case 'sending':
        return 'Sending';
      case 'failed':
        return 'Failed';
      case 'draft':
        return 'Draft';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _getAudienceDisplayName(String audience) {
    switch (audience) {
      case 'allFollowers':
        return 'All Followers';
      case 'qrScanFollowers':
        return 'QR Scan Followers';
      case 'offerFollowers':
        return 'Offer Followers';
      case 'manualFollowers':
        return 'Manual Followers';
      case 'dateRangeFollowers':
        return 'Recent Followers';
      case 'custom':
        return 'Custom';
      default:
        return audience;
    }
  }
}


