import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../models/video_contest.dart';
import '../../models/video_ad.dart';
import '../../providers/video_contest_provider.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../routes/router_enum.dart';

class ContestDetailPage extends StatefulWidget {
  final String contestId;

  const ContestDetailPage({
    super.key,
    required this.contestId,
  });

  @override
  State<ContestDetailPage> createState() => _ContestDetailPageState();
}

class _ContestDetailPageState extends State<ContestDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _countdownTimer;
  String _remainingTime = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          // Timer will update the countdown in the UI
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return ChangeNotifierProvider(
      create: (_) => ContestDetailProvider()..loadContest(widget.contestId, userId),
      child: Scaffold(
        backgroundColor: AppColors.darkBgColor,
        body: Consumer<ContestDetailProvider>(
          builder: (context, provider, child) {
            if (provider.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(provider.error!, style: AppTextStyles.bodyTextStyle),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        provider.loadContest(widget.contestId, userId);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (provider.contest == null) {
              return const Center(child: Text('Contest not found'));
            }

            final contest = provider.contest!;
            _updateRemainingTime(contest);

            return CustomScrollView(
              slivers: [
                _buildAppBar(contest),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildContestInfo(contest, provider),
                      _buildTabBar(),
                    ],
                  ),
                ),
                _buildTabContent(provider, userId, contest),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(VideoContest contest) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.darkBgColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          contest.title,
          style: AppTextStyles.headingTextStyle3.copyWith(fontSize: 16),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryColor.withOpacity(0.5),
                AppColors.darkBgColor,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.emoji_events,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContestInfo(VideoContest contest, ContestDetailProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contest.description,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.videocam,
                '${provider.videos.length}',
                'Videos',
              ),
              _buildStatItem(
                Icons.how_to_vote,
                '${contest.totalVotes}',
                'Votes',
              ),
              _buildStatItem(
                Icons.emoji_events,
                '${contest.maxWinners}',
                'Winners',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Countdown Timer
          if (contest.isVotingOpen)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voting ends in',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                        Text(
                          _remainingTime,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Already voted notice
          if (provider.hasVoted)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'You have voted in this contest',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headingTextStyle3.copyWith(fontSize: 20),
        ),
        Text(
          label,
          style: AppTextStyles.smallTextStyle.copyWith(
            color: AppColors.lightGreyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.cardBgColor,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: AppColors.lightGreyColor,
        indicatorColor: AppColors.primaryColor,
        tabs: const [
          Tab(text: 'Videos'),
          Tab(text: 'Leaderboard'),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    ContestDetailProvider provider,
    String userId,
    VideoContest contest,
  ) {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildVideosTab(provider, userId, contest),
          _buildLeaderboardTab(provider),
        ],
      ),
    );
  }

  Widget _buildVideosTab(
    ContestDetailProvider provider,
    String userId,
    VideoContest contest,
  ) {
    if (provider.videos.isEmpty) {
      return const Center(
        child: Text('No videos in this contest yet'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final video = provider.videos[index];
        final isVoted = provider.userVotedVideoId == video.id;

        return _VideoCard(
          video: video,
          isVoted: isVoted,
          canVote: contest.isVotingOpen && !provider.hasVoted,
          onVote: () async {
            final success = await provider.submitVote(
              contestId: widget.contestId,
              videoId: video.id,
              userId: userId,
            );

            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vote submitted successfully!')),
              );
            } else if (!success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(provider.error ?? 'Failed to submit vote')),
              );
            }
          },
          onPlay: () {
            context.push(
              RouterEnum.videoDetailsView.routeName,
              extra: {'ad': video},
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboardTab(ContestDetailProvider provider) {
    if (provider.leaderboard.isEmpty) {
      return const Center(
        child: Text('No votes yet'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.leaderboard.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = provider.leaderboard[index];
        return _LeaderboardCard(entry: entry);
      },
    );
  }

  void _updateRemainingTime(VideoContest contest) {
    if (!contest.isVotingOpen) {
      _remainingTime = '';
      return;
    }

    final now = DateTime.now();
    final diff = contest.voteWindowEnd.difference(now);

    if (diff.isNegative) {
      _remainingTime = 'Ended';
      return;
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (days > 0) {
      _remainingTime = '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      _remainingTime = '${hours}h ${minutes}m ${seconds}s';
    } else {
      _remainingTime = '${minutes}m ${seconds}s';
    }
  }
}

class _VideoCard extends StatelessWidget {
  final VideoAd video;
  final bool isVoted;
  final bool canVote;
  final VoidCallback onVote;
  final VoidCallback onPlay;

  const _VideoCard({
    required this.video,
    required this.isVoted,
    required this.canVote,
    required this.onVote,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: isVoted
            ? Border.all(color: Colors.blue, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail
          GestureDetector(
            onTap: onPlay,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.darkBgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (video.thumbnailUrl != null)
                    Image.network(
                      video.thumbnailUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  if (isVoted)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Your Vote',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: AppTextStyles.tileTitleTextStyle,
                ),
                if (video.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    video.description!,
                    style: AppTextStyles.bodyTextStyle.copyWith(
                      color: AppColors.lightGreyColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.lightGreyColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${video.durationSeconds}s',
                          style: AppTextStyles.smallTextStyle.copyWith(
                            color: AppColors.lightGreyColor,
                          ),
                        ),
                      ],
                    ),

                    if (canVote && !isVoted)
                      ElevatedButton.icon(
                        onPressed: onVote,
                        icon: const Icon(Icons.how_to_vote, size: 20),
                        label: const Text('Vote'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final dynamic entry; // ContestLeaderboardEntry

  const _LeaderboardCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(entry.rank);
    final rankIcon = _getRankIcon(entry.rank);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: entry.rank <= 3
            ? Border.all(color: rankColor, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rankIcon != null
                  ? Icon(rankIcon, color: rankColor, size: 24)
                  : Text(
                      '#${entry.rank}',
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Video info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.videoTitle,
                  style: AppTextStyles.tileTitleTextStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${entry.uploadedBy}',
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),
              ],
            ),
          ),

          // Vote count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.how_to_vote, size: 16, color: AppColors.primaryColor),
                const SizedBox(width: 4),
                Text(
                  '${entry.voteCount}',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
        return AppColors.lightGreyColor;
    }
  }

  IconData? _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
      case 3:
        return Icons.military_tech;
      default:
        return null;
    }
  }
}

