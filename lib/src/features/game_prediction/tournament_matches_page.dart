import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/match_model.dart';
import '../../models/tournament_model.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../routes/router_enum.dart';
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
  String _selectedFilter = 'All'; // All, Upcoming, Completed

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final tournaments = TournamentService.getDummyTournaments();
    _tournament = tournaments.firstWhere((t) => t.id == widget.tournamentId);
    _matches = TournamentService.getDummyMatches(widget.tournamentId);
    setState(() {});
  }

  List<Match> get _filteredMatches {
    if (_selectedFilter == 'All') return _matches;
    if (_selectedFilter == 'Upcoming') {
      return _matches.where((m) => m.status == MatchStatus.upcoming).toList();
    }
    return _matches.where((m) => m.status == MatchStatus.completed).toList();
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
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              spacing: 12,
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Upcoming'),
                _buildFilterChip('Completed'),
              ],
            ),
          ),

          // Match list
          Expanded(
            child: _filteredMatches.isEmpty
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
                          'No matches found',
                          style: AppTextStyles.bodyTextStyle.copyWith(
                            color: AppColors.lightGreyColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredMatches.length,
                    itemBuilder: (context, index) {
                      return _buildMatchCard(_filteredMatches[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionTextStyle.copyWith(
            color: isSelected ? AppColors.whiteColor : AppColors.lightGreyColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isUpcoming = match.status == MatchStatus.upcoming;
    final isCompleted = match.status == MatchStatus.completed;
    
    // Calculate time until close
    Duration? timeUntilClose;
    if (isUpcoming && match.isPredictionOpen) {
      timeUntilClose = match.timeUntilClose;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUpcoming && match.isPredictionOpen
              ? AppColors.primaryColor.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          // Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMatchStatusColor(match.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getMatchStatusText(match.status),
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: _getMatchStatusColor(match.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (timeUntilClose != null && timeUntilClose.inMinutes > 0)
                Row(
                  spacing: 4,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: AppColors.primaryColor,
                    ),
                    Text(
                      _formatDuration(timeUntilClose),
                      style: AppTextStyles.captionTextStyle.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Teams
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.homeTeam,
                      style: AppTextStyles.smallBoldTextStyle,
                      textAlign: TextAlign.center,
                    ),
                    if (isCompleted && match.homeScore != null)
                      Text(
                        match.homeScore.toString(),
                        style: AppTextStyles.headingTextStyle3.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                  ],
                ),
              ),

              // VS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.awayTeam,
                      style: AppTextStyles.smallBoldTextStyle,
                      textAlign: TextAlign.center,
                    ),
                    if (isCompleted && match.awayScore != null)
                      Text(
                        match.awayScore.toString(),
                        style: AppTextStyles.headingTextStyle3.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(color: AppColors.unSelectedGreyColor),

          // Match info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 6,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
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

          Row(
            spacing: 6,
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.unSelectedGreyColor,
              ),
              Expanded(
                child: Text(
                  match.venue,
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: AppColors.unSelectedGreyColor,
                  ),
                ),
              ),
            ],
          ),

          // Action button
          if (isUpcoming && match.isPredictionOpen)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push(
                    RouterEnum.makePredictionView.routeName,
                    extra: {
                      'match': match,
                      'tournament': _tournament,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.whiteColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Make Prediction',
                  style: AppTextStyles.buttonTextStyle.copyWith(
                    color: AppColors.whiteColor,
                  ),
                ),
              ),
            )
          else if (isUpcoming && !match.isPredictionOpen)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.unSelectedGreyColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: AppColors.unSelectedGreyColor,
                  ),
                  Text(
                    'Prediction Closed',
                    style: AppTextStyles.smallTextStyle.copyWith(
                      color: AppColors.unSelectedGreyColor,
                    ),
                  ),
                ],
              ),
            )
          else if (isCompleted)
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
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.greenColor,
                  ),
                  Text(
                    'Match Completed',
                    style: AppTextStyles.smallTextStyle.copyWith(
                      color: AppColors.greenColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getMatchStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.upcoming:
        return AppColors.primaryColor;
      case MatchStatus.live:
        return Colors.red;
      case MatchStatus.completed:
        return AppColors.greenColor;
    }
  }

  String _getMatchStatusText(MatchStatus status) {
    switch (status) {
      case MatchStatus.upcoming:
        return 'Upcoming';
      case MatchStatus.live:
        return 'Live';
      case MatchStatus.completed:
        return 'Completed';
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
