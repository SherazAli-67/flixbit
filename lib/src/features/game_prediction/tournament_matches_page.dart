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
          'Game Prediction',
          style: AppTextStyles.headingTextStyle3,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header (title card like the mock)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            color: AppColors.darkBgColor,
            child: Text(
              'Tournament Game',
              style: AppTextStyles.headingTextStyle3,
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
                        _matches.length == 1 ? 'Submit Prediction' : 'Submit All Predictions',
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          // Top card: round, game title, image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text('Round ${index + 1}', style: AppTextStyles.captionTextStyle.copyWith(color: AppColors.lightGreyColor)),
                    Text('Game ${index + 1}', style: AppTextStyles.subHeadingTextStyle),
                    Text(
                      '${match.homeTeam} vs. ${match.awayTeam}',
                      style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.lightGreyColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 88,
                  height: 72,
                  color: AppColors.darkGreyColor,
                  child: Image.asset(
                    'asset/images/referral_page_img.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),

          // Instruction text
          Text(
            "Select the team you think will win or choose 'Tie' if you predict a draw.",
            style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.lightGreyColor),
          ),

          // Radio-style options
          _optionTile(
            matchId: match.id,
            value: 'home',
            label: match.homeTeam,
            selected: selectedWinner == 'home',
          ),
          _optionTile(
            matchId: match.id,
            value: 'away',
            label: match.awayTeam,
            selected: selectedWinner == 'away',
          ),
          _optionTile(
            matchId: match.id,
            value: 'draw',
            label: 'Tie',
            selected: selectedWinner == 'draw',
          ),

          // Date/time footer like subtle caption
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: AppColors.unSelectedGreyColor),
              const SizedBox(width: 6),
              Text(
                '${dateFormat.format(match.matchDate)} • ${match.matchTime}',
                style: AppTextStyles.captionTextStyle.copyWith(color: AppColors.unSelectedGreyColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _optionTile({
    required String matchId,
    required String value,
    required String label,
    required bool selected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _predictions[matchId] = {
            'winner': value,
            'homeScore': 0,
            'awayScore': 0,
          };
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor.withValues(alpha: 0.2) : AppColors.darkBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.unSelectedGreyColor.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _radioDot(selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.tileTitleTextStyle.copyWith(
                  color: AppColors.whiteColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioDot({required bool selected}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.whiteColor : AppColors.unSelectedGreyColor,
          width: 2,
        ),
        color: selected ? AppColors.primaryColor : Colors.transparent,
      ),
      child: selected
          ? const Center(
              child: Icon(Icons.circle, size: 10, color: AppColors.whiteColor),
            )
          : null,
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
