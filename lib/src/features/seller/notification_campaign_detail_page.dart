import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../service/qr_notification_service.dart';
import '../../models/qr_notification_campaign_model.dart';

class NotificationCampaignDetailPage extends StatefulWidget {
  final String campaignId;
  
  const NotificationCampaignDetailPage({
    super.key,
    required this.campaignId,
  });

  @override
  State<NotificationCampaignDetailPage> createState() => _NotificationCampaignDetailPageState();
}

class _NotificationCampaignDetailPageState extends State<NotificationCampaignDetailPage> {
  final QRNotificationService _notificationService = QRNotificationService();
  
  QRNotificationCampaign? _campaign;
  bool _isLoading = true;
  String _selectedTab = 'overview';

  @override
  void initState() {
    super.initState();
    _loadCampaignDetails();
  }

  Future<void> _loadCampaignDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final sellerId = FirebaseAuth.instance.currentUser?.uid;
      if (sellerId == null) return;

      _notificationService.getCampaign(widget.campaignId).then((campaign) {
        if (mounted) {
          setState(() => _campaign = campaign);
        }
      });
    } catch (e) {
      debugPrint('Error loading campaign details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        title: Text(
          _campaign?.title ?? 'Campaign Details',
          style: AppTextStyles.headingTextStyle3,
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
        ),
        actions: [
          if (_campaign != null) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.whiteColor),
              onSelected: (value) => _handleAction(value),
              itemBuilder: (context) => _buildActionMenuItems(),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : _campaign == null
              ? const Center(child: Text('Campaign not found'))
              : Column(
                  children: [
                    // Status Banner
                    _buildStatusBanner(),
                    
                    // Tab Bar
                    _buildTabBar(),
                    
                    // Tab Content
                    Expanded(
                      child: _buildTabContent(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatusBanner() {
    if (_campaign == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(_campaign!.status).withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: _getStatusColor(_campaign!.status).withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(_campaign!.status),
            color: _getStatusColor(_campaign!.status),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _campaign!.statusDisplayName,
                  style: AppTextStyles.subHeadingTextStyle.copyWith(
                    color: _getStatusColor(_campaign!.status),
                  ),
                ),
                Text(
                  _getStatusDescription(_campaign!.status),
                  style: AppTextStyles.hintTextStyle,
                ),
              ],
            ),
          ),
          if (_campaign!.status == CampaignStatus.scheduled && _campaign!.scheduledFor != null)
            Text(
              'Scheduled for ${_formatDateTime(_campaign!.scheduledFor!)}',
              style: AppTextStyles.hintTextStyle,
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab('overview', 'Overview'),
          _buildTab('analytics', 'Analytics'),
          _buildTab('audience', 'Audience'),
        ],
      ),
    );
  }

  Widget _buildTab(String tabId, String label) {
    final isSelected = _selectedTab == tabId;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tabId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: isSelected ? AppColors.primaryColor : AppColors.unSelectedGreyColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'overview':
        return _buildOverviewTab();
      case 'analytics':
        return _buildAnalyticsTab();
      case 'audience':
        return _buildAudienceTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    if (_campaign == null) return const SizedBox.shrink();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 24,
        children: [
          // Campaign Information
          _buildCampaignInfo(),
          
          // Message Preview
          _buildMessagePreview(),
          
          // Performance Summary (for sent campaigns)
          if (_campaign!.status == CampaignStatus.sent) _buildPerformanceSummary(),
          
          // Timeline
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildCampaignInfo() {
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
            'Campaign Information',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          _buildInfoRow('Title', _campaign!.title),
          _buildInfoRow('Audience', _campaign!.audienceDisplayName),
          _buildInfoRow('Target Count', _campaign!.targetCount.toString()),
          _buildInfoRow('Created', _formatDateTime(_campaign!.createdAt)),
          if (_campaign!.scheduledFor != null)
            _buildInfoRow('Scheduled For', _formatDateTime(_campaign!.scheduledFor!)),
          if (_campaign!.sentAt != null)
            _buildInfoRow('Sent At', _formatDateTime(_campaign!.sentAt!)),
          if (_campaign!.actionRoute != null)
            _buildInfoRow('Action Route', _campaign!.actionRoute!),
          if (_campaign!.actionText != null)
            _buildInfoRow('Action Text', _campaign!.actionText!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.hintTextStyle,
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyTextStyle,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildMessagePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFieldBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Message Preview',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _campaign!.title,
                  style: AppTextStyles.bodyTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _campaign!.message,
                  style: AppTextStyles.bodyTextStyle,
                ),
                if (_campaign!.actionText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _campaign!.actionText!,
                      style: AppTextStyles.hintTextStyle.copyWith(
                        color: AppColors.whiteColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFieldBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        spacing: 16,
        children: [
          const Text(
            'Performance Summary',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'Sent',
                  _campaign!.sentCount.toString(),
                  AppColors.primaryColor,
                ),
              ),
              Expanded(
                child: _buildPerformanceCard(
                  'Delivered',
                  _campaign!.deliveredCount.toString(),
                  AppColors.successColor,
                ),
              ),
              Expanded(
                child: _buildPerformanceCard(
                  'Opened',
                  _campaign!.openedCount.toString(),
                  Colors.orange,
                ),
              ),
            ],
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'Delivery Rate',
                  '${_campaign!.deliveryRate.toStringAsFixed(1)}%',
                  AppColors.successColor,
                ),
              ),
              Expanded(
                child: _buildPerformanceCard(
                  'Open Rate',
                  '${_campaign!.openRate.toStringAsFixed(1)}%',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        spacing: 4,
        children: [
          Text(
            value,
            style: AppTextStyles.headingTextStyle3.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.hintTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
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
            'Timeline',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          _buildTimelineItem(
            'Campaign Created',
            _formatDateTime(_campaign!.createdAt),
            Icons.add_circle,
            AppColors.primaryColor,
          ),
          if (_campaign!.scheduledFor != null)
            _buildTimelineItem(
              'Campaign Scheduled',
              _formatDateTime(_campaign!.scheduledFor!),
              Icons.schedule,
              Colors.orange,
            ),
          if (_campaign!.sentAt != null)
            _buildTimelineItem(
              'Campaign Sent',
              _formatDateTime(_campaign!.sentAt!),
              Icons.send,
              AppColors.successColor,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            spacing: 2,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyTextStyle,
              ),
              Text(
                time,
                style: AppTextStyles.hintTextStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    if (_campaign == null || _campaign!.status != CampaignStatus.sent) {
      return Center(
        child: Column(
          spacing: 16,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.unSelectedGreyColor.withValues(alpha: 0.5),
            ),
            Text(
              'Analytics not available',
              style: AppTextStyles.subHeadingTextStyle.copyWith(
                color: AppColors.unSelectedGreyColor,
              ),
            ),
            Text(
              'Analytics will be available after the campaign is sent',
              style: AppTextStyles.hintTextStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 24,
        children: [
          // Performance Chart
          _buildPerformanceChart(),
          
          // Delivery Timeline
          _buildDeliveryTimeline(),
          
          // Audience Breakdown
          _buildAudienceBreakdown(),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
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
            'Performance Metrics',
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
                        toY: _campaign!.deliveryRate,
                        color: AppColors.successColor,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: _campaign!.openRate,
                        color: Colors.orange,
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

  Widget _buildDeliveryTimeline() {
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
            'Delivery Timeline',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          // This would show hourly delivery data if available
          Text(
            'Delivery completed at ${_formatDateTime(_campaign!.sentAt!)}',
            style: AppTextStyles.bodyTextStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceBreakdown() {
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
            'Audience Breakdown',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          _buildBreakdownItem('Total Targeted', _campaign!.targetCount.toString()),
          _buildBreakdownItem('Successfully Sent', _campaign!.sentCount.toString()),
          _buildBreakdownItem('Delivered', _campaign!.deliveredCount.toString()),
          _buildBreakdownItem('Opened', _campaign!.openedCount.toString()),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyTextStyle,
        ),
        Text(
          value,
          style: AppTextStyles.bodyTextStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAudienceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 24,
        children: [
          // Audience Information
          _buildAudienceInfo(),
          
          // Audience Filters
          if (_campaign!.filters != null) _buildAudienceFilters(),
        ],
      ),
    );
  }

  Widget _buildAudienceInfo() {
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
            'Audience Information',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          _buildInfoRow('Audience Type', _campaign!.audienceDisplayName),
          _buildInfoRow('Target Count', _campaign!.targetCount.toString()),
          _buildInfoRow('Sent Count', _campaign!.sentCount.toString()),
          _buildInfoRow('Delivery Rate', '${_campaign!.deliveryRate.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildAudienceFilters() {
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
            'Applied Filters',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          ..._campaign!.filters!.entries.map((entry) {
            return _buildInfoRow(
              entry.key,
              entry.value.toString(),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildActionMenuItems() {
    final items = <PopupMenuEntry<String>>[];
    
    if (_campaign!.status == CampaignStatus.draft) {
      items.add(
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: AppColors.primaryColor),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
      );
    }
    
    if (_campaign!.status == CampaignStatus.scheduled) {
      items.add(
        const PopupMenuItem(
          value: 'cancel',
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red),
              SizedBox(width: 8),
              Text('Cancel'),
            ],
          ),
        ),
      );
    }
    
    items.add(
      const PopupMenuItem(
        value: 'duplicate',
        child: Row(
          children: [
            Icon(Icons.copy, color: AppColors.primaryColor),
            SizedBox(width: 8),
            Text('Duplicate'),
          ],
        ),
      ),
    );
    
    return items;
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        context.go('/seller_push_notification_view', extra: _campaign!.id);
        break;
      case 'cancel':
        _cancelCampaign();
        break;
      case 'duplicate':
        _duplicateCampaign();
        break;
    }
  }

  Future<void> _cancelCampaign() async {
    final confirmed = await _showConfirmationDialog(
      'Cancel Campaign',
      'Are you sure you want to cancel this scheduled campaign?',
    );
    
    if (confirmed) {
      try {
        await _notificationService.cancelCampaign(_campaign!.id);
        _showSuccessSnackBar('Campaign cancelled successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to cancel campaign: $e');
      }
    }
  }

  Future<void> _duplicateCampaign() async {
    try {
      final newCampaignId = await _notificationService.createCampaign(
        sellerId: FirebaseAuth.instance.currentUser!.uid,
        title: '${_campaign!.title} (Copy)',
        message: _campaign!.message,
        audience: _campaign!.audience,
        filters: _campaign!.filters,
        actionRoute: _campaign!.actionRoute,
        actionText: _campaign!.actionText,
      );
      
      _showSuccessSnackBar('Campaign duplicated successfully');
      context.go('/seller_push_notification_view', extra: newCampaignId);
    } catch (e) {
      _showErrorSnackBar('Failed to duplicate campaign: $e');
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBgColor,
        title: Text(
          title,
          style: const TextStyle(color: AppColors.whiteColor),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.whiteColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Color _getStatusColor(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.sent:
        return AppColors.successColor;
      case CampaignStatus.scheduled:
        return Colors.orange;
      case CampaignStatus.sending:
        return AppColors.primaryColor;
      case CampaignStatus.failed:
        return Colors.red;
      case CampaignStatus.draft:
        return AppColors.unSelectedGreyColor;
      case CampaignStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.sent:
        return Icons.check_circle;
      case CampaignStatus.scheduled:
        return Icons.schedule;
      case CampaignStatus.sending:
        return Icons.send;
      case CampaignStatus.failed:
        return Icons.error;
      case CampaignStatus.draft:
        return Icons.edit;
      case CampaignStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusDescription(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.sent:
        return 'Campaign has been successfully sent to all targeted users';
      case CampaignStatus.scheduled:
        return 'Campaign is scheduled to be sent at the specified time';
      case CampaignStatus.sending:
        return 'Campaign is currently being sent to users';
      case CampaignStatus.failed:
        return 'Campaign failed to send. Please check your settings and try again';
      case CampaignStatus.draft:
        return 'Campaign is saved as draft and can be edited or sent later';
      case CampaignStatus.cancelled:
        return 'Campaign has been cancelled and will not be sent';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
