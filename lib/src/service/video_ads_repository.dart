import 'dart:async';

import '../models/video_ad.dart';

abstract class VideoAdsRepository {
  Future<List<VideoAd>> fetchAds({String? category, String? region});
  Stream<AdPlaybackRule> getPlaybackRule(String adId);
  Future<void> recordProgress(String adId, int watchedSeconds);
  Future<void> submitRating(String adId, bool thumbsUp);
  Future<RewardResult> claimReward(String adId);
  Future<void> submitVote(String adId, bool thumbsUp);
}

class VideoAdsRepositoryFake implements VideoAdsRepository {
  final Map<String, VideoAd> _ads;
  final Map<String, int> _progressSecondsByAd = {};
  final Set<String> _rewardedAdIds = {};
  final Map<String, StreamController<AdPlaybackRule>> _ruleControllers = {};

  VideoAdsRepositoryFake(List<VideoAd> seed)
      : _ads = {for (final ad in seed) ad.id: ad} {
    for (final ad in seed) {
      _ruleControllers[ad.id] = StreamController<AdPlaybackRule>.broadcast();
      _ruleControllers[ad.id]!.add(AdPlaybackRule(ad.minWatchSeconds));
    }
  }

  @override
  Future<List<VideoAd>> fetchAds({String? category, String? region}) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return _ads.values
        .where((ad) => ad.isActiveNow)
        .where((ad) => category == null || ad.category == category)
        .where((ad) => region == null || ad.region == region)
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  @override
  Stream<AdPlaybackRule> getPlaybackRule(String adId) {
    return _ruleControllers[adId]!.stream;
  }

  @override
  Future<void> recordProgress(String adId, int watchedSeconds) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final current = _progressSecondsByAd[adId] ?? 0;
    _progressSecondsByAd[adId] = watchedSeconds > current ? watchedSeconds : current;
  }

  @override
  Future<void> submitRating(String adId, bool thumbsUp) async {
    await Future.delayed(const Duration(milliseconds: 120));
    // no-op for fake
  }

  @override
  Future<RewardResult> claimReward(String adId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final ad = _ads[adId];
    if (ad == null) {
      return const RewardResult(success: false, message: 'Ad not found', pointsAwarded: 0);
    }
    if (_rewardedAdIds.contains(adId)) {
      return const RewardResult(success: false, message: 'Already claimed', pointsAwarded: 0);
    }
    final progress = _progressSecondsByAd[adId] ?? 0;
    if (progress < ad.minWatchSeconds) {
      return RewardResult(success: false, message: 'Watch at least ${ad.minWatchSeconds}s', pointsAwarded: 0);
    }
    _rewardedAdIds.add(adId);
    return RewardResult(
      success: true,
      message: 'Reward granted',
      pointsAwarded: ad.rewardPoints,
      couponId: ad.rewardCouponId,
    );
  }

  @override
  Future<void> submitVote(String adId, bool thumbsUp) async {
    await Future.delayed(const Duration(milliseconds: 120));
  }
}



