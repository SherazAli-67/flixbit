import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/video_ad.dart';
import '../../providers/video_ads_providers.dart';
import '../../res/apptextstyles.dart';
import '../../res/app_colors.dart';

class VideoAdsListPage extends StatelessWidget {
  const VideoAdsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Watch & Earn'),
      ),
      body: ChangeNotifierProvider(
        create: (ctx) => VideoAdsListProvider(createSeededFakeRepository())..load(),
        child: const _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoAdsListProvider>();
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text(provider.error!, style: AppTextStyles.smallTextStyle));
    }
    final ads = provider.ads;
    if (ads.isEmpty) {
      return const Center(child: Text('No ads available'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ad = ads[index];
        return _AdTile(ad: ad);
      },
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
        title: Text(ad.title, style: AppTextStyles.tileTitleTextStyle),
        subtitle: Text('${ad.durationSeconds}s • +${ad.rewardPoints} Flixbit', style: AppTextStyles.captionTextStyle),
        trailing: const Icon(Icons.play_arrow, color: Colors.white),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoAdDetailPage(ad: ad)));
        },
      ),
    );
  }
}

class VideoAdDetailPage extends StatefulWidget {
  final VideoAd ad;
  const VideoAdDetailPage({super.key, required this.ad});

  @override
  State<VideoAdDetailPage> createState() => _VideoAdDetailPageState();
}

class _VideoAdDetailPageState extends State<VideoAdDetailPage> {
  int watched = 0;
  late final repository = createSeededFakeRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.ad.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 16,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.ondemand_video, color: Colors.white, size: 48),
            ),
            Text('Watch to earn +${widget.ad.rewardPoints} Flixbit', style: AppTextStyles.subHeadingTextStyle),
            Text('Minimum watch: ${widget.ad.minWatchSeconds}s', style: AppTextStyles.captionTextStyle.copyWith(color: AppColors.unSelectedGreyColor)),
            Row(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    watched = widget.ad.minWatchSeconds;
                    await repository.recordProgress(widget.ad.id, watched);
                    if (!mounted) return;
                    setState(() {});
                  },
                  child: const Text('Simulate Watch'),
                ),
                ElevatedButton(
                  onPressed: watched >= widget.ad.minWatchSeconds ? () async {
                    final result = await repository.claimReward(widget.ad.id);
                    if (!mounted) return;
                    final text = result.success ? 'Reward: +${result.pointsAwarded}' : result.message;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
                  } : null,
                  child: const Text('Claim Reward'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

