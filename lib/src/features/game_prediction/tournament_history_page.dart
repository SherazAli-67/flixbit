import 'package:flixbit/src/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/wallet_models.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../service/tournament_history_service.dart';

/// Page showing user's complete tournament history with predictions vs actual results
class TournamentHistoryPage extends StatefulWidget {
  final String tournamentId;

  const TournamentHistoryPage({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentHistoryPage> createState() => _TournamentHistoryPageState();
}

class _TournamentHistoryPageState extends State<TournamentHistoryPage> {
  UserTournamentHistory? _history;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final history = await TournamentHistoryService.getUserTournamentHistory(
        userId: userId,
        tournamentId: widget.tournamentId,
      );

      setState(() {
        _history = history;
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
          'Tournament History',
          style: AppTextStyles.headingTextStyle3,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? LoadingWidget()
          : _error != null
              ? _buildErrorView()
              : _history == null
                  ? _buildEmptyView()
                  : _buildHistoryView(),
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
              'Error Loading History',
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
              onPressed: _loadHistory,
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
          Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.unSelectedGreyColor),
          const SizedBox(height: 16),
          Text(
            'No History Found',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t participated in this tournament yet',
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    final history = _history!;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament header
          _buildTournamentHeader(history, dateFormat),
          const SizedBox(height: 20),

          // Stats summary
          _buildStatsSummary(history),
          const SizedBox(height: 20),

          // Earnings breakdown
          _buildEarningsCard(history),
          const SizedBox(height: 20),

          // Predictions vs Results
          Text(
            'Predictions & Results',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          const SizedBox(height: 12),
          
          ...history.predictionResults.map((result) => _buildPredictionResultCard(result)),
        ],
      ),
    );
  }

  Widget _buildTournamentHeader(UserTournamentHistory history, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.2),
            AppColors.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            history.tournament.name,
            style: AppTextStyles.headingTextStyle3,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: AppColors.lightGreyColor),
              const SizedBox(width: 6),
              Text(
                '${dateFormat.format(history.tournament.startDate)} - ${dateFormat.format(history.tournament.endDate)}',
                style: AppTextStyles.captionTextStyle.copyWith(
                  color: AppColors.lightGreyColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.sports_soccer, size: 14, color: AppColors.lightGreyColor),
              const SizedBox(width: 6),
              Text(
                '${history.tournament.sportType} • ${history.predictionResults.length} predictions made',
                style: AppTextStyles.captionTextStyle.copyWith(
                  color: AppColors.lightGreyColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(UserTournamentHistory history) {
    final stats = history.stats;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Performance',
            style: AppTextStyles.tileTitleTextStyle,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Accuracy',
                  '${stats.accuracyPercentage.toStringAsFixed(0)}%',
                  stats.isQualified ? AppColors.greenColor : AppColors.primaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Correct',
                  '${stats.correctPredictions}/${stats.totalPredictions}',
                  AppColors.whiteColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Rank',
                  stats.rank != null ? '#${stats.rank}' : 'N/A',
                  AppColors.primaryColor,
                ),
              ),
            ],
          ),
          if (stats.isQualified) ...[
            const SizedBox(height: 12),
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
                  Icon(Icons.check_circle, color: AppColors.greenColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Qualified for Final Draw',
                    style: AppTextStyles.bodyTextStyle.copyWith(
                      color: AppColors.greenColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.tileTitleTextStyle.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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

  Widget _buildEarningsCard(UserTournamentHistory history) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.greenColor.withValues(alpha: 0.2),
            AppColors.greenColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.greenColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Earnings',
                style: AppTextStyles.tileTitleTextStyle,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.greenColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${history.totalEarnings} Points',
                  style: AppTextStyles.bodyTextStyle.copyWith(
                    color: AppColors.greenColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Earnings breakdown
          ...history.transactions
              .where((tx) => tx.type == TransactionType.earn)
              .map((tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                _getSourceIcon(tx.source),
                                size: 16,
                                color: AppColors.greenColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getSourceLabel(tx.source),
                                  style: AppTextStyles.bodyTextStyle.copyWith(
                                    color: AppColors.lightGreyColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${tx.amount.toInt()} pts',
                          style: AppTextStyles.bodyTextStyle.copyWith(
                            color: AppColors.greenColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _buildPredictionResultCard(PredictionResult result) {
    final dateFormat = DateFormat('MMM dd, HH:mm');
    final isCorrect = result.wasCorrect;
    final isExact = result.wasExactScore;
    final isPending = result.prediction.isCorrect == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? AppColors.unSelectedGreyColor.withValues(alpha: 0.3)
              : isCorrect
                  ? AppColors.greenColor.withValues(alpha: 0.3)
                  : AppColors.errorColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${result.match.homeTeam} vs ${result.match.awayTeam}',
                  style: AppTextStyles.tileTitleTextStyle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? AppColors.unSelectedGreyColor.withValues(alpha: 0.2)
                      : isCorrect
                          ? AppColors.greenColor.withValues(alpha: 0.2)
                          : AppColors.errorColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.resultText,
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: isPending
                        ? AppColors.unSelectedGreyColor
                        : isCorrect
                            ? AppColors.greenColor
                            : AppColors.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateFormat.format(result.match.matchDate),
            style: AppTextStyles.captionTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
          ),
          const Divider(height: 24, color: AppColors.unSelectedGreyColor),

          // Prediction vs Actual
          _buildComparisonRow(
            'Your Prediction',
            _getPredictionDisplay(result),
            Icons.person,
          ),
          const SizedBox(height: 8),
          _buildComparisonRow(
            'Actual Result',
            _getActualDisplay(result),
            Icons.sports_soccer,
          ),

          if (!isPending) ...[
            const Divider(height: 24, color: AppColors.unSelectedGreyColor),
            
            // Points earned
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isExact ? Icons.stars : Icons.emoji_events,
                      color: isCorrect ? AppColors.greenColor : AppColors.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isExact
                          ? 'Exact Score Bonus!'
                          : isCorrect
                              ? 'Points Earned'
                              : 'No Points',
                      style: AppTextStyles.bodyTextStyle.copyWith(
                        color: isCorrect ? AppColors.greenColor : AppColors.errorColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  isCorrect ? '+${result.pointsEarned} pts' : '0 pts',
                  style: AppTextStyles.tileTitleTextStyle.copyWith(
                    color: isCorrect ? AppColors.greenColor : AppColors.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.bodyTextStyle.copyWith(
            color: AppColors.lightGreyColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyTextStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _getPredictionDisplay(PredictionResult result) {
    final prediction = result.prediction;
    
    if (prediction.predictedHomeScore != null && prediction.predictedAwayScore != null) {
      return '${_getWinnerName(result, prediction.predictedWinner)} (${prediction.predictedHomeScore}-${prediction.predictedAwayScore})';
    } else {
      return _getWinnerName(result, prediction.predictedWinner);
    }
  }

  String _getActualDisplay(PredictionResult result) {
    final match = result.match;
    
    if (match.homeScore != null && match.awayScore != null) {
      return '${_getWinnerName(result, match.winner ?? 'pending')} (${match.homeScore}-${match.awayScore})';
    } else {
      return 'Pending';
    }
  }

  String _getWinnerName(PredictionResult result, String winner) {
    switch (winner) {
      case 'home':
        return result.match.homeTeam;
      case 'away':
        return result.match.awayTeam;
      case 'draw':
        return 'Draw';
      default:
        return 'Pending';
    }
  }

  IconData _getSourceIcon(TransactionSource source) {
    switch (source) {
      case TransactionSource.tournamentPrediction:
        return Icons.sports_soccer;
      case TransactionSource.tournamentQualification:
        return Icons.verified;
      case TransactionSource.tournamentWin:
        return Icons.emoji_events;
      default:
        return Icons.monetization_on;
    }
  }

  String _getSourceLabel(TransactionSource source) {
    switch (source) {
      case TransactionSource.tournamentPrediction:
        return 'Correct Predictions';
      case TransactionSource.tournamentQualification:
        return 'Qualification Bonus';
      case TransactionSource.tournamentWin:
        return 'Tournament Winner';
      default:
        return source.toString().split('.').last;
    }
  }
}

