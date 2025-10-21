import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/video_ad.dart';
import '../../../models/video_analytics.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';
import '../../../res/firebase_constants.dart';
import '../../../routes/router_enum.dart';
import '../../../service/video_analytics_service.dart';
import '../../../../l10n/app_localizations.dart';

class SellerVideoAdsPage extends StatefulWidget {
  const SellerVideoAdsPage({super.key});

  @override
  State<SellerVideoAdsPage> createState() => _SellerVideoAdsPageState();
}

class _SellerVideoAdsPageState extends State<SellerVideoAdsPage> {
  final VideoAnalyticsService _analyticsService = VideoAnalyticsService();
  List<VideoAd> _videos = [];
  Map<String, VideoAnalytics> _analyticsMap = {};
  Map<String, dynamic> _aggregateStats = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _loading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');

      // Fetch seller's videos
      final videosSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseConstants.videoAdsCollection)
          .where('uploadedBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _videos = videosSnapshot.docs
          .map((doc) => VideoAd.fromFirestore(doc.data(), doc.id))
          .toList();

      // Fetch analytics for each video
      for (final video in _videos) {
        final analytics = await _analyticsService.getVideoAnalytics(video.id);
        if (analytics != null) {
          _analyticsMap[video.id] = analytics;
        }
      }

      // Calculate aggregate stats
      _aggregateStats = await _analyticsService.getAggregateStats(userId);

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: ()=> context.pop(),
        ),
        title: Text(l10n.videoAds, style: AppTextStyles.whiteBold20),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadVideos,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildContent(context),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(_error!, style: AppTextStyles.bodyTextStyle),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadVideos,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Overview
          if (_aggregateStats.isNotEmpty) ...[
            const Text('Performance Overview', style: AppTextStyles.whiteBold18),
            const SizedBox(height: 16),
            _buildPerformanceCards(),
            const SizedBox(height: 32),
          ],
          
          // Upload Actions
          const Text('Upload or Link Video', style: AppTextStyles.whiteBold18),
          const SizedBox(height: 16),
          
          Row(
            spacing: 12,
            children: [
              Expanded(child: _buildUploadButton(context)),
              Expanded(child: _buildEmbedButton()),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Manage Videos Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Videos', style: AppTextStyles.whiteBold18),
              Text('${_videos.length} videos', style: AppTextStyles.lightGrayRegular14),
            ],
          ),
          const SizedBox(height: 16),
          
          // Video List
          _videos.isEmpty ? _buildEmptyState() : _buildVideosList(),
        ],
      ),
    );
  }

  Widget _buildPerformanceCards() {
    final totalViews = _aggregateStats['totalViews'] ?? 0;
    final totalWatchTime = _aggregateStats['totalWatchTime'] ?? 0;
    final avgEngagement = (_aggregateStats['avgEngagement'] ?? 0.0) as double;
    
    return Row(
      spacing: 12,
      children: [
        Expanded(child: _buildStatCard('Views', '$totalViews', Icons.visibility, Colors.blue)),
        Expanded(child: _buildStatCard('Watch Time', _formatDuration(totalWatchTime), Icons.access_time, Colors.green)),
        Expanded(child: _buildStatCard('Engagement', '${avgEngagement.toStringAsFixed(1)}%', Icons.trending_up, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.whiteBold18),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.lightGrayRegular12, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return GestureDetector(
      onTap: ()=> context.push(RouterEnum.uploadVideoAdView.routeName),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: const [
            Icon(Icons.upload_file, color: AppColors.whiteColor, size: 24),
            Text('Upload Video', style: AppTextStyles.whiteBold16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmbedButton() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: const [
          Icon(Icons.link, color: AppColors.whiteColor, size: 24),
          Text('Embed Link', style: AppTextStyles.whiteBold16),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.video_library, size: 64, color: AppColors.unSelectedGreyColor),
            const SizedBox(height: 16),
            const Text('No videos yet', style: AppTextStyles.bodyTextStyle),
            const SizedBox(height: 8),
            Text(
              'Upload your first video to start earning',
              style: AppTextStyles.lightGrayRegular14,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosList() {
    return Column(
      children: _videos.map((video) {
        final analytics = _analyticsMap[video.id];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildVideoCard(video, analytics),
        );
      }).toList(),
    );
  }

  Widget _buildVideoCard(VideoAd video, VideoAnalytics? analytics) {
    final views = analytics?.totalViews ?? 0;
    final uploadDate = video.createdAt;
    final statusColor = _getStatusColor(video.approvalStatus);
    final statusText = _getStatusText(video.approvalStatus);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: video.approvalStatus == ApprovalStatus.approved
            ? Border.all(color: Colors.green.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        spacing: 12,
        children: [
          // Thumbnail
          Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.darkGreyColor,
            ),
            child: video.thumbnailUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      video.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.play_circle_outline,
                        color: AppColors.whiteColor,
                        size: 32,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.play_circle_outline,
                    color: AppColors.whiteColor,
                    size: 32,
                  ),
          ),
          
          // Video Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video.title, style: AppTextStyles.whiteBold16),
                const SizedBox(height: 4),
                Text(
                  _formatUploadDate(uploadDate),
                  style: AppTextStyles.lightGrayRegular14,
                ),
                const SizedBox(height: 4),
                Row(
                  spacing: 12,
                  children: [
                    Row(
                      spacing: 4,
                      children: [
                        const Icon(Icons.visibility, color: AppColors.lightGreyColor, size: 16),
                        Text('$views', style: AppTextStyles.lightGrayRegular14),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Options Menu
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.whiteColor),
            onPressed: ()=> _showOptionsMenu(context, video),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, VideoAd video) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_circle, color: AppColors.whiteColor),
            title: const Text('Preview Video', style: AppTextStyles.bodyTextStyle),
            onTap: () {
              context.pop();
              context.push(RouterEnum.videoDetailsView.routeName, extra: {'ad': video});
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: AppColors.whiteColor),
            title: const Text('View Analytics', style: AppTextStyles.bodyTextStyle),
            onTap: () {
              context.pop();
              // Navigate to detailed analytics (Option 1 - future implementation)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Detailed analytics coming soon')),
              );
            },
          ),
          if (video.approvalStatus == ApprovalStatus.pending)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Video', style: TextStyle(color: Colors.red)),
              onTap: () {
                context.pop();
                _confirmDelete(context, video);
              },
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, VideoAd video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Delete Video?', style: AppTextStyles.headingTextStyle3),
        content: Text('Are you sure you want to delete "${video.title}"?'),
        actions: [
          TextButton(
            onPressed: ()=> context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              context.pop();
              await _deleteVideo(video.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVideo(String videoId) async {
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.videoAdsCollection)
          .doc(videoId)
          .delete();
      
      await _loadVideos(); // Reload list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting video: $e')),
        );
      }
    }
  }

  Color _getStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.approved:
        return Colors.green;
      case ApprovalStatus.pending:
        return Colors.orange;
      case ApprovalStatus.rejected:
        return Colors.red;
      case ApprovalStatus.flagged:
        return Colors.purple;
      case ApprovalStatus.inactive:
        return Colors.grey;
    }
  }

  String _getStatusText(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.pending:
        return 'Pending';
      case ApprovalStatus.rejected:
        return 'Rejected';
      case ApprovalStatus.flagged:
        return 'Flagged';
      case ApprovalStatus.inactive:
        return 'Inactive';
    }
  }

  String _formatUploadDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Uploaded today';
    } else if (diff.inDays == 1) {
      return 'Uploaded yesterday';
    } else if (diff.inDays < 7) {
      return 'Uploaded ${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return 'Uploaded $weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      return 'Uploaded on ${DateFormat('MMM d, yyyy').format(date)}';
    }
  }

  String _formatDuration(int seconds) {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }
}
