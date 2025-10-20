import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../service/video_upload_service.dart';

class VideoUploadProvider extends ChangeNotifier {
  final VideoUploadService _uploadService = VideoUploadService();

  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;
  String? _uploadedVideoUrl;
  String? _uploadedThumbnailUrl;
  String? _uploadedVideoId;

  // Getters
  PlatformFile? get selectedFile => _selectedFile;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;
  String? get uploadedVideoUrl => _uploadedVideoUrl;
  String? get uploadedThumbnailUrl => _uploadedThumbnailUrl;
  String? get uploadedVideoId => _uploadedVideoId;
  bool get hasSelectedFile => _selectedFile != null;
  bool get isUploadComplete => _uploadedVideoUrl != null && !_isUploading;

  /// Pick video file
  Future<void> pickVideo() async {
    try {
      _error = null;
      notifyListeners();

      final file = await _uploadService.pickVideo();

      if (file != null) {
        _selectedFile = file;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear selected file
  void clearSelection() {
    _selectedFile = null;
    _error = null;
    _uploadProgress = 0.0;
    _uploadedVideoUrl = null;
    _uploadedThumbnailUrl = null;
    _uploadedVideoId = null;
    notifyListeners();
  }

  /// Upload video
  Future<bool> uploadVideo({
    required String sellerId,
    required String title,
    required String description,
    required int durationSeconds,
    required String category,
    required String region,
    DateTime? startAt,
    DateTime? endAt,
    required int rewardPoints,
    String? rewardCouponId,
    required int minWatchSeconds,
    bool contestEnabled = false,
    DateTime? voteWindowStart,
    DateTime? voteWindowEnd,
    double? sponsorshipAmount,
    Map<String, dynamic>? targetAudience,
    Map<String, dynamic>? creatorRewards,
  }) async {
    if (_selectedFile == null) {
      _error = 'No file selected';
      notifyListeners();
      return false;
    }

    try {
      _isUploading = true;
      _error = null;
      _uploadProgress = 0.0;
      notifyListeners();

      // Upload file to storage
      final result = await _uploadService.uploadToStorage(
        file: _selectedFile!,
        sellerId: sellerId,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      if (!result.success) {
        throw Exception(result.error ?? 'Upload failed');
      }

      _uploadedVideoUrl = result.videoUrl;
      _uploadedThumbnailUrl = result.thumbnailUrl;

      // Submit to Firestore for approval
      final videoId = await _uploadService.submitForApproval(
        sellerId: sellerId,
        title: title,
        description: description,
        videoUrl: result.videoUrl!,
        thumbnailUrl: result.thumbnailUrl,
        durationSeconds: durationSeconds,
        category: category,
        region: region,
        startAt: startAt,
        endAt: endAt,
        rewardPoints: rewardPoints,
        rewardCouponId: rewardCouponId,
        minWatchSeconds: minWatchSeconds,
        contestEnabled: contestEnabled,
        voteWindowStart: voteWindowStart,
        voteWindowEnd: voteWindowEnd,
        sponsorshipAmount: sponsorshipAmount,
        targetAudience: targetAudience,
        creatorRewards: creatorRewards,
      );

      _uploadedVideoId = videoId;
      _isUploading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset state
  void reset() {
    _selectedFile = null;
    _isUploading = false;
    _uploadProgress = 0.0;
    _error = null;
    _uploadedVideoUrl = null;
    _uploadedThumbnailUrl = null;
    _uploadedVideoId = null;
    notifyListeners();
  }
}

