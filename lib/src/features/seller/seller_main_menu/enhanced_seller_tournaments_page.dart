import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/tournament_model.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';
import '../../../service/enhanced_tournament_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/match_management_view.dart';
import '../widgets/score_update_view.dart';
import '../widgets/analytics_view.dart';

class EnhancedSellerTournamentsPage extends StatefulWidget {
  const EnhancedSellerTournamentsPage({super.key});

  @override
  State<EnhancedSellerTournamentsPage> createState() =>
      _EnhancedSellerTournamentsPageState();
}

class _EnhancedSellerTournamentsPageState
    extends State<EnhancedSellerTournamentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Lists
  List<Tournament> _myTournaments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadMyTournaments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyTournaments() async {
    setState(() => _isLoading = true);
    try {
      final sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final tournaments = await EnhancedTournamentService.getAllTournaments(
        sellerId: sellerId,
      );
      setState(() {
        _myTournaments = tournaments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(l10n),

            // Tab Bar
            Container(
              color: AppColors.cardBgColor,
              child: TabBar(
                controller: _tabController,
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                indicatorColor: AppColors.primaryColor,
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: AppColors.unSelectedGreyColor,
                labelStyle: AppTextStyles.smallBoldTextStyle,
                tabs: const [
                  Tab(text: 'Create'),
                  Tab(text: 'My Tournaments'),
                  Tab(text: 'Matches'),
                  Tab(text: 'Scores'),
                  Tab(text: 'Analytics'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCreateTournamentTab(),
                  _buildMyTournamentsTab(),
                  _buildMatchesTab(),
                  _buildScoresTab(),
                  _buildAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBgColor,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: AppColors.primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tournament Management',
                  style: AppTextStyles.headingTextStyle3,
                ),
                Text(
                  'Create and manage game prediction tournaments',
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor),
            onPressed: _loadMyTournaments,
          ),
        ],
      ),
    );
  }

  // ==================== CREATE TOURNAMENT TAB ====================
  Widget _buildCreateTournamentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [
          _CreateTournamentForm(
            onTournamentCreated: () {
              _loadMyTournaments();
              _tabController.animateTo(1);
            },
          ),
        ],
      ),
    );
  }

  // ==================== MY TOURNAMENTS TAB ====================
  Widget _buildMyTournamentsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myTournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer_outlined,
              size: 80,
              color: AppColors.unSelectedGreyColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No tournaments yet',
              style: AppTextStyles.subHeadingTextStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first tournament to get started',
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.add),
              label: const Text('Create Tournament'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.whiteColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myTournaments.length,
      itemBuilder: (context, index) {
        return _TournamentCard(
          tournament: _myTournaments[index],
          onEdit: () {
            // TODO: Navigate to edit page
          },
          onDelete: () async {
            await EnhancedTournamentService.deleteTournament(
              _myTournaments[index].id,
            );
            _loadMyTournaments();
          },
        );
      },
    );
  }

  // ==================== MATCHES TAB ====================
  Widget _buildMatchesTab() {
    return MatchManagementView(tournaments: _myTournaments);
  }

  // ==================== SCORES TAB ====================
  Widget _buildScoresTab() {
    return ScoreUpdateView(tournaments: _myTournaments);
  }

  // ==================== ANALYTICS TAB ====================
  Widget _buildAnalyticsTab() {
    return SellerTournamentAnalyticsView(tournaments: _myTournaments);
  }
}

// ==================== CREATE TOURNAMENT FORM ====================
class _CreateTournamentForm extends StatefulWidget {
  final VoidCallback onTournamentCreated;

  const _CreateTournamentForm({required this.onTournamentCreated});

  @override
  State<_CreateTournamentForm> createState() => _CreateTournamentFormState();
}

class _CreateTournamentFormState extends State<_CreateTournamentForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic Info
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedSport = 'Football';
  DateTime? _startDate;
  DateTime? _endDate;

  // Game Rules
  PredictionType _predictionType = PredictionType.winnerOnly;
  int _pointsPerCorrectPrediction = 10;
  int _bonusPointsForExactScore = 20;
  double _qualificationThreshold = 80.0;

  // Entry & Pricing
  EntryType _entryType = EntryType.free;
  int _entryFee = 0;

  // Rewards
  final _prizeDescriptionController = TextEditingController();
  int _numberOfWinners = 1;
  final List<String> _selectedRewardIds = [];

  // Sponsorship
  bool _isSponsored = false;
  
  // Targeting
  String _region = 'Global';

  // Notification Settings
  bool _sendPushOnCreation = true;
  bool _notifyBeforeMatches = true;
  bool _notifyOnScoreUpdates = true;

  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prizeDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [
          // Basic Information Section
          _buildSection(
            title: 'Basic Information',
            icon: Icons.info_outline,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Tournament Name',
                hint: 'e.g., World Cup Predictions 2025',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Brief description of the tournament',
                maxLines: 3,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildDropdown<String>(
                label: 'Sport Type',
                value: _selectedSport,
                items: ['Football', 'Basketball', 'Cricket', 'Tennis', 'Other'],
                onChanged: (v) => setState(() => _selectedSport = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () async {
                        final date = await _selectDate(context);
                        if (date != null) setState(() => _startDate = date);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      label: 'End Date',
                      date: _endDate,
                      onTap: () async {
                        final date = await _selectDate(context);
                        if (date != null) setState(() => _endDate = date);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Game Rules Section
          _buildSection(
            title: 'Game Rules & Scoring',
            icon: Icons.rule,
            children: [
              _buildDropdown<PredictionType>(
                label: 'Prediction Type',
                value: _predictionType,
                items: PredictionType.values,
                itemLabel: (type) {
                  switch (type) {
                    case PredictionType.winnerOnly:
                      return 'Winner Only';
                    case PredictionType.scoreline:
                      return 'Scoreline';
                    case PredictionType.both:
                      return 'Both';
                  }
                },
                onChanged: (v) => setState(() => _predictionType = v!),
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                label: 'Points Per Correct Prediction',
                value: _pointsPerCorrectPrediction,
                onChanged: (v) => setState(() => _pointsPerCorrectPrediction = v),
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                label: 'Bonus Points for Exact Score',
                value: _bonusPointsForExactScore,
                onChanged: (v) => setState(() => _bonusPointsForExactScore = v),
              ),
              const SizedBox(height: 16),
              _buildSliderField(
                label: 'Qualification Threshold (${_qualificationThreshold.toInt()}%)',
                value: _qualificationThreshold,
                min: 50,
                max: 100,
                onChanged: (v) => setState(() => _qualificationThreshold = v),
              ),
            ],
          ),

          // Entry & Pricing Section
          _buildSection(
            title: 'Entry & Pricing',
            icon: Icons.payment,
            children: [
              _buildRadioGroup<EntryType>(
                label: 'Entry Type',
                value: _entryType,
                options: EntryType.values,
                optionLabel: (type) => type == EntryType.free ? 'Free' : 'Paid',
                onChanged: (v) => setState(() => _entryType = v!),
              ),
              if (_entryType == EntryType.paid) ...[
                const SizedBox(height: 16),
                _buildNumberField(
                  label: 'Entry Fee (Flixbit Points)',
                  value: _entryFee,
                  onChanged: (v) => setState(() => _entryFee = v),
                ),
              ],
            ],
          ),

          // Rewards Section
          _buildSection(
            title: 'Rewards & Prizes',
            icon: Icons.card_giftcard,
            children: [
              _buildTextField(
                controller: _prizeDescriptionController,
                label: 'Prize Description',
                hint: 'e.g., \$500 Cash Prize + Gift Vouchers',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                label: 'Number of Winners',
                value: _numberOfWinners,
                onChanged: (v) => setState(() => _numberOfWinners = v),
              ),
              const SizedBox(height: 16),
              _buildRewardSelectionField(),
            ],
          ),

          // Sponsorship Section
          _buildSection(
            title: 'Sponsorship (Optional)',
            icon: Icons.business,
            children: [
              _buildSwitch(
                label: 'Is Sponsored Tournament',
                value: _isSponsored,
                onChanged: (v) => setState(() => _isSponsored = v),
              ),
              if (_isSponsored)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Sponsor details can be configured after creation',
                    style: AppTextStyles.captionTextStyle.copyWith(
                      color: AppColors.lightGreyColor,
                    ),
                  ),
                ),
            ],
          ),

          // Targeting Section
          _buildSection(
            title: 'Targeting & Visibility',
            icon: Icons.location_on,
            children: [
              _buildDropdown<String>(
                label: 'Region',
                value: _region,
                items: ['Global', 'Dubai', 'Riyadh', 'Cairo', 'Other'],
                onChanged: (v) => setState(() => _region = v!),
              ),
            ],
          ),

          // Notification Settings
          _buildSection(
            title: 'Notification Settings',
            icon: Icons.notifications,
            children: [
              _buildSwitch(
                label: 'Send push notification on creation',
                value: _sendPushOnCreation,
                onChanged: (v) => setState(() => _sendPushOnCreation = v),
              ),
              _buildSwitch(
                label: 'Notify users before matches',
                value: _notifyBeforeMatches,
                onChanged: (v) => setState(() => _notifyBeforeMatches = v),
              ),
              _buildSwitch(
                label: 'Notify on score updates',
                value: _notifyOnScoreUpdates,
                onChanged: (v) => setState(() => _notifyOnScoreUpdates = v),
              ),
            ],
          ),

          // Create Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isCreating ? null : _createTournament,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCreating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Create Tournament',
                      style: AppTextStyles.buttonTextStyle.copyWith(
                        fontSize: 18,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      final tournament = Tournament(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        sportType: _selectedSport,
        startDate: _startDate!,
        endDate: _endDate!,
        createdAt: DateTime.now(),
        status: TournamentStatus.upcoming,
        totalMatches: 0,
        predictionType: _predictionType,
        pointsPerCorrectPrediction: _pointsPerCorrectPrediction,
        bonusPointsForExactScore: _bonusPointsForExactScore,
        qualificationThreshold: _qualificationThreshold / 100,
        entryType: _entryType,
        entryFee: _entryFee,
        prizeDescription: _prizeDescriptionController.text,
        numberOfWinners: _numberOfWinners,
        rewardIds: _selectedRewardIds,
        isSponsored: _isSponsored,
        region: _region,
        sendPushOnCreation: _sendPushOnCreation,
        notifyBeforeMatches: _notifyBeforeMatches,
        notifyOnScoreUpdates: _notifyOnScoreUpdates,
        createdBy: sellerId,
      );

      await EnhancedTournamentService.createTournament(tournament);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tournament created successfully!'),
            backgroundColor: AppColors.greenColor,
          ),
        );
        widget.onTournamentCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  // Helper Widgets
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.tileTitleTextStyle),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.smallBoldTextStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.bodyTextStyle,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.hintTextStyle,
            filled: true,
            fillColor: AppColors.inputFieldBgColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    String Function(T)? itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.smallBoldTextStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                itemLabel?.call(item) ?? item.toString(),
                style: AppTextStyles.bodyTextStyle,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          style: AppTextStyles.bodyTextStyle,
          dropdownColor: AppColors.cardBgColor,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFieldBgColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.smallBoldTextStyle),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputFieldBgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select date',
                    style: date != null
                        ? AppTextStyles.bodyTextStyle
                        : AppTextStyles.hintTextStyle,
                  ),
                ),
                Icon(Icons.calendar_today,
                    size: 18, color: AppColors.unSelectedGreyColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required void Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.smallBoldTextStyle),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              icon: Icon(Icons.remove_circle,
                  color: value > 1
                      ? AppColors.primaryColor
                      : AppColors.unSelectedGreyColor),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.inputFieldBgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.tileTitleTextStyle,
                ),
              ),
            ),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: Icon(Icons.add_circle, color: AppColors.primaryColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required void Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.smallBoldTextStyle),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: AppColors.primaryColor,
          inactiveColor: AppColors.unSelectedGreyColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRadioGroup<T>({
    required String label,
    required T value,
    required List<T> options,
    required String Function(T) optionLabel,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.smallBoldTextStyle),
        const SizedBox(height: 8),
        ...options.map((option) {
          return RadioListTile<T>(
            value: option,
            groupValue: value,
            onChanged: onChanged,
            title: Text(optionLabel(option), style: AppTextStyles.bodyTextStyle),
            activeColor: AppColors.primaryColor,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }


  Widget _buildSwitch({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.bodyTextStyle),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryColor,
              surface: AppColors.cardBgColor,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Widget _buildRewardSelectionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Rewards (Optional)',
          style: AppTextStyles.smallBoldTextStyle,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inputFieldBgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reward selection will be available after creating the tournament',
                style: AppTextStyles.captionTextStyle.copyWith(
                  color: AppColors.lightGreyColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can add specific rewards as prizes later in the tournament settings',
                style: AppTextStyles.captionTextStyle.copyWith(
                  color: AppColors.lightGreyColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== TOURNAMENT CARD ====================
class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TournamentCard({
    required this.tournament,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tournament.name,
                  style: AppTextStyles.tileTitleTextStyle,
                ),
              ),
              _StatusBadge(status: tournament.status),
            ],
          ),
          Text(
            tournament.description,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
          ),
          Row(
            children: [
              Icon(Icons.sports_soccer, size: 16, color: AppColors.unSelectedGreyColor),
              const SizedBox(width: 4),
              Text(
                '${tournament.totalMatches} matches',
                style: AppTextStyles.captionTextStyle,
              ),
              const SizedBox(width: 16),
              Icon(Icons.emoji_events, size: 16, color: AppColors.primaryColor),
              const SizedBox(width: 4),
              Text(
                tournament.prizeDescription,
                style: AppTextStyles.captionTextStyle.copyWith(
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    side: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.redColor,
                    side: BorderSide(color: AppColors.redColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TournamentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    
    switch (status) {
      case TournamentStatus.upcoming:
        color = AppColors.upcomingStatusColor;
        label = 'Upcoming';
        break;
      case TournamentStatus.ongoing:
        color = AppColors.liveStatusColor;
        label = 'Live';
        break;
      case TournamentStatus.completed:
        color = AppColors.completedStatusColor;
        label = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionTextStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


