import 'package:flutter/material.dart';
import '../../../models/tournament_model.dart';
import '../../../models/match_model.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';
import '../../../service/enhanced_tournament_service.dart';
import '../../../service/prediction_service.dart';
import 'package:intl/intl.dart';

class ScoreUpdateView extends StatefulWidget {
  final List<Tournament> tournaments;

  const ScoreUpdateView({super.key, required this.tournaments});

  @override
  State<ScoreUpdateView> createState() => _ScoreUpdateViewState();
}

class _ScoreUpdateViewState extends State<ScoreUpdateView> {
  Tournament? _selectedTournament;
  List<Match> _matches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tournaments.isNotEmpty) {
      _selectedTournament = widget.tournaments.first;
      _loadMatches();
    }
  }

  Future<void> _loadMatches() async {
    if (_selectedTournament == null) return;

    setState(() => _isLoading = true);
    try {
      final allMatches = await EnhancedTournamentService.getTournamentMatches(
        _selectedTournament!.id,
      );
      
      // Filter to show only live and completed matches
      setState(() {
        _matches = allMatches
            .where((m) =>
                m.status == MatchStatus.live ||
                m.status == MatchStatus.completed)
            .toList();
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

  @override
  Widget build(BuildContext context) {
    if (widget.tournaments.isEmpty) {
      return _buildEmptyState('Create a tournament first');
    }

    return Column(
      children: [
        // Tournament Selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderColor.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text('Select Tournament', style: AppTextStyles.smallBoldTextStyle),
              DropdownButtonFormField<Tournament>(
                value: _selectedTournament,
                items: widget.tournaments.map((tournament) {
                  return DropdownMenuItem(
                    value: tournament,
                    child: Text(
                      tournament.name,
                      style: AppTextStyles.bodyTextStyle,
                    ),
                  );
                }).toList(),
                onChanged: (tournament) {
                  setState(() => _selectedTournament = tournament);
                  _loadMatches();
                },
                style: AppTextStyles.bodyTextStyle,
                dropdownColor: AppColors.cardBgColor,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputFieldBgColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.borderColor),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderColor.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Update scores for completed matches to distribute points to users',
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Matches List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _matches.isEmpty
                  ? _buildEmptyState(
                      'No live or completed matches.\nMatches appear here after they start.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _matches.length,
                      itemBuilder: (context, index) {
                        return _ScoreUpdateCard(
                          tournament: _selectedTournament!,
                          match: _matches[index],
                          onScoreUpdated: _loadMatches,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.scoreboard_outlined,
            size: 80,
            color: AppColors.unSelectedGreyColor,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ==================== SCORE UPDATE CARD ====================
class _ScoreUpdateCard extends StatefulWidget {
  final Tournament tournament;
  final Match match;
  final VoidCallback onScoreUpdated;

  const _ScoreUpdateCard({
    required this.tournament,
    required this.match,
    required this.onScoreUpdated,
  });

  @override
  State<_ScoreUpdateCard> createState() => _ScoreUpdateCardState();
}

class _ScoreUpdateCardState extends State<_ScoreUpdateCard> {
  late int _homeScore;
  late int _awayScore;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _homeScore = widget.match.homeScore ?? 0;
    _awayScore = widget.match.awayScore ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isCompleted = widget.match.status == MatchStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.completedStatusColor.withValues(alpha: 0.3)
              : AppColors.liveStatusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          // Match Info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      '${widget.match.homeTeam} vs ${widget.match.awayTeam}',
                      style: AppTextStyles.tileTitleTextStyle,
                    ),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 12, color: AppColors.unSelectedGreyColor),
                        const SizedBox(width: 4),
                        Text(
                          '${dateFormat.format(widget.match.matchDate)} • ${widget.match.matchTime}',
                          style: AppTextStyles.captionTextStyle.copyWith(
                            color: AppColors.unSelectedGreyColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(widget.match.status),
            ],
          ),

          // Score Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputFieldBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              spacing: 16,
              children: [
                Text('Final Score', style: AppTextStyles.smallBoldTextStyle),
                Row(
                  children: [
                    // Home Team Score
                    Expanded(
                      child: Column(
                        spacing: 8,
                        children: [
                          Text(
                            widget.match.homeTeam,
                            style: AppTextStyles.captionTextStyle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          _buildScorePicker(
                            value: _homeScore,
                            onChanged: (v) => setState(() => _homeScore = v),
                            enabled: !isCompleted,
                          ),
                        ],
                      ),
                    ),

                    // Separator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '-',
                        style: AppTextStyles.headingTextStyle3.copyWith(
                          color: AppColors.lightGreyColor,
                        ),
                      ),
                    ),

                    // Away Team Score
                    Expanded(
                      child: Column(
                        spacing: 8,
                        children: [
                          Text(
                            widget.match.awayTeam,
                            style: AppTextStyles.captionTextStyle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          _buildScorePicker(
                            value: _awayScore,
                            onChanged: (v) => setState(() => _awayScore = v),
                            enabled: !isCompleted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Button
          if (isCompleted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.completedStatusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.completedStatusColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: AppColors.completedStatusColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Match finalized. Points distributed.',
                      style: AppTextStyles.smallTextStyle.copyWith(
                        color: AppColors.completedStatusColor,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _finalizeMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.whiteColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Finalize Match & Distribute Points'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScorePicker({
    required int value,
    required ValueChanged<int> onChanged,
    required bool enabled,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: enabled ? AppColors.cardBgColor : AppColors.darkGreyColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Decrease
          Expanded(
            child: IconButton(
              onPressed: enabled && value > 0 ? () => onChanged(value - 1) : null,
              icon: Icon(
                Icons.remove,
                color: enabled && value > 0
                    ? AppColors.primaryColor
                    : AppColors.unSelectedGreyColor,
              ),
            ),
          ),

          // Value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              value.toString(),
              style: AppTextStyles.headingTextStyle3.copyWith(
                color: enabled ? AppColors.primaryColor : AppColors.unSelectedGreyColor,
              ),
            ),
          ),

          // Increase
          Expanded(
            child: IconButton(
              onPressed: enabled && value < 20 ? () => onChanged(value + 1) : null,
              icon: Icon(
                Icons.add,
                color: enabled && value < 20
                    ? AppColors.primaryColor
                    : AppColors.unSelectedGreyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MatchStatus status) {
    Color color;
    String label;

    switch (status) {
      case MatchStatus.upcoming:
        color = AppColors.upcomingStatusColor;
        label = 'Upcoming';
        break;
      case MatchStatus.live:
        color = AppColors.liveStatusColor;
        label = 'Live';
        break;
      case MatchStatus.completed:
        color = AppColors.completedStatusColor;
        label = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionTextStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _finalizeMatch() async {
    // Get prediction stats first to show impact
    final stats = await PredictionService.getMatchPredictionStats(widget.match.id);
    final totalPredictions = stats['total'] ?? 0;

    if (totalPredictions == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No predictions submitted for this match'),
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Finalize Match?',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              'Final Score: $_homeScore - $_awayScore',
              style: AppTextStyles.tileTitleTextStyle.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Impact Preview',
                        style: AppTextStyles.smallBoldTextStyle.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '• $totalPredictions users will be evaluated',
                    style: AppTextStyles.captionTextStyle.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                  Text(
                    '• Points will be awarded automatically',
                    style: AppTextStyles.captionTextStyle.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                  Text(
                    '• User stats will be updated',
                    style: AppTextStyles.captionTextStyle.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                  Text(
                    '• Notifications will be sent',
                    style: AppTextStyles.captionTextStyle.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: AppTextStyles.captionTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.lightGreyColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.whiteColor,
            ),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);

    try {
      // Finalize match (this triggers prediction evaluation)
      await EnhancedTournamentService.finalizeMatch(
        tournamentId: widget.tournament.id,
        matchId: widget.match.id,
        homeScore: _homeScore,
        awayScore: _awayScore,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Match finalized! Points distributed to $totalPredictions users.',
            ),
            backgroundColor: AppColors.greenColor,
            duration: const Duration(seconds: 4),
          ),
        );
        widget.onScoreUpdated();
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
      if (mounted) setState(() => _isUpdating = false);
    }
  }
}

