import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/match_model.dart';
import '../../models/tournament_model.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../service/tournament_service.dart';

class TournamentMatchesPage extends StatefulWidget {
  final String tournamentId;
  
  const TournamentMatchesPage({super.key, required this.tournamentId});

  @override
  State<TournamentMatchesPage> createState() => _TournamentMatchesPageState();
}

class _TournamentMatchesPageState extends State<TournamentMatchesPage> {
  Tournament? _tournament;
  List<Match> _matches = [];
  
  // Store predictions: matchId -> {'winner': 'home'/'away'/'draw', 'homeScore': 0, 'awayScore': 0}
  final Map<String, Map<String, dynamic>> _predictions = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final tournaments = TournamentService.getDummyTournaments();
    _tournament = tournaments.firstWhere((t) => t.id == widget.tournamentId);
    _matches = TournamentService.getDummyMatches(widget.tournamentId)
        .where((m) => m.status == MatchStatus.upcoming && m.isPredictionOpen)
        .toList();
    setState(() {});
  }

  int get _completedPredictions {
    return _predictions.values.where((p) => p['winner'] != null).length;
  }

  bool get _canSubmit {
    return _completedPredictions == _matches.length && _matches.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_tournament == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _tournament!.name,
          style: AppTextStyles.headingTextStyle3,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBgColor,
            child: Column(
              spacing: 8,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prediction Contest',
                      style: AppTextStyles.subHeadingTextStyle,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_completedPredictions/${_matches.length}',
                        style: AppTextStyles.smallBoldTextStyle.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_matches.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _completedPredictions / _matches.length,
                      minHeight: 4,
                      backgroundColor: AppColors.unSelectedGreyColor.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                  ),
              ],
            ),
          ),

          // Quiz Questions
          Expanded(
            child: _matches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          size: 64,
                          color: AppColors.unSelectedGreyColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No upcoming matches available',
                          style: AppTextStyles.bodyTextStyle.copyWith(
                            color: AppColors.lightGreyColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new matches',
                          style: AppTextStyles.captionTextStyle.copyWith(
                            color: AppColors.unSelectedGreyColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _matches.length,
                    itemBuilder: (context, index) {
                      return _buildQuizQuestion(index, _matches[index]);
                    },
                  ),
          ),

          // Submit Button
          if (_matches.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                spacing: 12,
                children: [
                  if (!_canSubmit)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 8,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.lightGreyColor,
                        ),
                        Text(
                          'Please complete all predictions to submit',
                          style: AppTextStyles.captionTextStyle.copyWith(
                            color: AppColors.lightGreyColor,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _submitAllPredictions : null,
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
                        'Submit All Predictions',
                        style: AppTextStyles.buttonTextStyle.copyWith(
                          color: _canSubmit ? AppColors.whiteColor : AppColors.lightGreyColor,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizQuestion(int index, Match match) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final prediction = _predictions[match.id];
    final selectedWinner = prediction?['winner'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedWinner != null
              ? AppColors.primaryColor.withValues(alpha: 0.5)
              : AppColors.unSelectedGreyColor.withValues(alpha: 0.2),
          width: selectedWinner != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          // Question number and match info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Match ${index + 1}',
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selectedWinner != null)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
            ],
          ),

          // Teams Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Home team
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_soccer,
                        color: AppColors.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.homeTeam,
                      style: AppTextStyles.smallBoldTextStyle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // VS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'VS',
                  style: AppTextStyles.tileTitleTextStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),
              ),

              // Away team
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_soccer,
                        color: AppColors.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.awayTeam,
                      style: AppTextStyles.smallBoldTextStyle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Match details
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              Row(
                spacing: 4,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: AppColors.unSelectedGreyColor,
                  ),
                  Text(
                    '${dateFormat.format(match.matchDate)} • ${match.matchTime}',
                    style: AppTextStyles.captionTextStyle.copyWith(
                      color: AppColors.unSelectedGreyColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Divider(color: AppColors.unSelectedGreyColor, height: 24),

          // Question
          Text(
            'Who will win?',
            style: AppTextStyles.bodyTextStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          // Team selection options
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: _buildTeamOption(
                  match.id,
                  'home',
                  match.homeTeam,
                  selectedWinner == 'home',
                ),
              ),
              Expanded(
                child: _buildTeamOption(
                  match.id,
                  'draw',
                  'Draw',
                  selectedWinner == 'draw',
                ),
              ),
              Expanded(
                child: _buildTeamOption(
                  match.id,
                  'away',
                  match.awayTeam,
                  selectedWinner == 'away',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamOption(String matchId, String value, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _predictions[matchId] = {
            'winner': value,
            'homeScore': 0,
            'awayScore': 0,
          };
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.2)
              : AppColors.darkBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.unSelectedGreyColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Icon(
              value == 'draw' ? Icons.handshake : Icons.sports_soccer,
              color: isSelected ? AppColors.primaryColor : AppColors.lightGreyColor,
              size: 24,
            ),
            Text(
              label,
              style: AppTextStyles.captionTextStyle.copyWith(
                color: isSelected ? AppColors.primaryColor : AppColors.lightGreyColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primaryColor,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  void _submitAllPredictions() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Submit Predictions?',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to submit predictions for ${_matches.length} matches.',
              style: AppTextStyles.bodyTextStyle,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can earn up to ${_matches.length * (_tournament?.pointsPerCorrectPrediction ?? 10)} Flixbit points!',
                      style: AppTextStyles.captionTextStyle.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Note: Predictions cannot be changed once submitted.',
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
              _savePredictions();
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

  void _savePredictions() {
    // TODO: Save predictions to Firebase
    // For now, just show success message
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.whiteColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_matches.length} predictions submitted successfully!',
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

    // Navigate back
    Navigator.pop(context);
  }
}
