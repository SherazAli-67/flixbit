import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tournament_model.dart';
import '../models/user_tournament_stats.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';
import '../service/tournament_service.dart';

class GamePredicationPage extends StatefulWidget {
  const GamePredicationPage({super.key});

  @override
  State<GamePredicationPage> createState() => _GamePredicationPageState();
}

class _GamePredicationPageState extends State<GamePredicationPage> {
  List<Tournament> _tournaments = [];
  Map<String, UserTournamentStats> _userStats = {};

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  void _loadTournaments() {
    setState(() {
      _tournaments = TournamentService.getDummyTournaments();
      _userStats = TournamentService.getDummyUserStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    const Text(
                      'Game Predictions',
                      style: AppTextStyles.headingTextStyle3,
                    ),
                    Text(
                      'Predict match outcomes and win prizes',
                      style: AppTextStyles.bodyTextStyle.copyWith(
                        color: AppColors.lightGreyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Active Tournaments
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(
                  'Active Tournaments',
                  style: AppTextStyles.subHeadingTextStyle,
                ),
              ),
            ),

            // Tournament List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tournament = _tournaments[index];
                    final stats = _userStats[tournament.id];
                    
                    return _buildTournamentCard(tournament, stats);
                  },
                  childCount: _tournaments.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentCard(Tournament tournament, UserTournamentStats? stats) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isOngoing = tournament.status == TournamentStatus.ongoing;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOngoing 
              ? AppColors.primaryColor.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          // Header with status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tournament.name,
                  style: AppTextStyles.tileTitleTextStyle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(tournament.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(tournament.status),
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: _getStatusColor(tournament.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Description
          Text(
            tournament.description,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.lightGreyColor,
              fontSize: 13,
            ),
          ),

          // Tournament Info
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.unSelectedGreyColor,
              ),
              const SizedBox(width: 6),
              Text(
                '${dateFormat.format(tournament.startDate)} - ${dateFormat.format(tournament.endDate)}',
                style: AppTextStyles.captionTextStyle.copyWith(
                  color: AppColors.unSelectedGreyColor,
                ),
              ),
            ],
          ),

          Row(
            children: [
              Icon(
                Icons.sports_soccer,
                size: 14,
                color: AppColors.unSelectedGreyColor,
              ),
              const SizedBox(width: 6),
              Text(
                '${tournament.totalMatches} matches',
                style: AppTextStyles.captionTextStyle.copyWith(
                  color: AppColors.unSelectedGreyColor,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.emoji_events,
                size: 14,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tournament.prizeDescription,
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: AppColors.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Divider
          const Divider(
            color: AppColors.unSelectedGreyColor,
            height: 24,
          ),

          // User Stats
          if (stats != null) ...[ 
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Accuracy',
                    '${stats.accuracyPercentage.toStringAsFixed(0)}%',
                    stats.accuracyPercentage >= tournament.qualificationThreshold * 100
                        ? AppColors.greenColor
                        : AppColors.primaryColor,
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.unSelectedGreyColor,
                ),
                Expanded(
                  child: _buildStatItem(
                    'Points',
                    '${stats.totalPointsEarned}/${tournament.totalMatches * tournament.pointsPerCorrectPrediction}',
                    AppColors.primaryColor,
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.unSelectedGreyColor,
                ),
                Expanded(
                  child: _buildStatItem(
                    'Predictions',
                    '${stats.totalPredictions}/${tournament.totalMatches}',
                    AppColors.whiteColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Qualification Progress',
                      style: AppTextStyles.captionTextStyle.copyWith(
                        color: AppColors.lightGreyColor,
                      ),
                    ),
                    Text(
                      'Need ${(tournament.qualificationThreshold * 100).toInt()}%',
                      style: AppTextStyles.captionTextStyle.copyWith(
                        color: stats.isQualified 
                            ? AppColors.greenColor 
                            : AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.accuracyPercentage / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.unSelectedGreyColor.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      stats.isQualified ? AppColors.greenColor : AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Qualification Status or Action Button
            if (stats.isQualified)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.greenColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.greenColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.greenColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Qualified for Final Draw!',
                        style: AppTextStyles.smallBoldTextStyle.copyWith(
                          color: AppColors.greenColor,
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
                  onPressed: () {
                    // Navigate to matches
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.whiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'View Matches',
                    style: AppTextStyles.buttonTextStyle.copyWith(
                      color: AppColors.whiteColor,
                    ),
                  ),
                ),
              ),
          ] else ...[
            // No stats - user hasn't started
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to matches
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.whiteColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Start Predicting',
                  style: AppTextStyles.buttonTextStyle.copyWith(
                    color: AppColors.whiteColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      spacing: 4,
      children: [
        Text(
          label,
          style: AppTextStyles.captionTextStyle.copyWith(
            color: AppColors.lightGreyColor,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.tileTitleTextStyle.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.upcoming:
        return Colors.blue;
      case TournamentStatus.ongoing:
        return AppColors.primaryColor;
      case TournamentStatus.completed:
        return AppColors.greenColor;
    }
  }

  String _getStatusText(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.upcoming:
        return 'Upcoming';
      case TournamentStatus.ongoing:
        return 'Live';
      case TournamentStatus.completed:
        return 'Completed';
    }
  }
}
