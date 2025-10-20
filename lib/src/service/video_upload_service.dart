import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/video_ad.dart';
import '../models/video_analytics.dart';
import '../res/firebase_constants.dart';

class VideoUploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Maximum file size: 500MB
  static const int maxFileSizeBytes = 500 * 1024 * 1024;

  // Allowed video formats
  static const List<String> allowedExtensions = ['mp4', 'mov', 'avi'];

  /// Pick video from device
  Future<PlatformFile?> pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;

      // Validate file size
      if (file.size > maxFileSizeBytes) {
        throw Exception('File size exceeds 500MB limit');
      }

      // Validate extension
      final extension = path.extension(file.name).toLowerCase().replaceAll('.', '');
      if (!allowedExtensions.contains(extension)) {
        throw Exception('Invalid file format. Allowed: ${allowedExtensions.join(', ')}');
      }

      return file;
    } catch (e) {
      debugPrint('Error picking video: $e');
      rethrow;
    }
  }

  /// Validate video file
  bool validateVideo(PlatformFile file) {
    // Check size
    if (file.size > maxFileSizeBytes) {
      return false;
    }

    // Check extension
    final extension = path.extension(file.name).toLowerCase().replaceAll('.', '');
    return allowedExtensions.contains(extension);
  }

  /// Generate thumbnail from video
  Future<String?> generateThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 200,
        quality: 75,
      );

      return thumbnailPath;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Upload video to Firebase Storage
  Future<UploadResult> uploadToStorage({
    required PlatformFile file,
    required String sellerId,
    required Function(double progress) onProgress,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final storageRef = _storage.ref().child('videos/$sellerId/$fileName');

      UploadTask uploadTask;

      if (kIsWeb) {
        // Web upload
        if (file.bytes != null) {
          uploadTask = storageRef.putData(
            file.bytes!,
            SettableMetadata(contentType: 'video/${path.extension(file.name).replaceAll('.', '')}'),
          );
        } else {
          throw Exception('No file data available for web upload');
        }
      } else {
        // Mobile/Desktop upload
        if (file.path == null) {
          throw Exception('No file path available');
        }
        final videoFile = File(file.path!);
        uploadTask = storageRef.putFile(videoFile);
      }

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Upload thumbnail if available
      String? thumbnailUrl;
      if (!kIsWeb && file.path != null) {
        final thumbnailPath = await generateThumbnail(file.path!);
        if (thumbnailPath != null) {
          thumbnailUrl = await _uploadThumbnail(thumbnailPath, sellerId, fileName);
        }
      }

      return UploadResult(
        success: true,
        videoUrl: downloadUrl,
        thumbnailUrl: thumbnailUrl,
        fileName: fileName,
      );
    } catch (e) {
      debugPrint('Error uploading video: $e');
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Upload thumbnail to Storage
  Future<String?> _uploadThumbnail(String thumbnailPath, String sellerId, String videoFileName) async {
    try {
      final thumbnailFile = File(thumbnailPath);
      final thumbnailRef = _storage.ref().child('thumbnails/$sellerId/${videoFileName}_thumb.png');

      final uploadTask = thumbnailRef.putFile(thumbnailFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading thumbnail: $e');
      return null;
    }
  }

  /// Submit video for admin approval
  Future<String> submitForApproval({
    required String sellerId,
    required String title,
    required String description,
    required String videoUrl,
    String? thumbnailUrl,
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
    try {
      final now = DateTime.now();
      final videoRef = _firestore.collection(FirebaseConstants.videoAdsCollection).doc();

      final videoAd = VideoAd(
        id: videoRef.id,
        title: title,
        description: description,
        mediaUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
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
        uploadedBy: sellerId,
        approvalStatus: ApprovalStatus.pending,
        sponsorshipAmount: sponsorshipAmount,
        targetAudience: targetAudience,
        creatorRewards: creatorRewards,
        createdAt: now,
        updatedAt: now,
      );

      await videoRef.set(videoAd.toFirestore());

      // Initialize analytics document
      final analyticsRef = _firestore
          .collection(FirebaseConstants.videoAnalyticsCollection)
          .doc(videoRef.id);

      final analytics = VideoAnalytics(
        id: videoRef.id,
        videoId: videoRef.id,
        lastUpdated: now,
      );

      await analyticsRef.set(analytics.toFirestore());

      return videoRef.id;
    } catch (e) {
      debugPrint('Error submitting video for approval: $e');
      rethrow;
    }
  }

  /// Get video upload status
  Future<VideoUploadData?> getUploadStatus(String uploadId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.videoUploadsCollection)
          .doc(uploadId)
          .get();

      if (!doc.exists) return null;

      return VideoUploadData.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error getting upload status: $e');
      return null;
    }
  }

  /// Delete video from storage and Firestore
  Future<bool> deleteVideo(String videoId) async {
    try {
      // Get video document
      final videoDoc = await _firestore
          .collection(FirebaseConstants.videoAdsCollection)
          .doc(videoId)
          .get();

      if (!videoDoc.exists) {
        throw Exception('Video not found');
      }

      final videoData = videoDoc.data()!;
      final videoUrl = videoData['mediaUrl'] as String;
      final thumbnailUrl = videoData['thumbnailUrl'] as String?;

      // Delete from Storage
      try {
        final videoRef = _storage.refFromURL(videoUrl);
        await videoRef.delete();
      } catch (e) {
        debugPrint('Error deleting video file: $e');
      }

      if (thumbnailUrl != null) {
        try {
          final thumbnailRef = _storage.refFromURL(thumbnailUrl);
          await thumbnailRef.delete();
        } catch (e) {
          debugPrint('Error deleting thumbnail: $e');
        }
      }

      // Delete from Firestore
      await _firestore
          .collection(FirebaseConstants.videoAdsCollection)
          .doc(videoId)
          .delete();

      // Delete analytics
      await _firestore
          .collection(FirebaseConstants.videoAnalyticsCollection)
          .doc(videoId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting video: $e');
      return false;
    }
  }
}

class UploadResult {
  final bool success;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final String? error;

  const UploadResult({
    required this.success,
    this.videoUrl,
    this.thumbnailUrl,
    this.fileName,
    this.error,
  });
}

