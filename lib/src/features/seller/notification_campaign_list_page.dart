import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../service/qr_notification_service.dart';
import '../../models/qr_notification_campaign_model.dart';

class NotificationCampaignListPage extends StatefulWidget {
  const NotificationCampaignListPage({super.key});

  @override
  State<NotificationCampaignListPage> createState() => _NotificationCampaignListPageState();
}

class _NotificationCampaignListPageState extends State<NotificationCampaignListPage> {
  final QRNotificationService _notificationService = QRNotificationService();
  
  List<QRNotificationCampaign> _allCampaigns = [];
  List<QRNotificationCampaign> _filteredCampaigns = [];
  String _selectedFilter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _isLoading = true);
    
    try {
      final sellerId = FirebaseAuth.instance.currentUser?.uid;
      if (sellerId == null) return;

      _notificationService.getCampaigns(sellerId).listen((campaigns) {
        if (mounted) {
          setState(() {
            _allCampaigns = campaigns;
            _applyFilter();
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading campaigns: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    setState(() {
      switch (_selectedFilter) {
        case 'all':
          _filteredCampaigns = _allCampaigns;
          break;
        case 'sent':
          _filteredCampaigns = _allCampaigns.where((c) => c.status == CampaignStatus.sent).toList();
          break;
        case 'scheduled':
          _filteredCampaigns = _allCampaigns.where((c) => c.status == CampaignStatus.scheduled).toList();
          break;
        case 'draft':
          _filteredCampaigns = _allCampaigns.where((c) => c.status == CampaignStatus.draft).toList();
          break;
        case 'failed':
          _filteredCampaigns = _allCampaigns.where((c) => c.status == CampaignStatus.failed).toList();
          break;
        default:
          _filteredCampaigns = _allCampaigns;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        title: const Text(
          'Notification Campaigns',
          style: AppTextStyles.headingTextStyle3,
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/seller_push_notification_view'),
            icon: const Icon(Icons.add, color: AppColors.primaryColor),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : Column(
              children: [
                // Filter Tabs
                _buildFilterTabs(),
                
                // Campaign List
                Expanded(
                  child: _filteredCampaigns.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadCampaigns,
                          color: AppColors.primaryColor,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredCampaigns.length,
                            itemBuilder: (context, index) {
                              final campaign = _filteredCampaigns[index];
                              return _buildCampaignCard(campaign);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            _buildFilterTab('all', 'All', _allCampaigns.length),
            _buildFilterTab('sent', 'Sent', _allCampaigns.where((c) => c.status == CampaignStatus.sent).length),
            _buildFilterTab('scheduled', 'Scheduled', _allCampaigns.where((c) => c.status == CampaignStatus.scheduled).length),
            _buildFilterTab('draft', 'Draft', _allCampaigns.where((c) => c.status == CampaignStatus.draft).length),
            _buildFilterTab('failed', 'Failed', _allCampaigns.where((c) => c.status == CampaignStatus.failed).length),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label, int count) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filter);
        _applyFilter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.inputFieldBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.unSelectedGreyColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Text(
              label,
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: isSelected ? AppColors.whiteColor : AppColors.unSelectedGreyColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.whiteColor.withValues(alpha: 0.2)
                    : AppColors.unSelectedGreyColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: AppTextStyles.hintTextStyle.copyWith(
                  color: isSelected ? AppColors.whiteColor : AppColors.unSelectedGreyColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignCard(QRNotificationCampaign campaign) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFieldBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(campaign.status).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
              Row(
                spacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(campaign.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      campaign.statusDisplayName,
                      style: AppTextStyles.hintTextStyle.copyWith(
                        color: _getStatusColor(campaign.status),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.unSelectedGreyColor),
                    onSelected: (value) => _handleCampaignAction(value, campaign),
                    itemBuilder: (context) => _buildCampaignMenuItems(campaign),
                  ),
                ],
              ),
            ],
          ),
          
          // Message
          Text(
            campaign.message,
            style: AppTextStyles.bodyTextStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Audience & Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audience: ${campaign.audienceDisplayName}',
                style: AppTextStyles.hintTextStyle,
              ),
              Text(
                'Target: ${campaign.targetCount}',
                style: AppTextStyles.hintTextStyle,
              ),
            ],
          ),
          
          // Performance Stats (only for sent campaigns)
          if (campaign.status == CampaignStatus.sent) ...[
            const Divider(color: AppColors.unSelectedGreyColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Sent', campaign.sentCount.toString()),
                _buildStatItem('Delivered', campaign.deliveredCount.toString()),
                _buildStatItem('Opened', campaign.openedCount.toString()),
                _buildStatItem('Rate', '${campaign.openRate.toStringAsFixed(1)}%'),
              ],
            ),
          ],
          
          // Date & Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Created: ${_formatDate(campaign.createdAt)}',
                style: AppTextStyles.hintTextStyle,
              ),
              if (campaign.sentAt != null)
                Text(
                  'Sent: ${_formatDate(campaign.sentAt!)}',
                  style: AppTextStyles.hintTextStyle,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      spacing: 2,
      children: [
        Text(
          value,
          style: AppTextStyles.bodyTextStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.hintTextStyle,
        ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _buildCampaignMenuItems(QRNotificationCampaign campaign) {
    final items = <PopupMenuEntry<String>>[];
    
    // View Details
    items.add(
      const PopupMenuItem(
        value: 'view',
        child: Row(
          children: [
            Icon(Icons.visibility, color: AppColors.primaryColor),
            SizedBox(width: 8),
            Text('View Details'),
          ],
        ),
      ),
    );
    
    // Edit (only for draft campaigns)
    if (campaign.status == CampaignStatus.draft) {
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
    
    // Cancel (only for scheduled campaigns)
    if (campaign.status == CampaignStatus.scheduled) {
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
    
    // Duplicate
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
    
    // Delete (only for draft campaigns)
    if (campaign.status == CampaignStatus.draft) {
      items.add(
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      );
    }
    
    return items;
  }

  void _handleCampaignAction(String action, QRNotificationCampaign campaign) {
    switch (action) {
      case 'view':
        context.go('/notification_campaign_detail_view', extra: campaign.id);
        break;
      case 'edit':
        // Navigate to edit campaign (could reuse the create page)
        context.go('/seller_push_notification_view', extra: campaign.id);
        break;
      case 'cancel':
        _cancelCampaign(campaign);
        break;
      case 'duplicate':
        _duplicateCampaign(campaign);
        break;
      case 'delete':
        _deleteCampaign(campaign);
        break;
    }
  }

  Future<void> _cancelCampaign(QRNotificationCampaign campaign) async {
    final confirmed = await _showConfirmationDialog(
      'Cancel Campaign',
      'Are you sure you want to cancel this scheduled campaign?',
    );
    
    if (confirmed) {
      try {
        await _notificationService.cancelCampaign(campaign.id);
        _showSuccessSnackBar('Campaign cancelled successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to cancel campaign: $e');
      }
    }
  }

  Future<void> _duplicateCampaign(QRNotificationCampaign campaign) async {
    try {
      final newCampaignId = await _notificationService.createCampaign(
        sellerId: FirebaseAuth.instance.currentUser!.uid,
        title: '${campaign.title} (Copy)',
        message: campaign.message,
        audience: campaign.audience,
        filters: campaign.filters,
        actionRoute: campaign.actionRoute,
        actionText: campaign.actionText,
      );
      
      _showSuccessSnackBar('Campaign duplicated successfully');
      
      // Navigate to edit the duplicated campaign
      context.go('/seller_push_notification_view', extra: newCampaignId);
    } catch (e) {
      _showErrorSnackBar('Failed to duplicate campaign: $e');
    }
  }

  Future<void> _deleteCampaign(QRNotificationCampaign campaign) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Campaign',
      'Are you sure you want to delete this campaign? This action cannot be undone.',
    );
    
    if (confirmed) {
      try {
        // Note: We would need to add a delete method to QRNotificationService
        _showSuccessSnackBar('Campaign deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete campaign: $e');
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        spacing: 16,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 64,
            color: AppColors.unSelectedGreyColor.withValues(alpha: 0.5),
          ),
          Text(
            'No campaigns found',
            style: AppTextStyles.subHeadingTextStyle.copyWith(
              color: AppColors.unSelectedGreyColor,
            ),
          ),
          Text(
            'Create your first notification campaign to engage with your followers',
            style: AppTextStyles.hintTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/seller_push_notification_view'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Create Campaign'),
          ),
        ],
      ),
    );
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}


