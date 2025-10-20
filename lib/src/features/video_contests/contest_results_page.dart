import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../../models/contest_winner.dart';
import '../../providers/video_contest_provider.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';

class ContestResultsPage extends StatefulWidget {
  final String contestId;
  final String contestTitle;

  const ContestResultsPage({
    super.key,
    required this.contestId,
    required this.contestTitle,
  });

  @override
  State<ContestResultsPage> createState() => _ContestResultsPageState();
}

class _ContestResultsPageState extends State<ContestResultsPage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Trigger confetti after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContestWinnersProvider()..fetchWinners(widget.contestId),
      child: Scaffold(
        backgroundColor: AppColors.darkBgColor,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),
                Consumer<ContestWinnersProvider>(
                  builder: (context, provider, child) {
                    if (provider.loading) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (provider.error != null) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                provider.error!,
                                style: AppTextStyles.bodyTextStyle,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  provider.fetchWinners(widget.contestId);
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (provider.winners.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Text('No winners announced yet'),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final winner = provider.winners[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _WinnerCard(winner: winner),
                            );
                          },
                          childCount: provider.winners.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            
            // Confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 3.14 / 2, // down
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.1,
                colors: const [
                  Colors.amber,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: AppColors.darkBgColor,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Contest Winners',
          style: TextStyle(fontSize: 16),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.amber.withOpacity(0.5),
                AppColors.darkBgColor,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          Text(
            widget.contestTitle,
            style: AppTextStyles.headingTextStyle2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Congratulations to all winners!',
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

class _WinnerCard extends StatelessWidget {
  final ContestWinner winner;

  const _WinnerCard({required this.winner});

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(winner.rank);
    final rankBadge = _getRankBadge(winner.rank);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankColor, width: 2),
        boxShadow: winner.rank == 1
            ? [
                BoxShadow(
                  color: rankColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: rankColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(rankBadge, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  _getRankText(winner.rank),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video title
                Text(
                  winner.videoTitle,
                  style: AppTextStyles.tileTitleTextStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),

                // Creator info
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.lightGreyColor),
                    const SizedBox(width: 4),
                    Text(
                      winner.sellerName,
                      style: AppTextStyles.bodyTextStyle.copyWith(
                        color: AppColors.lightGreyColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  children: [
                    _buildStatChip(
                      Icons.how_to_vote,
                      '${winner.voteCount} Votes',
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      Icons.stars,
                      '${winner.rewardPoints} Points',
                      Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Reward distributed badge
                if (winner.rewardDistributed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Reward Distributed',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                // View video button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to video detail
                      // We'd need to fetch the video first or pass it differently
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Video playback coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Watch Video'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: const BorderSide(color: AppColors.primaryColor),
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

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade400;
      default:
        return AppColors.primaryColor;
    }
  }

  IconData _getRankBadge(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
      case 3:
        return Icons.military_tech;
      default:
        return Icons.star;
    }
  }

  String _getRankText(int rank) {
    switch (rank) {
      case 1:
        return '1st Place';
      case 2:
        return '2nd Place';
      case 3:
        return '3rd Place';
      default:
        return '${rank}th Place';
    }
  }
}

