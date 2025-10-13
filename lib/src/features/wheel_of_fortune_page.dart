// lib/widgets/fortune_wheel.dart

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import '../config/wheel_config.dart';
import '../models/gift_model.dart';
import '../models/wheel_result_model.dart';
import '../service/gift_service.dart';

/// Independent Wheel of Fortune Widget
/// Can be used anywhere in the app without parameters
class WheelOfFortunePage extends StatefulWidget {
  const WheelOfFortunePage({Key? key}) : super(key: key);

  @override
  State<WheelOfFortunePage> createState() => _FortuneWheelWidgetState();
}

class _FortuneWheelWidgetState extends State<WheelOfFortunePage> {
  final StreamController<int> _controller = StreamController<int>();
  final ConfettiController _confettiController = ConfettiController(
    duration: Duration(seconds: 3),
  );
  final GiftService _giftService = GiftService();

  // Internal state
  Gift? _currentGift;
  List<Gift> _pendingGifts = [];
  bool _isSpinning = false;
  bool _hasSpun = false;
  bool _isLoading = true;
  WheelResult? _result;
  double _walletBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadGiftData();
  }

  @override
  void dispose() {
    _controller.close();
    _confettiController.dispose();
    super.dispose();
  }

  /// Load pending gifts and select first one
  Future<void> _loadGiftData() async {
    setState(() => _isLoading = true);

    try {
      _pendingGifts = await _giftService.getPendingGifts('currentUser');
      _walletBalance = await _giftService.getWalletBalance('currentUser');

      if (_pendingGifts.isNotEmpty) {
        _currentGift = _pendingGifts.first;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load gift data: $e');
    }
  }

  /// Spin the wheel
  Future<void> _spinWheel() async {
    if (_isSpinning || _hasSpun || _currentGift == null) return;

    setState(() => _isSpinning = true);

    try {
      // Get result from service
      final result = await _giftService.spinWheel(
        _currentGift!.id,
        _currentGift!.amount,
      );

      setState(() => _result = result);

      // Trigger wheel animation
      _controller.add(result.segmentIndex);

      // Wait for animation
      await Future.delayed(Duration(seconds: 3));

      setState(() {
        _isSpinning = false;
        _hasSpun = true;
      });

      // Show confetti
      _confettiController.play();

      // Show result
      await Future.delayed(Duration(milliseconds: 500));
      _showResultDialog();
    } catch (e) {
      setState(() => _isSpinning = false);
      _showErrorSnackBar('Error spinning wheel: $e');
    }
  }

  /// Show result dialog
  void _showResultDialog() {
    if (_result == null) return;

    final isWin = _result!.finalAmount >= _currentGift!.amount;
    final difference = _result!.finalAmount - _currentGift!.amount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2C3320),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isWin ? Icons.celebration : Icons.sentiment_satisfied,
                color: isWin ? Color(0xFFF5E042) : Colors.orange,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                isWin ? 'Congratulations!' : 'You Won!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '\$${_result!.finalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Color(0xFFF5E042),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              if (difference > 0)
                Text(
                  '+\$${difference.toStringAsFixed(2)} bonus!',
                  style: TextStyle(color: Colors.green, fontSize: 16),
                )
              else if (difference < 0)
                Text(
                  '${difference.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.orange, fontSize: 16),
                ),
              SizedBox(height: 16),
              Text(
                'Winnings are credited to your wallet instantly.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _claimWinnings(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF5E042),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Claim Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Claim winnings
  Future<void> _claimWinnings() async {
    if (_result == null || _currentGift == null) return;

    try {
      await _giftService.claimGift(_currentGift!.id, _result!.finalAmount);

      Navigator.pop(context); // Close dialog

      _showSuccessSnackBar(
        '\$${_result!.finalAmount.toStringAsFixed(2)} added to your wallet!',
      );

      // Reset and load next gift
      await _loadGiftData();
      setState(() {
        _hasSpun = false;
        _result = null;
      });
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Failed to claim winnings: $e');
    }
  }

  /// Add cash directly without spinning
  Future<void> _addCashDirectly() async {
    if (_currentGift == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2C3320),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Add Cash Directly?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'You will receive exactly \$${_currentGift!.amount.toStringAsFixed(2)} in your wallet without spinning the wheel. Are you sure?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF5E042),
                foregroundColor: Colors.black,
              ),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _giftService.addCashDirectly(
          _currentGift!.id,
          _currentGift!.amount,
        );

        _showSuccessSnackBar(
          '\$${_currentGift!.amount.toStringAsFixed(2)} added to your wallet!',
        );

        // Load next gift
        await _loadGiftData();
      } catch (e) {
        _showErrorSnackBar('Failed to add cash: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF2C3320),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF5E042),
          ),
        ),
      );
    }

    if (_currentGift == null) {
      return Scaffold(
        backgroundColor: Color(0xFF2C3320),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.card_giftcard_outlined, size: 80, color: Colors.white38),
              SizedBox(height: 16),
              Text(
                'No Pending Gifts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You don\'t have any gifts to claim right now',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadGiftData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF5E042),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text('Refresh', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    final segments = WheelConfig.defaultSegments;

    return Scaffold(
      backgroundColor: Color(0xFF2C3320),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Wheel of Fortune',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '\$${_walletBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Color(0xFFF5E042),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 20),
                Text(
                  'Spin the Wheel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Spin the wheel to win cash credit based on the virtual gifts you\'ve received.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 40),
                Expanded(
                  child: Center(
                    child: Container(
                      height: 300,
                      width: 300,
                      child: FortuneWheel(
                        selected: _controller.stream,
                        animateFirst: false,
                        duration: Duration(seconds: 3),
                        physics: CircularPanPhysics(
                          duration: Duration(seconds: 1),
                          curve: Curves.decelerate,
                        ),
                        indicators: [
                          FortuneIndicator(
                            alignment: Alignment.topCenter,
                            child: TriangleIndicator(color: Colors.white),
                          ),
                        ],
                        items: segments.map((segment) {
                          return FortuneItem(
                            child: Text(
                              segment.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: FortuneItemStyle(
                              color: segment.color,
                              borderColor: Colors.white,
                              borderWidth: 3,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Gift Value: ',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        '\$${_currentGift!.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Color(0xFFF5E042),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _hasSpun ? null : _spinWheel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasSpun
                                ? Colors.grey
                                : Color(0xFFF5E042),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: _isSpinning
                              ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                              : Text(
                            _hasSpun ? 'Already Spun' : 'Spin Now',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Winnings are credited to your wallet instantly.',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      if (!_hasSpun) ...[
                        SizedBox(height: 12),
                        GestureDetector(
                          onTap: _addCashDirectly,
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(text: 'Or, '),
                                TextSpan(
                                  text: 'add \$${_currentGift!.amount.toStringAsFixed(2)} cash value to wallet',
                                  style: TextStyle(
                                    color: Color(0xFFF5E042),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: [
                Colors.yellow,
                Colors.orange,
                Colors.red,
                Colors.green,
                Colors.blue,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Triangle indicator widget
class TriangleIndicator extends StatelessWidget {
  final Color color;

  const TriangleIndicator({Key? key, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(30, 30),
      painter: _TrianglePainter(color),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}