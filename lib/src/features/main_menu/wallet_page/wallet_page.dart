import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flixbit/src/helpers/format_helper.dart';
import 'package:flixbit/src/helpers/message_display_helper.dart';
import 'package:flixbit/src/service/wallet_service.dart';
import 'package:flixbit/src/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flixbit/l10n/app_localizations.dart';
import 'package:flixbit/src/models/wallet_models.dart';
import 'package:flixbit/src/providers/wallet_provider.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/app_icons.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  TransactionType? _selectedType;
  TransactionSource? _selectedSource;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  String userID = FirebaseAuth.instance.currentUser!.uid;
  @override
  void initState() {
    super.initState();
    // Initialize wallet data
    WidgetsBinding.instance.addPostFrameCallback((_) =>  context.read<WalletProvider>().initializeWallet());
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
        title: Text(l10n.wallet, style: AppTextStyles.headingTextStyle3,),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.primaryColor),
            onPressed: () =>
                DisplayMessageHelper.showFilterDialog(
                    context,
                    selectedType: _selectedType,
                    selectedSource: _selectedSource,
                    onTransactionTypeSelected: (selected, type) =>  setState(()=> _selectedType = selected ? type : null),
                    onTransactionSourceSelected: (selected, source) => setState(()=> _selectedSource = selected ? source : null),
                  onClearTap: (){
                    setState(() {
                      _selectedType = null;
                      _selectedSource = null;
                    });
                  }
                ),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          if (wallet.isLoading && wallet.balance == null) {
            return LoadingWidget();
          }

          if (wallet.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16,
                children: [
                  Text(wallet.error!, style: AppTextStyles.errorTextStyle, textAlign: TextAlign.center,),
                  ElevatedButton(
                    onPressed: () {
                      wallet.clearError();
                      wallet.initializeWallet(); // Replace with actual user ID
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            key: _refreshKey,
            onRefresh: () => wallet.refreshTransactions(userID), // Replace with actual user ID
            child: CustomScrollView(
              slivers: [
                // User Profile Section
                SliverToBoxAdapter(
                  child: Column(
                    spacing: 20,
                    children: [
                      _buildProfileSection(wallet),
                      _buildActionButtons(context),
                      _buildBalanceCards(wallet),
                      _buildPointsBreakdown(wallet),
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
                        Text(l10n.transactions, style: AppTextStyles.subHeadingTextStyle,),
                        if (_selectedType != null || _selectedSource != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                if (_selectedType != null)
                                  _buildFilterChip(_selectedType.toString().split('.').last, () => setState(() => _selectedType = null),),
                                if (_selectedSource != null)
                                  _buildFilterChip(_selectedSource.toString().split('.').last, () => setState(() => _selectedSource = null),),
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
                      ? SliverToBoxAdapter(child: Center(child: Text(l10n.noTransactions, style: AppTextStyles.bodyTextStyle,),),)
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final filteredTransactions = wallet.getFilteredTransactions(type: _selectedType, source: _selectedSource,);
                              
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
      spacing: 8,
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
                decoration: const BoxDecoration(color: AppColors.primaryColor, shape: BoxShape.circle,),
                child: const Icon(Icons.check, color: AppColors.whiteColor, size: 18,),
              ),
            ),
          ],
        ),
        Text('Ethan Carter',style: AppTextStyles.headingTextStyle3,),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        spacing: 12,
        children: [
          Row(
            spacing: 16,
            children: [
              Expanded(
                child: PrimaryBtn(
                  btnText: l10n.buy,
                  icon: '',
                  onTap: () => context.push(RouterEnum.buyFlixbitPointsView.routeName),
                  borderRadius: 20,
                ),
              ),
              Expanded(
                child: PrimaryBtn(
                  btnText: l10n.sell,
                  icon: '',
                  onTap: () {},
                  borderRadius: 20,
                  bgColor: AppColors.primaryColor.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: PrimaryBtn(
              btnText: 'Redeem Rewards',
              icon: '🎁',
              onTap: () => context.push(RouterEnum.rewardsView.routeName),
              borderRadius: 20,
              bgColor: AppColors.successColor.withValues(alpha: 0.2),
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
      child: Column(
        spacing: 16,
        children: [
         FutureBuilder(future: WalletService.getBalance(userID), builder: (_, snapshot){
           if(snapshot.hasData){
             return  _buildMainBalanceCard(
               title: l10n.flixbitBalance,
               amount: snapshot.requireData,
               currency: 'FLIXBIT',
             );
           }

           return _buildMainBalanceCard(
             title: l10n.flixbitBalance,
             amount: wallet.balance?.flixbitPoints ?? 0,
             currency: 'FLIXBIT',
           );
         }),
          _buildTournamentEarningsCard(
            title: 'Tournament Earnings',
            amount: wallet.balance?.tournamentPoints ?? 0,
            subtitle: 'Total Flixbit earned from tournaments',
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainBalanceCard({
    required String title,
    required num amount,
    required String currency,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyTextStyle.copyWith(
                  color: AppColors.whiteColor.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currency,
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: AppColors.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Column(
            spacing: 4,
            children: [
              Text(
                FormattingHelper.getFormattedAmount(amount: amount.toDouble()),
                style: AppTextStyles.headingTextStyle3.copyWith(
                  color: AppColors.whiteColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Available Balance',
                style: AppTextStyles.captionTextStyle.copyWith(
                  color: AppColors.whiteColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
  
  Widget _buildTournamentEarningsCard({
    required String title,
    required num amount,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: ()=>  DisplayMessageHelper.showTournamentPointsInfo(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greenColor.withValues(alpha: 0.3),),
        ),
        child: Row(
          spacing: 12,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.greenColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.emoji_events, color: AppColors.greenColor, size: 28,),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(title, style: AppTextStyles.bodyTextStyle.copyWith(fontWeight: FontWeight.w600,),),
                Text(subtitle, style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.lightGreyColor,),),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FormattingHelper.getFormattedAmount(amount: amount.toDouble()),
                style: AppTextStyles.tileTitleTextStyle.copyWith(color: AppColors.greenColor, fontWeight: FontWeight.bold,),
              ),
              Text('Points', style: AppTextStyles.captionTextStyle.copyWith(color: AppColors.lightGreyColor,),),
            ],
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

    // Special handling for reward redemptions
    final isRewardRedemption = transaction.source == TransactionSource.reward;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: isRewardRedemption 
            ? Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isRewardRedemption 
                  ? AppColors.primaryColor
                  : (isPositive ? AppColors.successColor : AppColors.errorColor),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRewardRedemption 
                  ? Icons.card_giftcard
                  : (isPositive ? Icons.arrow_upward : Icons.arrow_downward),
              color: AppColors.whiteColor,
            ),
          ),
          Expanded(child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getTransactionTitle(transaction), style: AppTextStyles.bodyTextStyle,),
                  Text(FormattingHelper.getFormattedDate(timestamp: transaction.timestamp), style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.lightGreyColor,),),
                ],
              ),
            ),
            Text(
              '${isPositive ? '+' : '-'}${FormattingHelper.getFormattedAmount(amount: transaction.amount)}',
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: isPositive ? AppColors.successColor : AppColors.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],))

        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDelete,
      backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
      labelStyle: AppTextStyles.smallTextStyle,
    );
  }

  Widget _buildPointsBreakdown(WalletProvider wallet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.pointsBreakdown, style: AppTextStyles.subHeadingTextStyle,),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, num>>(
            future: wallet.getDailySummary('currentUser'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return LoadingWidget();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    snapshot.error.toString(),
                    style: AppTextStyles.errorTextStyle,
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final summary = snapshot.data ?? {};
              return Column(
                spacing: 8,
                children: [
                  _buildPointsSourceCard(
                    icon: Icons.videogame_asset,
                    title: AppLocalizations.of(context)!.tournament,
                    points: summary['tournament'] ?? 0,
                    color: AppColors.primaryColor,
                  ),
                  _buildPointsSourceCard(
                    icon: Icons.ondemand_video,
                    title: AppLocalizations.of(context)!.videoAds,
                    points: summary['video_ad'] ?? 0,
                    color: Colors.purple,
                  ),
                  _buildPointsSourceCard(
                    icon: Icons.rate_review,
                    title: AppLocalizations.of(context)!.reviews,
                    points: summary['review'] ?? 0,
                    color: Colors.orange,
                  ),
                  _buildPointsSourceCard(
                    icon: Icons.qr_code_scanner,
                    title: AppLocalizations.of(context)!.qrScans,
                    points: summary['qr_scan'] ?? 0,
                    color: Colors.blue,
                  ),
                  _buildPointsSourceCard(
                    icon: Icons.people,
                    title: AppLocalizations.of(context)!.referrals,
                    points: summary['referral'] ?? 0,
                    color: Colors.green,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPointsSourceCard({
    required IconData icon,
    required String title,
    required num points,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyTextStyle,
                ),
                Text(
                  '${FormattingHelper.getFormattedAmount(amount: points.toDouble())} points today',
                  style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.lightGreyColor,),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('+${FormattingHelper.getFormattedAmount(amount: points.toDouble())}', style: AppTextStyles.smallTextStyle.copyWith( color: color, fontWeight: FontWeight.bold,),),
          ),
        ],
      ),
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

}