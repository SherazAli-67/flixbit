import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';
import '../routes/router_enum.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (_userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<NotificationProvider>().initialize(_userId!);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab bar
            _buildTabBar(),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllNotificationsTab(),
                  _buildUnreadNotificationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.whiteColor,
              size: 24,
            ),
          ),
          Expanded(
            child: Text(
              'Notifications',
              textAlign: TextAlign.center,
              style: AppTextStyles.subHeadingTextStyle,
            ),
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () => provider.markAllAsRead(),
                  child: Text(
                    'Mark All Read',
                    style: AppTextStyles.smallTextStyle.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                );
              }
              return const SizedBox(width: 48); // Balance the back button
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
       /* indicator: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),*/
        labelColor: AppColors.whiteColor,
        unselectedLabelColor: AppColors.lightGreyColor,
        labelStyle: AppTextStyles.smallBoldTextStyle,
        unselectedLabelStyle: AppTextStyles.smallTextStyle,
        tabs: [
          Tab(text: 'All'),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Unread'),
                    if (provider.unreadCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${provider.unreadCount}',
                          style: AppTextStyles.smallTextStyle.copyWith(
                            color: AppColors.whiteColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllNotificationsTab() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        if (provider.allNotifications.isEmpty) {
          return _buildEmptyState(
            icon: Icons.notifications_none,
            title: 'No notifications yet',
            subtitle: 'You\'ll see your notifications here when they arrive.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          color: AppColors.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.allNotifications.length,
            itemBuilder: (context, index) {
              final notification = provider.allNotifications[index];
              return _buildNotificationCard(notification);
            },
          ),
        );
      },
    );
  }

  Widget _buildUnreadNotificationsTab() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        if (provider.unreadNotifications.isEmpty) {
          return _buildEmptyState(
            icon: Icons.mark_email_read,
            title: 'All caught up!',
            subtitle: 'You have no unread notifications.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          color: AppColors.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.unreadNotifications.length,
            itemBuilder: (context, index) {
              final notification = provider.unreadNotifications[index];
              return _buildNotificationCard(notification);
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: notification.isRead 
            ? null 
            : Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 12,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    notification.typeIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    // Title and time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.bodyTextStyle.copyWith(
                              fontWeight: notification.isRead 
                                  ? FontWeight.normal 
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    
                    // Body
                    Text(
                      notification.body,
                      style: AppTextStyles.smallTextStyle.copyWith(
                        color: AppColors.lightGreyColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Time
                    Text(
                      _formatTime(notification.createdAt),
                      style: AppTextStyles.smallTextStyle.copyWith(
                        color: AppColors.lightGreyColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action button
              if (notification.actionText != null)
                TextButton(
                  onPressed: () => _handleNotificationTap(notification),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    notification.actionText!,
                    style: AppTextStyles.smallTextStyle.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          Icon(
            icon,
            color: AppColors.lightGreyColor,
            size: 64,
          ),
          Text(
            title,
            style: AppTextStyles.subHeadingTextStyle,
          ),
          Text(
            subtitle,
            style: AppTextStyles.smallTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    context.read<NotificationProvider>().markAsRead(notification.id);
    
    // Handle navigation
    if (notification.actionRoute != null) {
      context.push(notification.actionRoute!);
    } else {
      // Default navigation based on notification type
      switch (notification.type) {
        case NotificationType.rewardRedemption:
        case NotificationType.rewardExpiring:
        case NotificationType.rewardShipped:
        case NotificationType.rewardDelivered:
          context.push(RouterEnum.myRewardsView.routeName);
          break;
        case NotificationType.tournamentWin:
          context.push(RouterEnum.gamePredictionView.routeName);
          break;
        case NotificationType.offerAvailable:
          context.push(RouterEnum.offersView.routeName);
          break;
        case NotificationType.pointsEarned:
          context.push(RouterEnum.walletView.routeName);
          break;
        default:
          break;
      }
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.rewardRedemption:
        return AppColors.successColor;
      case NotificationType.rewardExpiring:
        return AppColors.orangeColor;
      case NotificationType.rewardShipped:
        return AppColors.primaryColor;
      case NotificationType.rewardDelivered:
        return AppColors.successColor;
      case NotificationType.tournamentWin:
        return AppColors.purpleColor;
      case NotificationType.offerAvailable:
        return AppColors.successColor;
      case NotificationType.pointsEarned:
        return AppColors.primaryColor;
      case NotificationType.other:
        return AppColors.lightGreyColor;
      default:
        return AppColors.primaryColor;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

