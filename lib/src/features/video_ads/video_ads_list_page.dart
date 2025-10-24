import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/video_ad.dart';
import '../../res/apptextstyles.dart';
import '../../res/app_colors.dart';
import '../../res/firebase_constants.dart';
import '../../routes/router_enum.dart';

class VideoAdsListPage extends StatefulWidget {
  const VideoAdsListPage({super.key});

  @override
  State<VideoAdsListPage> createState() => _VideoAdsListPageState();
}

class _VideoAdsListPageState extends State<VideoAdsListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<VideoAd> _videos = [];
  bool _loading = true;
  String? _error;
  String? _selectedCategory;
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(()=> _loading = true);

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(FirebaseConstants.videoAdsCollection)
          .where('approvalStatus', isEqualTo: 'approved');

      if (_selectedCategory != null) {
        query = query.where('category', isEqualTo: _selectedCategory);
      }

      if (_selectedRegion != null) {
        query = query.where('region', isEqualTo: _selectedRegion);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      _videos = snapshot.docs
          .map((doc) => VideoAd.fromFirestore(doc.data(), doc.id))
          .where((ad) => ad.isActiveNow)
          .toList();

      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint("Error while fetching videos: ${e.toString()}");
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Watch & Earn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: ()=> _showFilterDialog(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.withValues(alpha: 0.7)),
            Text(_error!, style: AppTextStyles.smallTextStyle, textAlign: TextAlign.center),
            ElevatedButton(
              onPressed: _loadVideos,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Icon(Icons.videocam_off, size: 64, color: AppColors.unSelectedGreyColor),
            const Text('No videos available', style: AppTextStyles.bodyTextStyle),
            Text(
              'Check back later for new videos',
              style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.lightGreyColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVideos,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _videos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _AdTile(ad: _videos[index]),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: const Text('Filter Videos', style: AppTextStyles.headingTextStyle3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                filled: true,
                fillColor: AppColors.darkBgColor,
              ),
              style: AppTextStyles.bodyTextStyle,
              dropdownColor: AppColors.darkBgColor,
              items: const [
                DropdownMenuItem(value: null, child: Text('All Categories')),
                DropdownMenuItem(value: 'Food & Dining', child: Text('Food & Dining')),
                DropdownMenuItem(value: 'Fitness & Sports', child: Text('Fitness & Sports')),
                DropdownMenuItem(value: 'Entertainment', child: Text('Entertainment')),
                DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
                DropdownMenuItem(value: 'Fashion', child: Text('Fashion')),
              ],
              onChanged: (value)=> setState(()=> _selectedCategory = value),
            ),
            DropdownButtonFormField<String>(
              value: _selectedRegion,
              decoration: const InputDecoration(
                labelText: 'Region',
                filled: true,
                fillColor: AppColors.darkBgColor,
              ),
              style: AppTextStyles.bodyTextStyle,
              dropdownColor: AppColors.darkBgColor,
              items: const [
                DropdownMenuItem(value: null, child: Text('All Regions')),
                DropdownMenuItem(value: 'Dubai', child: Text('Dubai')),
                DropdownMenuItem(value: 'Abu Dhabi', child: Text('Abu Dhabi')),
                DropdownMenuItem(value: 'Riyadh', child: Text('Riyadh')),
                DropdownMenuItem(value: 'Jeddah', child: Text('Jeddah')),
                DropdownMenuItem(value: 'Karachi', child: Text('Karachi')),
              ],
              onChanged: (value)=> setState(()=> _selectedRegion = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: ()=> context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              _loadVideos();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _AdTile extends StatelessWidget {
  final VideoAd ad;
  const _AdTile({required this.ad});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: ad.thumbnailUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ad.thumbnailUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: AppColors.darkBgColor,
                    child: const Icon(Icons.play_circle_outline, color: Colors.white),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.darkBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.play_circle_outline, color: Colors.white),
              ),
        title: Text(ad.title, style: AppTextStyles.tileTitleTextStyle),
        subtitle: Text(
          '${ad.durationSeconds}s • +${ad.rewardPoints} Flixbit',
          style: AppTextStyles.captionTextStyle,
        ),
        trailing: const Icon(Icons.play_arrow, color: Colors.white),
        onTap: ()=> context.push(
          RouterEnum.videoDetailsView.routeName,
          extra: {'ad': ad},
        ),
      ),
    );
  }
}
