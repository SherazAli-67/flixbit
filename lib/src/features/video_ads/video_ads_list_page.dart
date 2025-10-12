import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/video_ad.dart';
import '../../providers/video_ads_providers.dart';
import '../../res/apptextstyles.dart';
import '../../res/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class VideoAdsListPage extends StatelessWidget {
  const VideoAdsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.videoAds),
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
          context.push(RouterEnum.videoDetailsView.routeName, extra: {
            'ad' : ad
          });
        },
      ),
    );
  }
}