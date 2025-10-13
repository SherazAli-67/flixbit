import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/match_model.dart';
import '../../models/tournament_model.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../service/enhanced_tournament_service.dart';
import '../../service/prediction_service.dart';

class TournamentMatchesPage extends StatefulWidget {
  final String tournamentId;
  
  const TournamentMatchesPage({super.key, required this.tournamentId});

  @override
  State<TournamentMatchesPage> createState() => _TournamentMatchesPageState();
}

class _TournamentMatchesPageState extends State<TournamentMatchesPage> {
  Tournament? _tournament;
  List<Match> _matches = [];
  bool _isLoading = false;
  
  // Store NEW predictions: matchId -> {'winner': 'home'/'away'/'draw', 'homeScore': 0, 'awayScore': 0}
  final Map<String, Map<String, dynamic>> _predictions = {};
  
  // Store EXISTING predictions from Firebase (already submitted)
  final Map<String, Map<String, dynamic>> _existingPredictions = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load tournament
      final tournament = await EnhancedTournamentService.getTournament(widget.tournamentId);
      
      if (tournament == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tournament not found')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Load matches (only upcoming with open predictions)
      final allMatches = await EnhancedTournamentService.getTournamentMatches(widget.tournamentId);
      final openMatches = allMatches
          .where((m) => m.status == MatchStatus.upcoming && m.isPredictionOpen)
          .toList();

      // Load existing predictions for this user
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isNotEmpty) {
        for (var match in openMatches) {
          final hasPredicted = await PredictionService.hasPredicted(
            userId: userId,
            matchId: match.id,
          );
          
          if (hasPredicted) {
            // Get the existing prediction details
            final predictions = await PredictionService.getUserPredictions(
              userId: userId,
              tournamentId: widget.tournamentId,
            );
            
            final matchPredictions = predictions.where((p) => p.matchId == match.id);
            if (matchPredictions.isNotEmpty) {
              final matchPrediction = matchPredictions.first;
              _existingPredictions[match.id] = {
                'winner': matchPrediction.predictedWinner,
                'homeScore': matchPrediction.predictedHomeScore,
                'awayScore': matchPrediction.predictedAwayScore,
                'submittedAt': matchPrediction.submittedAt,
              };
            }
          }
        }
      }

      setState(() {
        _tournament = tournament;
        _matches = openMatches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading matches: $e')),
        );
      }
    }
  }

  int get _newPredictionsCount {
    // Only count new predictions (not already submitted)
    return _predictions.entries
        .where((entry) => !_existingPredictions.containsKey(entry.key))
        .where((entry) => entry.value['winner'] != null)
        .length;
  }
  
  int get _unpredictedMatchesCount {
    // Count matches without any prediction (new or existing)
    return _matches.where((m) => 
      !_predictions.containsKey(m.id) && 
      !_existingPredictions.containsKey(m.id)
    ).length;
  }

  bool get _canSubmit {
    return _newPredictionsCount > 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tournament == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBgColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
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
                  // Info message
                  if (_unpredictedMatchesCount > 0 && _newPredictionsCount == 0)
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
                          'Select winners for $_unpredictedMatchesCount remaining matches',
                          style: AppTextStyles.captionTextStyle.copyWith(
                            color: AppColors.lightGreyColor,
                          ),
                        ),
                      ],
                    )
                  else if (_newPredictionsCount > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 8,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: AppColors.greenColor,
                        ),
                        Text(
                          '$_newPredictionsCount new predictions ready to submit',
                          style: AppTextStyles.captionTextStyle.copyWith(
                            color: AppColors.greenColor,
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
                        _newPredictionsCount == 1 
                            ? 'Submit $_newPredictionsCount Prediction'
                            : 'Submit $_newPredictionsCount Predictions',
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
    
    // Check if this match has an existing submitted prediction
    final hasExistingPrediction = _existingPredictions.containsKey(match.id);
    
    // Determine which prediction to show
    String? selectedWinner;
    if (hasExistingPrediction) {
      selectedWinner = _existingPredictions[match.id]?['winner'] as String?;
    } else {
      selectedWinner = _predictions[match.id]?['winner'] as String?;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasExistingPrediction 
            ? AppColors.cardBgColor.withValues(alpha: 0.5)
            : AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: hasExistingPrediction 
            ? Border.all(color: AppColors.greenColor.withValues(alpha: 0.3), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          // Top card: round, game title, image, status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Row(
                      children: [
                        Text('Round ${index + 1}', 
                            style: AppTextStyles.captionTextStyle.copyWith(
                              color: AppColors.lightGreyColor)),
                        if (hasExistingPrediction) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.greenColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, 
                                    size: 12, color: AppColors.greenColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Submitted',
                                  style: AppTextStyles.captionTextStyle.copyWith(
                                    color: AppColors.greenColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text('Game ${index + 1}', style: AppTextStyles.subHeadingTextStyle),
                    Text(
                      '${match.homeTeam} vs. ${match.awayTeam}',
                      style: AppTextStyles.smallTextStyle.copyWith(
                        color: AppColors.lightGreyColor),
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

          // Instruction text or locked message
          if (hasExistingPrediction)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greenColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, size: 16, color: AppColors.greenColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Prediction locked. You cannot change it after submission.',
                      style: AppTextStyles.captionTextStyle.copyWith(
                        color: AppColors.greenColor,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              "Select the team you think will win or choose 'Tie' if you predict a draw.",
              style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.lightGreyColor),
            ),

          // Radio-style options (disabled if already predicted)
          _optionTile(
            matchId: match.id,
            value: 'home',
            label: match.homeTeam,
            selected: selectedWinner == 'home',
            disabled: hasExistingPrediction,
          ),
          _optionTile(
            matchId: match.id,
            value: 'away',
            label: match.awayTeam,
            selected: selectedWinner == 'away',
            disabled: hasExistingPrediction,
          ),
          _optionTile(
            matchId: match.id,
            value: 'draw',
            label: 'Tie',
            selected: selectedWinner == 'draw',
            disabled: hasExistingPrediction,
          ),

          // Date/time footer
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
    bool disabled = false,
  }) {
    return InkWell(
      onTap: disabled ? null : () {
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
          color: disabled && selected
              ? AppColors.greenColor.withValues(alpha: 0.15)
              : selected
                  ? AppColors.primaryColor.withValues(alpha: 0.2)
                  : AppColors.darkBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled && selected
                ? AppColors.greenColor
                : selected
                    ? AppColors.primaryColor
                    : AppColors.unSelectedGreyColor.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _radioDot(
              selected: selected, 
              disabled: disabled,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.tileTitleTextStyle.copyWith(
                  color: disabled
                      ? AppColors.lightGreyColor
                      : AppColors.whiteColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (disabled && selected)
              Icon(
                Icons.check_circle,
                color: AppColors.greenColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _radioDot({
    required bool selected, 
    bool disabled = false,
  }) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: disabled && selected
              ? AppColors.greenColor
              : selected
                  ? AppColors.whiteColor
                  : AppColors.unSelectedGreyColor,
          width: 2,
        ),
        color: disabled && selected
            ? AppColors.greenColor
            : selected
                ? AppColors.primaryColor
                : Colors.transparent,
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
              'You are about to submit $_newPredictionsCount new ${_newPredictionsCount == 1 ? "prediction" : "predictions"}.',
              style: AppTextStyles.bodyTextStyle,
            ),
            if (_existingPredictions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${_existingPredictions.length} ${_existingPredictions.length == 1 ? "prediction" : "predictions"} already submitted earlier.',
                style: AppTextStyles.captionTextStyle.copyWith(
                  color: AppColors.lightGreyColor,
                ),
              ),
            ],
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
                      'You can earn up to ${_newPredictionsCount * (_tournament?.pointsPerCorrectPrediction ?? 10)} Flixbit points!',
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

  Future<void> _savePredictions() async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        throw Exception('User not logged in');
      }

      int submittedCount = 0;

      // Submit only NEW predictions (not already submitted)
      for (var entry in _predictions.entries) {
        final matchId = entry.key;
        
        // Skip if this match already has a submitted prediction
        if (_existingPredictions.containsKey(matchId)) {
          continue;
        }
        
        final prediction = entry.value;
        final match = _matches.firstWhere((m) => m.id == matchId);

        await PredictionService.submitPrediction(
          userId: userId,
          tournamentId: widget.tournamentId,
          match: match,
          predictedWinner: prediction['winner'] as String,
          predictedHomeScore: prediction['homeScore'] as int?,
          predictedAwayScore: prediction['awayScore'] as int?,
        );
        
        submittedCount++;
      }

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
                    '$submittedCount ${submittedCount == 1 ? "prediction" : "predictions"} submitted successfully!',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.redColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
