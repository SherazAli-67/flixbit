import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/match_model.dart';
import '../../models/tournament_model.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../service/prediction_service.dart';

class MakePredictionPage extends StatefulWidget {
  final Match match;
  final Tournament tournament;
  
  const MakePredictionPage({
    super.key,
    required this.match,
    required this.tournament,
  });

  @override
  State<MakePredictionPage> createState() => _MakePredictionPageState();
}

class _MakePredictionPageState extends State<MakePredictionPage> {
  String? _selectedWinner; // 'home', 'away', or 'draw'
  int _homeScore = 0;
  int _awayScore = 0;
  bool _predictScore = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeUntilClose = widget.match.timeUntilClose;

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Make Prediction',
          style: AppTextStyles.headingTextStyle3,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 24,
          children: [
            // Match header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                spacing: 12,
                children: [
                  Text(
                    '${widget.match.homeTeam} vs ${widget.match.awayTeam}',
                    style: AppTextStyles.tileTitleTextStyle,
                    textAlign: TextAlign.center,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 6,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.unSelectedGreyColor,
                      ),
                      Text(
                        '${dateFormat.format(widget.match.matchDate)} • ${widget.match.matchTime}',
                        style: AppTextStyles.captionTextStyle.copyWith(
                          color: AppColors.unSelectedGreyColor,
                        ),
                      ),
                    ],
                  ),
                  if (timeUntilClose.inMinutes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: AppColors.primaryColor,
                          ),
                          Text(
                            'Closes in ${_formatDuration(timeUntilClose)}',
                            style: AppTextStyles.captionTextStyle.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Question
            Text(
              'Who will win?',
              style: AppTextStyles.subHeadingTextStyle,
            ),

            // Team selection cards
            _buildTeamCard(
              teamName: widget.match.homeTeam,
              value: 'home',
              icon: Icons.sports_soccer,
            ),

            _buildTeamCard(
              teamName: widget.match.awayTeam,
              value: 'away',
              icon: Icons.sports_soccer,
            ),

            _buildTeamCard(
              teamName: 'Draw',
              value: 'draw',
              icon: Icons.handshake,
            ),

            const Divider(height: 40),

            // Optional score prediction
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Predict Score (Optional)',
                  style: AppTextStyles.bodyTextStyle,
                ),
                Switch(
                  value: _predictScore,
                  onChanged: (value) {
                    setState(() => _predictScore = value);
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),

            if (_predictScore) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 24,
                children: [
                  // Home score
                  Column(
                    spacing: 12,
                    children: [
                      Text(
                        widget.match.homeTeam,
                        style: AppTextStyles.smallTextStyle,
                        textAlign: TextAlign.center,
                      ),
                      _buildScorePicker(
                        value: _homeScore,
                        onChanged: (value) {
                          setState(() => _homeScore = value);
                        },
                      ),
                    ],
                  ),

                  // Separator
                  Text(
                    '-',
                    style: AppTextStyles.headingTextStyle3.copyWith(
                      color: AppColors.lightGreyColor,
                    ),
                  ),

                  // Away score
                  Column(
                    spacing: 12,
                    children: [
                      Text(
                        widget.match.awayTeam,
                        style: AppTextStyles.smallTextStyle,
                        textAlign: TextAlign.center,
                      ),
                      _buildScorePicker(
                        value: _awayScore,
                        onChanged: (value) {
                          setState(() => _awayScore = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Points info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You will earn ${widget.tournament.pointsPerCorrectPrediction} Flixbit points if your prediction is correct',
                      style: AppTextStyles.smallTextStyle.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedWinner != null ? _submitPrediction : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.whiteColor,
                  disabledBackgroundColor: AppColors.unSelectedGreyColor.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Submit Prediction',
                  style: AppTextStyles.buttonTextStyle.copyWith(
                    color: _selectedWinner != null 
                        ? AppColors.whiteColor 
                        : AppColors.lightGreyColor,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Note
            Text(
              'Note: You can only submit one prediction per match. Once submitted, it cannot be changed.',
              style: AppTextStyles.captionTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard({
    required String teamName,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedWinner == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedWinner = value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryColor.withValues(alpha: 0.2) 
              : AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryColor 
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? AppColors.whiteColor 
                    : AppColors.primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                teamName,
                style: AppTextStyles.tileTitleTextStyle.copyWith(
                  color: isSelected 
                      ? AppColors.primaryColor 
                      : AppColors.whiteColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primaryColor,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorePicker({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      width: 120,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Decrease button
          Expanded(
            child: IconButton(
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: Icon(
                Icons.remove,
                color: value > 0 
                    ? AppColors.primaryColor 
                    : AppColors.unSelectedGreyColor,
              ),
            ),
          ),

          // Value
          Text(
            value.toString(),
            style: AppTextStyles.headingTextStyle3.copyWith(
              color: AppColors.primaryColor,
            ),
          ),

          // Increase button
          Expanded(
            child: IconButton(
              onPressed: value < 10 ? () => onChanged(value + 1) : null,
              icon: Icon(
                Icons.add,
                color: value < 10 
                    ? AppColors.primaryColor 
                    : AppColors.unSelectedGreyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitPrediction() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Confirm Prediction',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your prediction:',
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getPredictionText(),
              style: AppTextStyles.tileTitleTextStyle.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
            if (_predictScore) ...[
              const SizedBox(height: 8),
              Text(
                'Score: $_homeScore - $_awayScore',
                style: AppTextStyles.bodyTextStyle,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'You cannot change your prediction once submitted.',
              style: AppTextStyles.captionTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _savePrediction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.whiteColor,
            ),
            child: Text(
              'Confirm',
              style: AppTextStyles.buttonTextStyle.copyWith(
                color: AppColors.whiteColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePrediction() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        throw Exception('User not logged in');
      }

      // Submit prediction to Firebase
      await PredictionService.submitPrediction(
        userId: userId,
        tournamentId: widget.tournament.id,
        match: widget.match,
        predictedWinner: _selectedWinner!,
        predictedHomeScore: _predictScore ? _homeScore : null,
        predictedAwayScore: _predictScore ? _awayScore : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.whiteColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Prediction submitted successfully!',
                    style: AppTextStyles.bodyTextStyle.copyWith(
                      color: AppColors.whiteColor,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.greenColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Navigate back to matches page
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.redColor,
          ),
        );
      }
    }
  }

  String _getPredictionText() {
    switch (_selectedWinner) {
      case 'home':
        return '${widget.match.homeTeam} wins';
      case 'away':
        return '${widget.match.awayTeam} wins';
      case 'draw':
        return 'Match ends in a draw';
      default:
        return '';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
