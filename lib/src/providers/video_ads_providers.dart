import 'package:flutter/foundation.dart';

import '../models/video_ad.dart';
import '../service/video_ads_repository.dart';

VideoAdsRepository createSeededFakeRepository() {
  return VideoAdsRepositoryFake([
    VideoAd(
      id: 'ad-1',
      title: 'Cafe Latte - 20% Off',
      mediaUrl: 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
      thumbnailUrl: null,
      durationSeconds: 5,
      category: 'food',
      region: 'dubai',
      startAt: DateTime.now().subtract(const Duration(days: 1)),
      endAt: DateTime.now().add(const Duration(days: 30)),
      rewardPoints: 5,
      rewardCouponId: null,
      minWatchSeconds: 4,
      contestEnabled: true,
      voteWindowStart: DateTime.now().subtract(const Duration(days: 1)),
      voteWindowEnd: DateTime.now().add(const Duration(days: 6)),
    ),
    VideoAd(
      id: 'ad-2',
      title: 'Fitness Club Annual Pass',
      mediaUrl: 'https://samplelib.com/lib/preview/mp4/sample-10s.mp4',
      thumbnailUrl: null,
      durationSeconds: 10,
      category: 'fitness',
      region: 'karachi',
      startAt: DateTime.now().subtract(const Duration(days: 2)),
      endAt: DateTime.now().add(const Duration(days: 90)),
      rewardPoints: 10,
      rewardCouponId: 'coupon-20off-fitness',
      minWatchSeconds: 8,
      contestEnabled: false,
    ),
  ]);
}

class VideoAdsListProvider extends ChangeNotifier {
  final VideoAdsRepository repository;
  List<VideoAd> _ads = const [];
  bool _loading = false;
  String? _error;

  List<VideoAd> get ads => _ads;
  bool get loading => _loading;
  String? get error => _error;

  VideoAdsListProvider(this.repository);

  Future<void> load({String? category, String? region}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _ads = await repository.fetchAds(category: category, region: region);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

class RewardClaimProvider extends ChangeNotifier {
  final VideoAdsRepository repository;
  bool _claiming = false;
  RewardResult? _lastResult;
  String? _error;

  bool get claiming => _claiming;
  RewardResult? get lastResult => _lastResult;
  String? get error => _error;

  RewardClaimProvider(this.repository);

  Future<void> claim(String adId) async {
    _claiming = true;
    _error = null;
    notifyListeners();
    try {
      _lastResult = await repository.claimReward(adId);
      if (_lastResult?.success == false) {
        _error = _lastResult?.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _claiming = false;
      notifyListeners();
    }
  }
}

