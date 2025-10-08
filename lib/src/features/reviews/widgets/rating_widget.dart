import 'package:flutter/material.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';

class RatingWidget extends StatefulWidget {
  final double initialRating;
  final bool isInteractive;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Function(double)? onRatingChanged;
  final bool showLabel;
  final String? label;

  const RatingWidget({
    super.key,
    this.initialRating = 0.0,
    this.isInteractive = false,
    this.size = 20.0,
    this.activeColor,
    this.inactiveColor,
    this.onRatingChanged,
    this.showLabel = false,
    this.label,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  void didUpdateWidget(RatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _currentRating = widget.initialRating;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: widget.isInteractive ? () => _onStarTapped(index + 1) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Icon(
                  _getStarIcon(index),
                  size: widget.size,
                  color: _getStarColor(index),
                ),
              ),
            );
          }),
        ),
        if (widget.showLabel && widget.label != null) ...[
          const SizedBox(width: 8),
          Text(
            widget.label!,
            style: AppTextStyles.smallTextStyle.copyWith(
              color: AppColors.unSelectedGreyColor,
            ),
          ),
        ],
      ],
    );
  }

  IconData _getStarIcon(int index) {
    if (_currentRating >= index + 1) {
      return Icons.star;
    } else if (_currentRating > index) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  Color _getStarColor(int index) {
    final activeColor = widget.activeColor ?? AppColors.primaryColor;
    final inactiveColor = widget.inactiveColor ?? AppColors.unSelectedGreyColor;
    
    if (_currentRating >= index + 1) {
      return activeColor;
    } else if (_currentRating > index) {
      return activeColor;
    } else {
      return inactiveColor;
    }
  }

  void _onStarTapped(int rating) {
    setState(() {
      _currentRating = rating.toDouble();
    });
    widget.onRatingChanged?.call(_currentRating);
  }
}

class RatingDisplayWidget extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final double size;
  final bool showReviewCount;
  final bool showBadges;
  final List<String> badges;

  const RatingDisplayWidget({
    super.key,
    required this.rating,
    this.totalReviews = 0,
    this.size = 16.0,
    this.showReviewCount = true,
    this.showBadges = false,
    this.badges = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingWidget(
          initialRating: rating,
          size: size,
          showLabel: false,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.smallTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.whiteColor,
          ),
        ),
        if (showReviewCount && totalReviews > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($totalReviews)',
            style: AppTextStyles.captionTextStyle.copyWith(
              color: AppColors.unSelectedGreyColor,
            ),
          ),
        ],
        if (showBadges && badges.isNotEmpty) ...[
          const SizedBox(width: 8),
          ...badges.take(2).map((badge) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                badge,
                style: AppTextStyles.captionTextStyle.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 10,
                ),
              ),
            ),
          )),
        ],
      ],
    );
  }
}

class RatingDistributionWidget extends StatelessWidget {
  final Map<int, int> ratingDistribution;
  final int totalReviews;

  const RatingDistributionWidget({
    super.key,
    required this.ratingDistribution,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    if (totalReviews == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating Distribution',
          style: AppTextStyles.smallTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(5, (index) {
          final rating = 5 - index;
          final count = ratingDistribution[rating] ?? 0;
          final percentage = totalReviews > 0 ? (count / totalReviews) * 100 : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(
                  '$rating',
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: AppColors.unSelectedGreyColor,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.star,
                  size: 12,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppColors.cardBgColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor.withValues(alpha: 0.3),
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: AppColors.unSelectedGreyColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
