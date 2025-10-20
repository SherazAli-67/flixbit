import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../providers/video_upload_provider.dart';
import '../../widgets/primary_btn.dart';

class UploadVideoAdPage extends StatefulWidget {
  const UploadVideoAdPage({super.key});

  @override
  State<UploadVideoAdPage> createState() => _UploadVideoAdPageState();
}

class _UploadVideoAdPageState extends State<UploadVideoAdPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _rewardPointsController = TextEditingController();
  final _minWatchController = TextEditingController();
  final _sponsorshipController = TextEditingController();
  
  // Form state
  String? _selectedCategory;
  String? _selectedRegion;
  DateTime? _voteWindowStart;
  DateTime? _voteWindowEnd;
  bool _isContestEnabled = false;
  
  // Categories and regions
  final List<String> _categories = [
    'Food & Dining',
    'Fitness & Sports',
    'Entertainment',
    'Electronics',
    'Fashion',
    'Travel',
    'Other',
  ];
  
  final List<String> _regions = [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Riyadh',
    'Jeddah',
    'Karachi',
    'Lahore',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _rewardPointsController.dispose();
    _minWatchController.dispose();
    _sponsorshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VideoUploadProvider(),
      child: Scaffold(
        backgroundColor: AppColors.darkBgColor,
        appBar: AppBar(
          backgroundColor: AppColors.darkBgColor,
          elevation: 0,
          title: const Text('Upload Video Ad'),
        ),
        body: Consumer<VideoUploadProvider>(
          builder: (context, provider, child) {
            if (provider.isUploadComplete) {
              return _buildSuccessScreen(provider);
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upload Section
                    _buildUploadSection(provider),
                    const SizedBox(height: 30),
                    
                    // Video Details Section
                    _buildVideoDetailsSection(),
                    const SizedBox(height: 30),
                    
                    // Contest Settings Section
                    _buildContestSection(),
                    const SizedBox(height: 30),
                    
                    // Reward Settings Section
                    _buildRewardSection(),
                    const SizedBox(height: 30),
                    
                    // Error Message
                    if (provider.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                provider.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryBtn(
                        btnText: provider.isUploading
                            ? 'Uploading... ${(provider.uploadProgress * 100).toInt()}%'
                            : 'Submit for Approval',
                        onTap: provider.isUploading || !provider.hasSelectedFile
                            ? () {} // Disabled state
                            : () => _submitVideo(provider),
                        isLoading: provider.isUploading,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUploadSection(VideoUploadProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upload Video File', style: AppTextStyles.headingTextStyle3),
        const SizedBox(height: 16),
        
        GestureDetector(
          onTap: provider.isUploading ? null : () => provider.pickVideo(),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: provider.hasSelectedFile
                    ? AppColors.primaryColor
                    : AppColors.borderColor,
                width: 2,
              ),
            ),
            child: provider.hasSelectedFile
                ? _buildSelectedFilePreview(provider)
                : _buildEmptyUploadArea(),
          ),
        ),
        
        if (provider.isUploading) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: provider.uploadProgress,
            backgroundColor: AppColors.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyUploadArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 64,
          color: AppColors.unSelectedGreyColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Click to select video file',
          style: AppTextStyles.bodyTextStyle.copyWith(
            color: AppColors.unSelectedGreyColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'MP4, MOV, AVI up to 500MB',
          style: AppTextStyles.smallTextStyle.copyWith(
            color: AppColors.lightGreyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFilePreview(VideoUploadProvider provider) {
    final file = provider.selectedFile!;
    final fileSizeMB = (file.size / (1024 * 1024)).toStringAsFixed(2);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.video_file,
          size: 64,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            file.name,
            style: AppTextStyles.bodyTextStyle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$fileSizeMB MB',
          style: AppTextStyles.smallTextStyle.copyWith(
            color: AppColors.lightGreyColor,
          ),
        ),
        const SizedBox(height: 16),
        if (!provider.isUploading)
          TextButton.icon(
            onPressed: () => provider.clearSelection(),
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildVideoDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Video Details', style: AppTextStyles.headingTextStyle3),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _titleController,
          label: 'Video Title',
          hint: 'Enter video title',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'Enter video description',
          maxLines: 4,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Category',
                value: _selectedCategory,
                items: _categories,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown(
                label: 'Region',
                value: _selectedRegion,
                items: _regions,
                onChanged: (value) {
                  setState(() => _selectedRegion = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _durationController,
                label: 'Duration (seconds)',
                hint: 'e.g., 30',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _minWatchController,
                label: 'Min Watch Time (sec)',
                hint: 'e.g., 20',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contest Settings', style: AppTextStyles.headingTextStyle3),
        const SizedBox(height: 16),
        
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Enable Contest Mode', style: AppTextStyles.bodyTextStyle),
          subtitle: Text(
            'Allow users to vote on this video',
            style: AppTextStyles.smallTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
          ),
          value: _isContestEnabled,
          activeColor: AppColors.primaryColor,
          onChanged: (value) {
            setState(() => _isContestEnabled = value);
          },
        ),
        
        if (_isContestEnabled) ...[
          const SizedBox(height: 16),
          Text(
            'Voting Window',
            style: AppTextStyles.bodyTextStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          _buildDateTimePicker(
            label: 'Voting Start',
            selectedDate: _voteWindowStart,
            onChanged: (date) {
              setState(() => _voteWindowStart = date);
            },
          ),
          const SizedBox(height: 12),
          
          _buildDateTimePicker(
            label: 'Voting End',
            selectedDate: _voteWindowEnd,
            onChanged: (date) {
              setState(() => _voteWindowEnd = date);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRewardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reward Settings', style: AppTextStyles.headingTextStyle3),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _rewardPointsController,
                label: 'Reward Points',
                hint: '5',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _sponsorshipController,
                label: 'Sponsorship (\$)',
                hint: '100.00',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyTextStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyTextStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.hintTextStyle,
            filled: true,
            fillColor: AppColors.cardBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyTextStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.cardBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
          ),
          style: AppTextStyles.bodyTextStyle,
          dropdownColor: AppColors.cardBgColor,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null) {
              return 'Please select $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (time != null) {
            onChanged(DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            ));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate != null
                  ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${selectedDate.hour}:${selectedDate.minute.toString().padLeft(2, '0')}'
                  : label,
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: selectedDate != null
                    ? AppColors.whiteColor
                    : AppColors.lightGreyColor,
              ),
            ),
            Icon(Icons.calendar_today, color: AppColors.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(VideoUploadProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Video Submitted!',
            style: AppTextStyles.headingTextStyle2,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Your video has been submitted for admin approval. You will be notified once it\'s reviewed.',
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          PrimaryBtn(
            btnText: 'Back to Dashboard',
            onTap: () {
              provider.reset();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitVideo(VideoUploadProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get current user ID (seller)
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to upload videos')),
      );
      return;
    }

    final success = await provider.uploadVideo(
      sellerId: userId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      durationSeconds: int.parse(_durationController.text),
      category: _selectedCategory!,
      region: _selectedRegion!,
      rewardPoints: int.parse(_rewardPointsController.text),
      minWatchSeconds: int.parse(_minWatchController.text),
      contestEnabled: _isContestEnabled,
      voteWindowStart: _voteWindowStart,
      voteWindowEnd: _voteWindowEnd,
      sponsorshipAmount: _sponsorshipController.text.isNotEmpty
          ? double.tryParse(_sponsorshipController.text)
          : null,
    );

    if (success && mounted) {
      // Success screen will be shown automatically by the provider state
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Upload failed')),
      );
    }
  }
}
