import 'package:flutter/material.dart';
import '../../../models/tournament_model.dart';
import '../../../models/user_tournament_stats.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';
import '../../../service/enhanced_tournament_service.dart';

class AnalyticsView extends StatefulWidget {
  final List<Tournament> tournaments;

  const AnalyticsView({super.key, required this.tournaments});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  Tournament? _selectedTournament;
  Map<String, dynamic> _stats = {};
  List<UserTournamentStats> _leaderboard = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tournaments.isNotEmpty) {
      _selectedTournament = widget.tournaments.first;
      _loadAnalytics();
    }
  }

  Future<void> _loadAnalytics() async {
    if (_selectedTournament == null) return;

    setState(() => _isLoading = true);
    try {
      final stats = await EnhancedTournamentService.getTournamentStats(
        _selectedTournament!.id,
      );
      final leaderboard = await EnhancedTournamentService.getLeaderboard(
        tournamentId: _selectedTournament!.id,
        limit: 10,
      );

      setState(() {
        _stats = stats;
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tournaments.isEmpty) {
      return _buildEmptyState('Create a tournament to view analytics');
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
              Row(
                children: [
                  Expanded(
                    child: Text('Tournament Analytics',
                        style: AppTextStyles.tileTitleTextStyle),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: AppColors.primaryColor),
                    onPressed: _loadAnalytics,
                  ),
                ],
              ),
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
                  _loadAnalytics();
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

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 20,
                    children: [
                      // Overview Stats
                      _buildOverviewSection(),

                      // Leaderboard
                      _buildLeaderboardSection(),

                      // Qualified Users
                      _buildQualifiedUsersSection(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOverviewSection() {
    final totalParticipants = _stats['totalParticipants'] ?? 0;
    final activeParticipants = _stats['activeParticipants'] ?? 0;
    final qualifiedUsers = _stats['qualifiedUsers'] ?? 0;
    final averageAccuracy = (_stats['averageAccuracy'] ?? 0.0) as double;
    final totalPredictions = _stats['totalPredictions'] ?? 0;
    final totalPointsAwarded = _stats['totalPointsAwarded'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text('Overview', style: AppTextStyles.tileTitleTextStyle),
        
        // Stats Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              icon: Icons.people,
              label: 'Total Participants',
              value: totalParticipants.toString(),
              color: AppColors.primaryColor,
            ),
            _buildStatCard(
              icon: Icons.person_add,
              label: 'Active Users',
              value: activeParticipants.toString(),
              color: AppColors.lightGreenColor,
            ),
            _buildStatCard(
              icon: Icons.emoji_events,
              label: 'Qualified Users',
              value: qualifiedUsers.toString(),
              color: AppColors.orangeColor,
            ),
            _buildStatCard(
              icon: Icons.trending_up,
              label: 'Avg. Accuracy',
              value: '${averageAccuracy.toStringAsFixed(1)}%',
              color: AppColors.lightBlueColor,
            ),
            _buildStatCard(
              icon: Icons.assignment_turned_in,
              label: 'Total Predictions',
              value: totalPredictions.toString(),
              color: AppColors.purpleColor,
            ),
            _buildStatCard(
              icon: Icons.star,
              label: 'Points Awarded',
              value: totalPointsAwarded.toString(),
              color: AppColors.vibrantBlueColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.headingTextStyle3.copyWith(
                  color: color,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.captionTextStyle.copyWith(
                  color: AppColors.lightGreyColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    if (_leaderboard.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text('Top 10 Leaderboard', style: AppTextStyles.tileTitleTextStyle),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text('Rank',
                          style: AppTextStyles.smallBoldTextStyle),
                    ),
                    Expanded(
                      child: Text('User',
                          style: AppTextStyles.smallBoldTextStyle),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text('Accuracy',
                          style: AppTextStyles.smallBoldTextStyle,
                          textAlign: TextAlign.center),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text('Points',
                          style: AppTextStyles.smallBoldTextStyle,
                          textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
              // List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _leaderboard.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.borderColor.withValues(alpha: 0.3),
                ),
                itemBuilder: (context, index) {
                  final stat = _leaderboard[index];
                  final rank = index + 1;
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    color: rank <= 3
                        ? _getRankColor(rank).withValues(alpha: 0.05)
                        : null,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: _buildRankBadge(rank),
                        ),
                        Expanded(
                          child: Text(
                            'User ${stat.userId.substring(0, 8)}...',
                            style: AppTextStyles.bodyTextStyle,
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            '${stat.accuracyPercentage.toStringAsFixed(1)}%',
                            style: AppTextStyles.smallBoldTextStyle.copyWith(
                              color: stat.isQualified
                                  ? AppColors.greenColor
                                  : AppColors.lightGreyColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${stat.totalPointsEarned}',
                            style: AppTextStyles.bodyTextStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _getRankColor(rank).withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            rank == 1
                ? Icons.workspace_premium
                : rank == 2
                    ? Icons.stars
                    : Icons.star,
            color: _getRankColor(rank),
            size: 20,
          ),
        ),
      );
    }
    return Center(
      child: Text(
        '#$rank',
        style: AppTextStyles.smallBoldTextStyle.copyWith(
          color: AppColors.lightGreyColor,
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.orangeColor; // Gold
      case 2:
        return AppColors.lightGreyColor; // Silver
      case 3:
        return AppColors.lightBlueColor; // Bronze
      default:
        return AppColors.unSelectedGreyColor;
    }
  }

  Widget _buildQualifiedUsersSection() {
    final qualifiedUsers = _stats['qualifiedUsers'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text('Qualified Users', style: AppTextStyles.tileTitleTextStyle),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            spacing: 12,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.greenColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.check_circle,
                        color: AppColors.greenColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$qualifiedUsers Users Qualified',
                          style: AppTextStyles.tileTitleTextStyle.copyWith(
                            color: AppColors.greenColor,
                          ),
                        ),
                        Text(
                          'Eligible for prize draw',
                          style: AppTextStyles.captionTextStyle.copyWith(
                            color: AppColors.lightGreyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_selectedTournament?.status == TournamentStatus.completed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to prize distribution page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Prize distribution coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('Distribute Prizes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenColor,
                      foregroundColor: AppColors.whiteColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
            ],
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
            Icons.analytics_outlined,
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

