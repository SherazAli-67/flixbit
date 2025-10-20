import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/offer_model.dart';
import '../../providers/seller_offers_provider.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../../l10n/app_localizations.dart';

class CreateEditOfferPage extends StatefulWidget {
  final String? offerId; // null for create, offerId for edit

  const CreateEditOfferPage({
    super.key,
    this.offerId,
  });

  @override
  State<CreateEditOfferPage> createState() => _CreateEditOfferPageState();
}

class _CreateEditOfferPageState extends State<CreateEditOfferPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _discountAmountController = TextEditingController();
  final _discountCodeController = TextEditingController();
  final _maxRedemptionsController = TextEditingController();
  final _minPurchaseController = TextEditingController();
  final _rewardPointsController = TextEditingController();
  final _radiusController = TextEditingController();
  
  // Form values
  OfferType _selectedType = OfferType.discount;
  String? _selectedCategory;
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  bool _requiresReview = false;
  List<String> _termsAndConditions = [];
  String? _imageUrl;
  String? _videoUrl;
  GeoPoint? _targetLocation;
  
  // State
  bool _loading = false;
  bool _isEditMode = false;
  
  final List<String> _categories = [
    'Food',
    'Fashion',
    'Electronics',
    'Health',
    'Sports',
    'Entertainment',
    'Beauty',
    'Travel',
    'Education',
    'Services',
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.offerId != null;
    if (_isEditMode) {
      _loadOfferData();
    }
    _rewardPointsController.text = '10'; // Default reward points
  }

  Future<void> _loadOfferData() async {
    // TODO: Load offer data for editing
    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountPercentageController.dispose();
    _discountAmountController.dispose();
    _discountCodeController.dispose();
    _maxRedemptionsController.dispose();
    _minPurchaseController.dispose();
    _rewardPointsController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Edit Offer' : 'Create New Offer',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              _buildInfoBanner(),
              
              const SizedBox(height: 24),
              
              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _titleController,
                label: 'Offer Title*',
                hint: 'e.g., 20% off on all items',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description*',
                hint: 'Describe your offer in detail',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              
              const SizedBox(height: 24),
              
              // Offer Type & Discount
              _buildSectionTitle('Offer Type & Discount'),
              const SizedBox(height: 16),
              _buildOfferTypeSelector(),
              
              const SizedBox(height: 16),
              _buildDiscountFields(),
              
              const SizedBox(height: 24),
              
              // Validity Period
              _buildSectionTitle('Validity Period'),
              const SizedBox(height: 16),
              _buildDatePickers(),
              
              const SizedBox(height: 24),
              
              // Redemption Settings
              _buildSectionTitle('Redemption Settings'),
              const SizedBox(height: 16),
              _buildRedemptionSettings(),
              
              const SizedBox(height: 24),
              
              // Location Targeting (Optional)
              _buildSectionTitle('Location Targeting (Optional)'),
              const SizedBox(height: 16),
              _buildLocationSettings(),
              
              const SizedBox(height: 24),
              
              // Terms & Conditions
              _buildSectionTitle('Terms & Conditions'),
              const SizedBox(height: 16),
              _buildTermsSection(),
              
              const SizedBox(height: 32),
              
              // Submit Buttons
              _buildActionButtons(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your offer will be pending until approved by admin. This usually takes 24-48 hours.',
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.subHeadingTextStyle,
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
        Text(
          label,
          style: AppTextStyles.bodyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyTextStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.unSelectedGreyColor,
            ),
            filled: true,
            fillColor: AppColors.cardBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryColor),
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

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category*',
          style: AppTextStyles.bodyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              hint: Text(
                'Select a category',
                style: AppTextStyles.bodyTextStyle.copyWith(
                  color: AppColors.unSelectedGreyColor,
                ),
              ),
              isExpanded: true,
              dropdownColor: AppColors.cardBgColor,
              style: AppTextStyles.bodyTextStyle,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Offer Type*',
          style: AppTextStyles.bodyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OfferType.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text(_getOfferTypeName(type)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedType = type;
                });
              },
              backgroundColor: AppColors.cardBgColor,
              selectedColor: AppColors.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.whiteColor : AppColors.unSelectedGreyColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getOfferTypeName(OfferType type) {
    switch (type) {
      case OfferType.discount:
        return 'Discount';
      case OfferType.freeItem:
        return 'Free Item';
      case OfferType.buyOneGetOne:
        return 'BOGO';
      case OfferType.cashback:
        return 'Cashback';
      case OfferType.points:
        return 'Points Reward';
      case OfferType.voucher:
        return 'Voucher';
    }
  }

  Widget _buildDiscountFields() {
    return Column(
      children: [
        if (_selectedType == OfferType.discount) ...[
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _discountPercentageController,
                  label: 'Discount Percentage',
                  hint: 'e.g., 20',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final percent = double.tryParse(value);
                      if (percent == null || percent < 0 || percent > 100) {
                        return 'Enter 0-100';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _discountAmountController,
                  label: 'OR Fixed Amount',
                  hint: 'e.g., 50',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Enter either percentage OR fixed amount, not both',
            style: AppTextStyles.captionTextStyle.copyWith(
              color: AppColors.unSelectedGreyColor,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildTextField(
          controller: _discountCodeController,
          label: 'Coupon Code (Optional)',
          hint: 'e.g., SUMMER20',
        ),
      ],
    );
  }

  Widget _buildDatePickers() {
    return Column(
      children: [
        _buildDatePickerField(
          label: 'Valid From',
          date: _validFrom,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _validFrom,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primaryColor,
                      surface: AppColors.cardBgColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _validFrom = picked;
                if (_validFrom.isAfter(_validUntil)) {
                  _validUntil = _validFrom.add(const Duration(days: 30));
                }
              });
            }
          },
        ),
        const SizedBox(height: 16),
        _buildDatePickerField(
          label: 'Valid Until',
          date: _validUntil,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _validUntil,
              firstDate: _validFrom,
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primaryColor,
                      surface: AppColors.cardBgColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _validUntil = picked;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primaryColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: AppTextStyles.bodyTextStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRedemptionSettings() {
    return Column(
      children: [
        _buildTextField(
          controller: _maxRedemptionsController,
          label: 'Max Redemptions (Optional)',
          hint: 'Leave empty for unlimited',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _minPurchaseController,
          label: 'Minimum Purchase Amount (Optional)',
          hint: 'e.g., 100',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _rewardPointsController,
          label: 'Reward Points',
          hint: 'Points users earn on redemption',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            final points = int.tryParse(value);
            if (points == null || points < 0) {
              return 'Enter valid points';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _requiresReview,
              onChanged: (value) {
                setState(() {
                  _requiresReview = value ?? false;
                });
              },
              activeColor: AppColors.primaryColor,
            ),
            Expanded(
              child: Text(
                'Require review for extra points',
                style: AppTextStyles.bodyTextStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSettings() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _targetLocation != null
                      ? 'Location set (${_targetLocation!.latitude.toStringAsFixed(4)}, ${_targetLocation!.longitude.toStringAsFixed(4)})'
                      : 'No location set (available everywhere)',
                  style: AppTextStyles.bodyTextStyle,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement location picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location picker coming soon'),
                      backgroundColor: AppColors.primaryColor,
                    ),
                  );
                },
                child: Text(
                  _targetLocation != null ? 'Change' : 'Set',
                  style: AppTextStyles.bodyTextStyle.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_targetLocation != null) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _radiusController,
            label: 'Target Radius (km)',
            hint: 'e.g., 5',
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }

  Widget _buildTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_termsAndConditions.isNotEmpty)
          ...List.generate(_termsAndConditions.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${index + 1}. ', style: AppTextStyles.bodyTextStyle),
                  Expanded(
                    child: Text(
                      _termsAndConditions[index],
                      style: AppTextStyles.bodyTextStyle,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        _termsAndConditions.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addTerm,
          icon: const Icon(Icons.add, color: AppColors.primaryColor),
          label: Text(
            'Add Term',
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ],
    );
  }

  void _addTerm() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: Text('Add Term', style: AppTextStyles.subHeadingTextStyle),
        content: TextField(
          controller: controller,
          style: AppTextStyles.bodyTextStyle,
          decoration: InputDecoration(
            hintText: 'Enter term or condition',
            hintStyle: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.unSelectedGreyColor,
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.bodyTextStyle),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _termsAndConditions.add(controller.text.trim());
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.unSelectedGreyColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonTextStyle.copyWith(
                color: AppColors.unSelectedGreyColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _loading ? null : _submitOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.whiteColor,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _isEditMode ? 'Update Offer' : 'Submit for Approval',
                    style: AppTextStyles.buttonTextStyle,
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate discount fields
    if (_selectedType == OfferType.discount) {
      final hasPercentage = _discountPercentageController.text.isNotEmpty;
      final hasAmount = _discountAmountController.text.isNotEmpty;

      if (!hasPercentage && !hasAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter discount percentage or amount'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (hasPercentage && hasAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter either percentage OR amount, not both'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _loading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final provider = Provider.of<SellerOffersProvider>(context, listen: false);

      final offer = await provider.createOffer(
        sellerId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        validFrom: _validFrom,
        validUntil: _validUntil,
        category: _selectedCategory,
        discountPercentage: _discountPercentageController.text.isNotEmpty
            ? double.parse(_discountPercentageController.text)
            : null,
        discountAmount: _discountAmountController.text.isNotEmpty
            ? double.parse(_discountAmountController.text)
            : null,
        discountCode: _discountCodeController.text.trim().isNotEmpty
            ? _discountCodeController.text.trim()
            : null,
        maxRedemptions: _maxRedemptionsController.text.isNotEmpty
            ? int.parse(_maxRedemptionsController.text)
            : null,
        minPurchaseAmount: _minPurchaseController.text.isNotEmpty
            ? double.parse(_minPurchaseController.text)
            : null,
        termsAndConditions: _termsAndConditions,
        requiresReview: _requiresReview,
        reviewPointsReward: int.parse(_rewardPointsController.text),
        targetLocation: _targetLocation,
        targetRadiusKm: _radiusController.text.isNotEmpty
            ? double.parse(_radiusController.text)
            : null,
        imageUrl: _imageUrl,
        videoUrl: _videoUrl,
      );

      if (offer != null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offer submitted for approval'),
              backgroundColor: AppColors.primaryColor,
            ),
          );
        }
      } else {
        throw Exception('Failed to create offer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}

