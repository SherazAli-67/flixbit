import 'package:flixbit/src/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flixbit/src/providers/wallet_provider.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';

class SellFlixbitPointsPage extends StatefulWidget {
  const SellFlixbitPointsPage({super.key});

  @override
  State<SellFlixbitPointsPage> createState() => _SellFlixbitPointsPageState();
}

class _SellFlixbitPointsPageState extends State<SellFlixbitPointsPage> {
  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _payoutEmailController = TextEditingController();
  String _selectedPayoutMethod = 'PayPal';
  bool _isProcessing = false;

  // Conversion and fee settings (should match WalletSettings.defaults())
  final double _conversionRate = 0.01; // 1 Flixbit = $0.01
  final int _withdrawalFee = 50; // 50 points flat fee
  final int _minWithdrawal = 500; // Minimum 500 points

  int get _pointsToSell {
    return int.tryParse(_pointsController.text) ?? 0;
  }

  double get _usdAmount {
    return _pointsToSell * _conversionRate;
  }

  int get _totalDeduction {
    return _pointsToSell + _withdrawalFee;
  }

  double get _netAmount {
    return _usdAmount; // Net amount user receives
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _payoutEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final currentBalance = wallet.balance?.flixbitPoints ?? 0;

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
          'Sell Flixbit Points',
          style: AppTextStyles.headingTextStyle3,
        ),
        centerTitle: true,
      ),
      body: _isProcessing
          ? LoadingWidget()
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current balance card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withValues(alpha: 0.2),
                            AppColors.primaryColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Balance',
                                style: AppTextStyles.bodyTextStyle.copyWith(
                                  color: AppColors.lightGreyColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${currentBalance.toInt()} Points',
                                style: AppTextStyles.headingTextStyle3.copyWith(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.account_balance_wallet,
                            size: 40,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Warning info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Minimum withdrawal: $_minWithdrawal points. Withdrawal fee: $_withdrawalFee points.',
                              style: AppTextStyles.bodyTextStyle.copyWith(
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Points to sell input
                    Text(
                      'Points to Sell',
                      style: AppTextStyles.subHeadingTextStyle,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppTextStyles.bodyTextStyle,
                      decoration: InputDecoration(
                        hintText: 'Enter points amount',
                        hintStyle: AppTextStyles.bodyTextStyle.copyWith(
                          color: AppColors.lightGreyColor,
                        ),
                        filled: true,
                        fillColor: AppColors.cardBgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixText: 'Points',
                        suffixStyle: AppTextStyles.bodyTextStyle.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    // Quick amount buttons
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [500, 1000, 2500, 5000].map((amount) {
                        return ActionChip(
                          label: Text('$amount'),
                          labelStyle: AppTextStyles.bodyTextStyle.copyWith(
                            color: _pointsToSell == amount
                                ? AppColors.whiteColor
                                : AppColors.primaryColor,
                          ),
                          backgroundColor: _pointsToSell == amount
                              ? AppColors.primaryColor
                              : AppColors.primaryColor.withValues(alpha: 0.1),
                          onPressed: () {
                            _pointsController.text = amount.toString();
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Calculation breakdown
                    if (_pointsToSell > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildCalculationRow('Points to sell', '$_pointsToSell'),
                            const Divider(color: AppColors.unSelectedGreyColor),
                            _buildCalculationRow('Conversion rate', '1 point = \$$_conversionRate'),
                            const Divider(color: AppColors.unSelectedGreyColor),
                            _buildCalculationRow('USD Amount', '\$${_usdAmount.toStringAsFixed(2)}'),
                            const Divider(color: AppColors.unSelectedGreyColor),
                            _buildCalculationRow(
                              'Withdrawal fee',
                              '$_withdrawalFee points',
                              isNegative: true,
                            ),
                            const Divider(color: AppColors.unSelectedGreyColor, height: 24),
                            _buildCalculationRow(
                              'Total deduction',
                              '$_totalDeduction points',
                              isTotal: true,
                            ),
                            const SizedBox(height: 8),
                            _buildCalculationRow(
                              'You receive',
                              '\$${_netAmount.toStringAsFixed(2)} USD',
                              isTotal: true,
                              color: AppColors.greenColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Payout method
                    Text(
                      'Payout Method',
                      style: AppTextStyles.subHeadingTextStyle,
                    ),
                    const SizedBox(height: 12),
                    ..._buildPayoutMethodOptions(),

                    const SizedBox(height: 16),

                    // Payout email/account
                    TextField(
                      controller: _payoutEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTextStyles.bodyTextStyle,
                      decoration: InputDecoration(
                        hintText: _selectedPayoutMethod == 'PayPal'
                            ? 'PayPal email address'
                            : _selectedPayoutMethod == 'Bank Transfer'
                                ? 'Bank account number'
                                : 'Account details',
                        hintStyle: AppTextStyles.bodyTextStyle.copyWith(
                          color: AppColors.lightGreyColor,
                        ),
                        filled: true,
                        fillColor: AppColors.cardBgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          _selectedPayoutMethod == 'PayPal'
                              ? Icons.paypal
                              : Icons.account_balance,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sell button
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryBtn(
                        btnText: 'Request Withdrawal',
                        icon: '',
                        onTap: _canSubmit ? () => _handleSell() : () {},
                        bgColor: _canSubmit
                            ? AppColors.primaryColor
                            : AppColors.unSelectedGreyColor,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Processing info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Processing Information',
                            style: AppTextStyles.tileTitleTextStyle,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.schedule, 'Processing time: 3-5 business days'),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.verified_user, 'Secure payout processing'),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.receipt_long, 'Email confirmation sent'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Terms
                    Text(
                      'By requesting a withdrawal, you agree to our Withdrawal Policy. Points will be deducted immediately and processed within 3-5 business days.',
                      style: AppTextStyles.captionTextStyle.copyWith(
                        color: AppColors.lightGreyColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildPayoutMethodOptions() {
    final methods = ['PayPal', 'Bank Transfer', 'Stripe'];
    
    return methods.map((method) {
      final isSelected = _selectedPayoutMethod == method;
      
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedPayoutMethod = method;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryColor.withValues(alpha: 0.1)
                : AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.unSelectedGreyColor,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Text(
                method,
                style: AppTextStyles.bodyTextStyle.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildCalculationRow(String label, String value, {bool isNegative = false, bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: isTotal ? AppColors.whiteColor : AppColors.lightGreyColor,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: color ?? (isNegative
                  ? AppColors.errorColor
                  : isTotal
                      ? AppColors.primaryColor
                      : AppColors.whiteColor),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
          ),
        ),
      ],
    );
  }

  bool get _canSubmit {
    final wallet = context.read<WalletProvider>();
    final currentBalance = wallet.balance?.flixbitPoints ?? 0;
    
    return _pointsToSell >= _minWithdrawal &&
           _totalDeduction <= currentBalance &&
           _payoutEmailController.text.isNotEmpty;
  }

  Future<void> _handleSell() async {
    final wallet = context.read<WalletProvider>();
    final currentBalance = wallet.balance?.flixbitPoints ?? 0;

    // Validation
    if (_pointsToSell < _minWithdrawal) {
      _showError('Minimum withdrawal is $_minWithdrawal points');
      return;
    }

    if (_totalDeduction > currentBalance) {
      _showError('Insufficient balance. You need $_totalDeduction points (including $_withdrawalFee points fee)');
      return;
    }

    if (_payoutEmailController.text.isEmpty) {
      _showError('Please enter your payout account details');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBgColor,
        title: Text(
          'Confirm Withdrawal',
          style: AppTextStyles.headingTextStyle3,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are requesting a withdrawal of:',
              style: AppTextStyles.bodyTextStyle,
            ),
            const SizedBox(height: 16),
            _buildCalculationRow('Points to sell', '$_pointsToSell'),
            _buildCalculationRow('Withdrawal fee', '$_withdrawalFee points', isNegative: true),
            const Divider(color: AppColors.unSelectedGreyColor),
            _buildCalculationRow('Total deduction', '$_totalDeduction points', isTotal: true),
            const SizedBox(height: 8),
            _buildCalculationRow('You receive', '\$${_netAmount.toStringAsFixed(2)} USD', isTotal: true, color: AppColors.greenColor),
            const SizedBox(height: 16),
            _buildCalculationRow('Method', _selectedPayoutMethod),
            _buildCalculationRow('Account', _payoutEmailController.text),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.lightGreyColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirm', style: TextStyle(color: AppColors.primaryColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      await wallet.sellPoints(
        userId: userId,
        points: _pointsToSell,
        payoutMethod: '$_selectedPayoutMethod: ${_payoutEmailController.text}',
      );

      if (mounted) {
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.whiteColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Withdrawal request submitted! You will receive \$${_netAmount.toStringAsFixed(2)} in 3-5 business days.',
                    style: TextStyle(color: AppColors.whiteColor),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.greenColor,
            duration: const Duration(seconds: 4),
          ),
        );

        // Go back to wallet
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Withdrawal failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }
}

