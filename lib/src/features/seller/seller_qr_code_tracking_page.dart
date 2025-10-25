import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/service/qr_analytics_service.dart';
import 'package:fl_chart/fl_chart.dart';

class SellerQRCodeTrackingPage extends StatefulWidget {
  const SellerQRCodeTrackingPage({super.key});

  @override
  State<SellerQRCodeTrackingPage> createState() => _SellerQRCodeTrackingPageState();
}

class _SellerQRCodeTrackingPageState extends State<SellerQRCodeTrackingPage> {
  final QRAnalyticsService _analyticsService = QRAnalyticsService();
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String? _sellerId;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    _sellerId = FirebaseAuth.instance.currentUser?.uid;
    
    if (_sellerId != null) {
      final analytics = await _analyticsService.getComprehensiveAnalytics(_sellerId!);
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top AppBar-like header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.whiteColor),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'QR Code Analytics',
                      style: AppTextStyles.subHeadingTextStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _loadAnalytics,
                    icon: const Icon(Icons.refresh, color: AppColors.whiteColor),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : _sellerId == null
                      ? const Center(
                          child: Text(
                            'Please sign in to view analytics',
                            style: AppTextStyles.bodyTextStyle,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAnalytics,
                          color: AppColors.primaryColor,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Stats Cards
                                _buildStatsGrid(),
                                const SizedBox(height: 24),

                                // Daily Trend Chart
                                _buildDailyTrendChart(),
                                const SizedBox(height: 24),

                                // Hourly Distribution
                                _buildHourlyDistribution(),
                                const SizedBox(height: 24),

                                // Conversion Info
                                _buildConversionInfo(),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'Total Scans',
          '${_analytics['totalScans'] ?? 0}',
          Icons.qr_code_scanner,
          AppColors.primaryColor,
        ),
        _buildStatCard(
          'Today',
          '${_analytics['dailyScans'] ?? 0}',
          Icons.today,
          Colors.green,
        ),
        _buildStatCard(
          'This Week',
          '${_analytics['weeklyScans'] ?? 0}',
          Icons.calendar_view_week,
          Colors.orange,
        ),
        _buildStatCard(
          'This Month',
          '${_analytics['monthlyScans'] ?? 0}',
          Icons.calendar_month,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headingTextStyle3.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.captionTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTrendChart() {
    final dailyTrend = _analytics['dailyTrend'] as Map<String, int>? ?? {};
    
    if (dailyTrend.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No scan data available',
            style: AppTextStyles.bodyTextStyle,
          ),
        ),
      );
    }

    final sortedEntries = dailyTrend.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Scan Trend (Last 30 Days)',
            style: AppTextStyles.tileTitleTextStyle,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppTextStyles.captionTextStyle,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: sortedEntries
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble()))
                        .toList(),
                    isCurved: true,
                    color: AppColors.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyDistribution() {
    final peakHour = _analytics['peakHour'] ?? 0;
    final peakHourScans = _analytics['peakHourScans'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Peak Scan Time',
            style: AppTextStyles.tileTitleTextStyle,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppColors.primaryColor,
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${peakHour.toString().padLeft(2, '0')}:00 - ${(peakHour + 1).toString().padLeft(2, '0')}:00',
                      style: AppTextStyles.subHeadingTextStyle.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$peakHourScans scans during peak hour',
                      style: AppTextStyles.bodyTextStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversionInfo() {
    final followersFromQR = _analytics['followersFromQR'] ?? 0;
    final conversionRate = _analytics['conversionRate'] ?? '0%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conversion Metrics',
            style: AppTextStyles.tileTitleTextStyle,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                'Followers from QR',
                followersFromQR.toString(),
                Icons.people,
                Colors.green,
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.unSelectedGreyColor,
              ),
              _buildMetricItem(
                'Conversion Rate',
                conversionRate,
                Icons.trending_up,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.subHeadingTextStyle.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.captionTextStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
