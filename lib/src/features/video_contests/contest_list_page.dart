import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/video_contest.dart';
import '../../providers/video_contest_provider.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../routes/router_enum.dart';

class ContestListPage extends StatefulWidget {
  const ContestListPage({super.key});

  @override
  State<ContestListPage> createState() => _ContestListPageState();
}

class _ContestListPageState extends State<ContestListPage> {
  String? _selectedCategory;
  String? _selectedRegion;

  final List<String> _categories = [
    'All',
    'Food & Dining',
    'Fitness & Sports',
    'Entertainment',
    'Electronics',
    'Fashion',
    'Travel',
  ];

  final List<String> _regions = [
    'All',
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Riyadh',
    'Jeddah',
    'Karachi',
    'Lahore',
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VideoContestProvider()..fetchActiveContests(),
      child: Scaffold(
        backgroundColor: AppColors.darkBgColor,
        appBar: AppBar(
          backgroundColor: AppColors.darkBgColor,
          elevation: 0,
          title: const Text('Video Contests'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
            ),
          ],
        ),
        body: Consumer<VideoContestProvider>(
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
                    Text(
                      provider.error!,
                      style: AppTextStyles.bodyTextStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.fetchActiveContests(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (provider.contests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_off,
                      size: 64,
                      color: AppColors.unSelectedGreyColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active contests',
                      style: AppTextStyles.bodyTextStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new contests',
                      style: AppTextStyles.smallTextStyle.copyWith(
                        color: AppColors.lightGreyColor,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.fetchActiveContests(
                category: _selectedCategory == 'All' ? null : _selectedCategory,
                region: _selectedRegion == 'All' ? null : _selectedRegion,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.contests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final contest = provider.contests[index];
                  return _ContestCard(contest: contest);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: const Text('Filter Contests', style: AppTextStyles.headingTextStyle3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory ?? 'All',
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: AppTextStyles.bodyTextStyle,
                filled: true,
                fillColor: AppColors.darkBgColor,
              ),
              style: AppTextStyles.bodyTextStyle,
              dropdownColor: AppColors.darkBgColor,
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value == 'All' ? null : value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRegion ?? 'All',
              decoration: InputDecoration(
                labelText: 'Region',
                labelStyle: AppTextStyles.bodyTextStyle,
                filled: true,
                fillColor: AppColors.darkBgColor,
              ),
              style: AppTextStyles.bodyTextStyle,
              dropdownColor: AppColors.darkBgColor,
              items: _regions.map((reg) {
                return DropdownMenuItem(value: reg, child: Text(reg));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedRegion = value == 'All' ? null : value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<VideoContestProvider>().fetchActiveContests(
                    category: _selectedCategory,
                    region: _selectedRegion,
                  );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _ContestCard extends StatelessWidget {
  final VideoContest contest;

  const _ContestCard({required this.contest});

  @override
  Widget build(BuildContext context) {
    final timeRemaining = _getTimeRemaining();
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();

    return InkWell(
      onTap: () {
        context.push(
          RouterEnum.contestDetailView.routeName,
          extra: {'contestId': contest.id},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: contest.isFeatured ? AppColors.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (contest.isFeatured)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Featured Contest',
                      style: AppTextStyles.smallTextStyle.copyWith(
                        color: Colors.white,
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
                  // Title
                  Text(
                    contest.title,
                    style: AppTextStyles.tileTitleTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    contest.description,
                    style: AppTextStyles.bodyTextStyle.copyWith(
                      color: AppColors.lightGreyColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.people,
                        '${contest.totalParticipants} Videos',
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Icons.how_to_vote,
                        '${contest.totalVotes} Votes',
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Icons.emoji_events,
                        'Top ${contest.maxWinners}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Rewards section
                  if (contest.rewardIds.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          size: 16,
                          color: AppColors.successColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Win ${contest.rewardIds.length} reward${contest.rewardIds.length > 1 ? 's' : ''}!',
                            style: AppTextStyles.smallTextStyle.copyWith(
                              color: AppColors.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showRewardsPreview(context, contest.rewardIds),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'View Rewards',
                            style: AppTextStyles.smallTextStyle.copyWith(
                              color: AppColors.successColor,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Status and Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: AppTextStyles.smallTextStyle.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (timeRemaining != null)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppColors.lightGreyColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeRemaining,
                              style: AppTextStyles.smallTextStyle.copyWith(
                                color: AppColors.lightGreyColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.smallTextStyle.copyWith(
            color: AppColors.whiteColor,
          ),
        ),
      ],
    );
  }

  String? _getTimeRemaining() {
    final now = DateTime.now();

    if (contest.isUpcoming) {
      final diff = contest.startDate.difference(now);
      return 'Starts in ${_formatDuration(diff)}';
    }

    if (contest.isVotingOpen) {
      final diff = contest.voteWindowEnd.difference(now);
      return 'Ends in ${_formatDuration(diff)}';
    }

    return null;
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Soon';
    }
  }

  Color _getStatusColor() {
    if (contest.isUpcoming) return Colors.blue;
    if (contest.isVotingOpen) return Colors.green;
    if (contest.winnersAnnounced) return Colors.amber;
    return Colors.grey;
  }

  String _getStatusText() {
    if (contest.isUpcoming) return 'Upcoming';
    if (contest.isVotingOpen) return 'Voting Open';
    if (contest.winnersAnnounced) return 'Winners Announced';
    return 'Ended';
  }

  void _showRewardsPreview(BuildContext context, List<String> rewardIds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: Text(
          'Contest Rewards',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(
              'Win these rewards by participating in this contest!',
              style: AppTextStyles.smallTextStyle,
              textAlign: TextAlign.center,
            ),
            ...rewardIds.map((rewardId) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkBgColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.card_giftcard,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reward #${rewardId.substring(0, 8)}',
                      style: AppTextStyles.smallTextStyle,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Close',
              style: AppTextStyles.smallTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              context.push(RouterEnum.rewardsView.routeName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.whiteColor,
            ),
            child: const Text('Browse All Rewards'),
          ),
        ],
      ),
    );
  }
}

