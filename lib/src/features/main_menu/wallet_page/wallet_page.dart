import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flixbit/l10n/app_localizations.dart';
import 'package:flixbit/src/models/wallet_models.dart';
import 'package:flixbit/src/providers/wallet_provider.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/app_icons.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flixbit/src/widgets/loading_indicator.dart';
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  TransactionType? _selectedType;
  TransactionSource? _selectedSource;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    // Initialize wallet data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().initializeWallet('currentUser'); // Replace with actual user ID
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.wallet,
          style: AppTextStyles.headingTextStyle3,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.primaryColor),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          if (wallet.isLoading && wallet.balance == null) {
            return const Center(child: LoadingIndicator());
          }

          if (wallet.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    wallet.error!,
                    style: AppTextStyles.errorTextStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      wallet.clearError();
                      wallet.initializeWallet('currentUser'); // Replace with actual user ID
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            key: _refreshKey,
            onRefresh: () => wallet.refreshTransactions('currentUser'), // Replace with actual user ID
            child: CustomScrollView(
              slivers: [
                // User Profile Section
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileSection(wallet),
                      const SizedBox(height: 20),
                      _buildActionButtons(context),
                      const SizedBox(height: 20),
                      _buildBalanceCards(wallet),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Transactions Section Header
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.transactions,
                          style: AppTextStyles.subHeadingTextStyle,
                        ),
                        if (_selectedType != null || _selectedSource != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                if (_selectedType != null)
                                  _buildFilterChip(
                                    _selectedType.toString().split('.').last,
                                    () => setState(() => _selectedType = null),
                                  ),
                                if (_selectedSource != null)
                                  _buildFilterChip(
                                    _selectedSource.toString().split('.').last,
                                    () => setState(() => _selectedSource = null),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Transactions List
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: wallet.transactions.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              l10n.noTransactions,
                              style: AppTextStyles.bodyTextStyle,
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final filteredTransactions = wallet.getFilteredTransactions(
                                type: _selectedType,
                                source: _selectedSource,
                              );
                              
                              if (index >= filteredTransactions.length) {
                                return null;
                              }

                              final transaction = filteredTransactions[index];
                              return _buildTransactionItem(transaction);
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(WalletProvider wallet) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(AppIcons.icDummyProfileUrl),
              radius: 45,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.whiteColor,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Ethan Carter', // Replace with actual user name
          style: AppTextStyles.headingTextStyle3,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            child: PrimaryBtn(
              btnText: l10n.buy,
              icon: '',
              onTap: () => context.push(RouterEnum.buyFlixbitPointsView.routeName),
              borderRadius: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: PrimaryBtn(
              btnText: l10n.sell,
              icon: '',
              onTap: () {},
              borderRadius: 20,
              bgColor: AppColors.primaryColor.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCards(WalletProvider wallet) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildBalanceCard(
              title: l10n.flixbitBalance,
              amount: wallet.balance?.flixbitPoints ?? 0,
              currency: 'FLIXBIT',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildBalanceCard(
              title: l10n.tournamentPoints,
              amount: wallet.balance?.tournamentPoints ?? 0,
              currency: 'POINTS',
              onTap: () => _showConvertPointsDialog(wallet),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required num amount,
    required String currency,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat('#,##0').format(amount),
              style: AppTextStyles.headingTextStyle3,
            ),
            Text(
              currency,
              style: AppTextStyles.smallTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction) {
    final isPositive = [
      TransactionType.earn,
      TransactionType.buy,
      TransactionType.gift,
      TransactionType.reward,
      TransactionType.refund,
    ].contains(transaction.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPositive ? AppColors.successColor : AppColors.errorColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: AppColors.whiteColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTransactionTitle(transaction),
                  style: AppTextStyles.bodyTextStyle,
                ),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(transaction.timestamp),
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'}${NumberFormat('#,##0').format(transaction.amount)}',
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: isPositive ? AppColors.successColor : AppColors.errorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDelete,
      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
      labelStyle: AppTextStyles.smallTextStyle,
    );
  }

  String _getTransactionTitle(WalletTransaction transaction) {
    final l10n = AppLocalizations.of(context)!;
    switch (transaction.type) {
      case TransactionType.earn:
        return l10n.earned;
      case TransactionType.spend:
        return l10n.spent;
      case TransactionType.buy:
        return l10n.bought;
      case TransactionType.sell:
        return l10n.sold;
      case TransactionType.gift:
        return l10n.giftReceived;
      case TransactionType.reward:
        return l10n.rewardEarned;
      case TransactionType.refund:
        return l10n.refunded;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBgColor,
        title: Text(
          AppLocalizations.of(context)!.filterTransactions,
          style: AppTextStyles.headingTextStyle3,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.transactionType,
              style: AppTextStyles.bodyTextStyle,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TransactionType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.toString().split('.').last),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = selected ? type : null;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.source,
              style: AppTextStyles.bodyTextStyle,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TransactionSource.values.map((source) {
                return ChoiceChip(
                  label: Text(source.toString().split('.').last),
                  selected: _selectedSource == source,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSource = selected ? source : null;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedSource = null;
              });
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.clearAll),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  void _showConvertPointsDialog(WalletProvider wallet) {
    final tournamentPoints = wallet.balance?.tournamentPoints ?? 0;
    if (tournamentPoints == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noTournamentPoints),
        ),
      );
      return;
    }

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBgColor,
        title: Text(
          AppLocalizations.of(context)!.convertPoints,
          style: AppTextStyles.headingTextStyle3,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.convertPointsDescription,
              style: AppTextStyles.bodyTextStyle,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.pointsToConvert,
                suffixText: 'Points',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              final points = int.tryParse(controller.text);
              if (points == null || points <= 0 || points > tournamentPoints) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.invalidPointsAmount),
                  ),
                );
                return;
              }
              
              wallet.convertTournamentPoints('currentUser', points).then((_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.pointsConverted),
                  ),
                );
              }).catchError((error) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error.toString()),
                  ),
                );
              });
            },
            child: Text(AppLocalizations.of(context)!.convert),
          ),
        ],
      ),
    );
  }
}