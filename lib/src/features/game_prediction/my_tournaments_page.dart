import 'package:flixbit/src/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/tournament_model.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../service/tournament_history_service.dart';

/// Page showing list of all tournaments user has participated in
class MyTournamentsPage extends StatefulWidget {
  const MyTournamentsPage({super.key});

  @override
  State<MyTournamentsPage> createState() => _MyTournamentsPageState();
}

class _MyTournamentsPageState extends State<MyTournamentsPage> {
  List<TournamentSummary> _tournaments = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final tournaments = await TournamentHistoryService.getUserTournamentsList(userId);

      setState(() {
        _tournaments = tournaments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Tournaments',
          style: AppTextStyles.headingTextStyle3,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? LoadingWidget()
          : _error != null
              ? _buildErrorView()
              : _tournaments.isEmpty
                  ? _buildEmptyView()
                  : _buildTournamentsList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
            const SizedBox(height: 16),
            Text(
              'Error Loading Tournaments',
              style: AppTextStyles.subHeadingTextStyle,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTournaments,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: AppColors.unSelectedGreyColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Tournaments Yet',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Start predicting to see your tournament history',
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentsList() {
    return RefreshIndicator(
      onRefresh: _loadTournaments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tournaments.length,
        itemBuilder: (context, index) {
          final summary = _tournaments[index];
          return _buildTournamentCard(summary);
        },
      ),
    );
  }

  Widget _buildTournamentCard(TournamentSummary summary) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isCompleted = summary.tournament.status == TournamentStatus.completed;

    return GestureDetector(
      onTap: () {
        // Navigate to detailed history page
        // context.push('/tournament-history/${summary.tournament.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: summary.stats.isQualified
                ? AppColors.greenColor.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    summary.tournament.name,
                    style: AppTextStyles.tileTitleTextStyle,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(summary.tournament.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(summary.tournament.status),
                    style: AppTextStyles.captionTextStyle.copyWith(
                      color: _getStatusColor(summary.tournament.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tournament dates
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.lightGreyColor),
                const SizedBox(width: 6),
                Text(
                  '${dateFormat.format(summary.tournament.startDate)} - ${dateFormat.format(summary.tournament.endDate)}',
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Accuracy',
                    '${summary.stats.accuracyPercentage.toStringAsFixed(0)}%',
                    summary.stats.isQualified ? AppColors.greenColor : AppColors.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Predictions',
                    '${summary.stats.correctPredictions}/${summary.stats.totalPredictions}',
                    AppColors.whiteColor,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Earned',
                    '${summary.totalEarnings}',
                    AppColors.greenColor,
                  ),
                ),
              ],
            ),

            if (summary.stats.isQualified) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.greenColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.greenColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Qualified',
                      style: AppTextStyles.smallBoldTextStyle.copyWith(
                        color: AppColors.greenColor,
                      ),
                    ),
                    if (summary.stats.rank != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.emoji_events, color: AppColors.greenColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Rank #${summary.stats.rank}',
                        style: AppTextStyles.smallBoldTextStyle.copyWith(
                          color: AppColors.greenColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            if (isCompleted) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to detailed history
                      // context.push('/tournament-history/${summary.tournament.id}');
                    },
                    icon: Icon(Icons.visibility, size: 16, color: AppColors.primaryColor),
                    label: Text(
                      'View Details',
                      style: TextStyle(color: AppColors.primaryColor),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.bodyTextStyle.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.captionTextStyle.copyWith(
            color: AppColors.lightGreyColor,
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

