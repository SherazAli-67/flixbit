import 'package:flutter/material.dart';
import '../../../models/tournament_model.dart';
import '../../../models/match_model.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';
import '../../../service/enhanced_tournament_service.dart';
import 'package:intl/intl.dart';

class MatchManagementView extends StatefulWidget {
  final List<Tournament> tournaments;

  const MatchManagementView({super.key, required this.tournaments});

  @override
  State<MatchManagementView> createState() => _MatchManagementViewState();
}

class _MatchManagementViewState extends State<MatchManagementView> {
  Tournament? _selectedTournament;
  List<Match> _matches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tournaments.isNotEmpty) {
      _selectedTournament = widget.tournaments.first;
      _loadMatches();
    }
  }

  Future<void> _loadMatches() async {
    if (_selectedTournament == null) return;

    setState(() => _isLoading = true);
    try {
      final matches = await EnhancedTournamentService.getTournamentMatches(
        _selectedTournament!.id,
      );
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading matches: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tournaments.isEmpty) {
      return _buildEmptyState('Create a tournament first to add matches');
    }

    return Column(
      children: [
        // Tournament Selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderColor.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text('Select Tournament', style: AppTextStyles.smallBoldTextStyle),
              DropdownButtonFormField<Tournament>(
                value: _selectedTournament,
                items: widget.tournaments.map((tournament) {
                  return DropdownMenuItem(
                    value: tournament,
                    child: Text(
                      tournament.name,
                      style: AppTextStyles.bodyTextStyle,
                    ),
                  );
                }).toList(),
                onChanged: (tournament) {
                  setState(() => _selectedTournament = tournament);
                  _loadMatches();
                },
                style: AppTextStyles.bodyTextStyle,
                dropdownColor: AppColors.cardBgColor,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputFieldBgColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.borderColor),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Matches List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _matches.isEmpty
                  ? _buildEmptyState('No matches added yet')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _matches.length,
                      itemBuilder: (context, index) {
                        return _MatchCard(
                          match: _matches[index],
                          onEdit: () => _showAddEditMatchDialog(match: _matches[index],),
                          onDelete: () => _deleteMatch(_matches[index]),
                        );
                      },
                    ),
        ),

        // Add Match Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _selectedTournament != null
                  ? () => _showAddEditMatchDialog()
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Add Match'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
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
            message,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddEditMatchDialog({Match? match}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditMatchDialog(
        tournament: _selectedTournament!,
        match: match,
        onSave: () {
          _loadMatches();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _deleteMatch(Match match) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Match', style: AppTextStyles.subHeadingTextStyle),
        content: Text(
          'Are you sure you want to delete ${match.homeTeam} vs ${match.awayTeam}?',
          style: AppTextStyles.bodyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.lightGreyColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redColor,
              foregroundColor: AppColors.whiteColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await EnhancedTournamentService.deleteMatch(
          tournamentId: _selectedTournament!.id,
          matchId: match.id,
        );
        _loadMatches();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Match deleted successfully'),
              backgroundColor: AppColors.greenColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

// ==================== MATCH CARD ====================
class _MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MatchCard({
    required this.match,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(match.status).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          // Teams & Status
          Row(
            children: [
              Expanded(
                child: Text(
                  '${match.homeTeam} vs ${match.awayTeam}',
                  style: AppTextStyles.tileTitleTextStyle,
                ),
              ),
              _StatusChip(status: match.status),
            ],
          ),

          // Match Details
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 14, color: AppColors.unSelectedGreyColor),
              const SizedBox(width: 6),
              Text(
                '${dateFormat.format(match.matchDate)} • ${match.matchTime}',
                style: AppTextStyles.captionTextStyle.copyWith(
                  color: AppColors.unSelectedGreyColor,
                ),
              ),
            ],
          ),

          Row(
            children: [
              Icon(Icons.location_on,
                  size: 14, color: AppColors.unSelectedGreyColor),
              const SizedBox(width: 6),
              Text(
                match.venue,
                style: AppTextStyles.captionTextStyle.copyWith(
                  color: AppColors.unSelectedGreyColor,
                ),
              ),
            ],
          ),

          // Score (if completed)
          if (match.status == MatchStatus.completed) ...[
            Divider(color: AppColors.borderColor.withValues(alpha: 0.3)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${match.homeScore ?? 0}',
                  style: AppTextStyles.headingTextStyle3.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Text('-', style: AppTextStyles.subHeadingTextStyle),
                const SizedBox(width: 16),
                Text(
                  '${match.awayScore ?? 0}',
                  style: AppTextStyles.headingTextStyle3.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ],

          // Actions
          Divider(color: AppColors.borderColor.withValues(alpha: 0.3)),
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

  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.upcoming:
        return AppColors.upcomingStatusColor;
      case MatchStatus.live:
        return AppColors.liveStatusColor;
      case MatchStatus.completed:
        return AppColors.completedStatusColor;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final MatchStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case MatchStatus.upcoming:
        color = AppColors.upcomingStatusColor;
        label = 'Upcoming';
        break;
      case MatchStatus.live:
        color = AppColors.liveStatusColor;
        label = 'Live';
        break;
      case MatchStatus.completed:
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

// ==================== ADD/EDIT MATCH DIALOG ====================
class _AddEditMatchDialog extends StatefulWidget {
  final Tournament tournament;
  final Match? match;
  final VoidCallback onSave;

  const _AddEditMatchDialog({
    required this.tournament,
    this.match,
    required this.onSave,
  });

  @override
  State<_AddEditMatchDialog> createState() => _AddEditMatchDialogState();
}

class _AddEditMatchDialogState extends State<_AddEditMatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _homeTeamController = TextEditingController();
  final _awayTeamController = TextEditingController();
  final _venueController = TextEditingController();
  DateTime? _matchDate;
  TimeOfDay? _matchTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.match != null) {
      _homeTeamController.text = widget.match!.homeTeam;
      _awayTeamController.text = widget.match!.awayTeam;
      _venueController.text = widget.match!.venue;
      _matchDate = widget.match!.matchDate;
      
      // Parse time from string (HH:mm format)
      final timeParts = widget.match!.matchTime.split(':');
      if (timeParts.length == 2) {
        _matchTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    }
  }

  @override
  void dispose() {
    _homeTeamController.dispose();
    _awayTeamController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.match != null;

    return Dialog(
      backgroundColor: AppColors.cardBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 20,
              children: [
                // Title
                Text(
                  isEdit ? 'Edit Match' : 'Add Match',
                  style: AppTextStyles.headingTextStyle3,
                ),

                // Home Team
                _buildTextField(
                  controller: _homeTeamController,
                  label: 'Home Team',
                  hint: 'e.g., Manchester City',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),

                // Away Team
                _buildTextField(
                  controller: _awayTeamController,
                  label: 'Away Team',
                  hint: 'e.g., Arsenal',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),

                // Venue
                _buildTextField(
                  controller: _venueController,
                  label: 'Venue',
                  hint: 'e.g., Etihad Stadium',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),

                // Date & Time
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimeField(
                        label: 'Match Date',
                        value: _matchDate != null
                            ? DateFormat('MMM dd, yyyy').format(_matchDate!)
                            : null,
                        icon: Icons.calendar_today,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _matchDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: widget.tournament.endDate,
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
                          if (date != null) {
                            setState(() => _matchDate = date);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateTimeField(
                        label: 'Match Time',
                        value: _matchTime != null
                            ? _matchTime!.format(context)
                            : null,
                        icon: Icons.access_time,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _matchTime ?? TimeOfDay.now(),
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
                          if (time != null) {
                            setState(() => _matchTime = time);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                // Actions
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.lightGreyColor,
                          side: BorderSide(color: AppColors.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveMatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.whiteColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isEdit ? 'Update' : 'Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.smallBoldTextStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: AppTextStyles.bodyTextStyle,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.hintTextStyle,
            filled: true,
            fillColor: AppColors.inputFieldBgColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildDateTimeField({
    required String label,
    String? value,
    required IconData icon,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.inputFieldBgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Select',
                    style: value != null
                        ? AppTextStyles.bodyTextStyle
                        : AppTextStyles.hintTextStyle,
                  ),
                ),
                Icon(icon, size: 18, color: AppColors.unSelectedGreyColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_matchDate == null || _matchTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Combine date and time
      final matchDateTime = DateTime(
        _matchDate!.year,
        _matchDate!.month,
        _matchDate!.day,
        _matchTime!.hour,
        _matchTime!.minute,
      );

      // Calculate prediction close time (1 hour before match)
      final predictionCloseTime =
          matchDateTime.subtract(const Duration(hours: 1));

      final match = Match(
        id: widget.match?.id ?? '',
        tournamentId: widget.tournament.id,
        homeTeam: _homeTeamController.text,
        awayTeam: _awayTeamController.text,
        matchDate: matchDateTime,
        matchTime:
            '${_matchTime!.hour.toString().padLeft(2, '0')}:${_matchTime!.minute.toString().padLeft(2, '0')}',
        venue: _venueController.text,
        createdAt: widget.match?.createdAt ?? DateTime.now(),
        status: widget.match?.status ?? MatchStatus.upcoming,
        homeScore: widget.match?.homeScore,
        awayScore: widget.match?.awayScore,
        predictionCloseTime: predictionCloseTime,
        winner: widget.match?.winner,
      );

      if (widget.match == null) {
        // Add new match
        await EnhancedTournamentService.addMatch(
          tournamentId: widget.tournament.id,
          match: match,
        );
      } else {
        // Update existing match
        await EnhancedTournamentService.updateMatch(
          tournamentId: widget.tournament.id,
          match: match,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.match == null
                  ? 'Match added successfully'
                  : 'Match updated successfully',
            ),
            backgroundColor: AppColors.greenColor,
          ),
        );
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

