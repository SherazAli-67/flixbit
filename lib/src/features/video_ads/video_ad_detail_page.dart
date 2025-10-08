import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flixbit/src/models/video_ad.dart';
import 'package:flixbit/src/features/reviews/write_review_page.dart';
import 'package:flixbit/src/models/review_model.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/apptextstyles.dart';

class VideoAdDetailPage extends StatefulWidget {
  final VideoAd ad;
  final String? sellerId; // optional seller link
  const VideoAdDetailPage({super.key, required this.ad, this.sellerId});

  @override
  State<VideoAdDetailPage> createState() => _VideoAdDetailPageState();
}

class _VideoAdDetailPageState extends State<VideoAdDetailPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.ad.mediaUrl));
    await _controller.initialize();
    _controller.addListener(_videoListener);
    setState(() {
      _isInitialized = true;
    });
    _controller.play();
  }

  void _videoListener() {
    if (!_controller.value.isInitialized) return;
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    if (!_hasCompleted && duration.inMilliseconds > 0 && position >= duration) {
      _hasCompleted = true;
      _onVideoCompleted(widget.sellerId ?? '', widget.ad.id);
    }
  }

  // After video completion
  void _onVideoCompleted(String sellerId, String videoId) {
    // Show review prompt
    _showVideoReviewPrompt(sellerId, videoId);
  }

  void _showVideoReviewPrompt(String sellerId, String videoId) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBgColor,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was this video?', style: AppTextStyles.bodyTextStyle),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WriteReviewPage(
                            sellerId: sellerId,
                            sellerName: 'Seller', // optional; replace when available
                            verificationMethod: 'video_watch',
                            reviewType: ReviewType.videoAd,
                          ),
                        ),
                      );
                    },
                    child: const Text('Rate Video'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
        title: Text(widget.ad.title, style: AppTextStyles.subHeadingTextStyle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: _isInitialized ? _controller.value.aspectRatio : 16 / 9,
            child: _isInitialized
                ? Stack(
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[
                      VideoPlayer(_controller),
                      _ControlsOverlay(controller: _controller),
                      VideoProgressIndicator(_controller, allowScrubbing: true),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.ad.title, style: AppTextStyles.bodyTextStyle.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('${widget.ad.durationSeconds}s • ${widget.ad.category ?? ''}', style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.unSelectedGreyColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
          child: Container(color: Colors.transparent),
        ),
        Align(
          alignment: Alignment.center,
          child: Icon(
            controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: Colors.white.withValues(alpha: 0.8),
            size: 64,
          ),
        ),
      ],
    );
  }
}