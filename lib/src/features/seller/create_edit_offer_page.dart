import 'package:flixbit/src/widgets/apptextfield_filled_widget.dart';
import 'package:flixbit/src/widgets/apptextfield_widget.dart';
import 'package:flixbit/src/widgets/date_picker_widget.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/offer_model.dart';
import '../../providers/seller_offers_provider.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';

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
  final List<String> _termsAndConditions = [];
  String? _imageUrl;
  String? _videoUrl;
  GeoPoint? _targetLocation;
  
  // State
  bool _isLoading = false;
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
      setState(() => _isLoading = false);
    }
    _rewardPointsController.text = '10'; // Default reward points
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
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: () => context.pop(),
        ),
        title: Text( _isEditMode ? 'Edit Offer' : 'Create New Offer',style: AppTextStyles.subHeadingTextStyle,),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 24,
            children: [
              // Info Banner
              _buildInfoBanner(),

              _buildSectionWidget(children: [
                Text('Basic Information', style: AppTextStyles.subHeadingTextStyle,),
                AppTextField(textController: _titleController, hintText: 'e.g., 20% off on all items', titleText: 'Offer Title*', ),
                AppTextFieldFilledWidget(
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
                _buildCategoryDropdown(),
              ]),


              _buildSectionWidget(
                children: [
                  // Offer Type & Discount
                  Text('Offer Type & Discount', style: AppTextStyles.subHeadingTextStyle,),
                  _buildOfferTypeSelector(),
                  if (_selectedType == OfferType.discount) ...[
                    Row(
                      children: [
                        Expanded(
                          child: AppTextFieldFilledWidget(
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
                          child: AppTextFieldFilledWidget(
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
                  AppTextFieldFilledWidget(controller: _discountCodeController, label: 'Coupon Code (Optional)',hint: 'e.g., SUMMER20',),
                ],
              ),

              _buildSectionWidget(
                children: [
                  // Validity Period
                  Text('Validity Period',style: AppTextStyles.subHeadingTextStyle,),
                  DatePickerWidget(validFrom: _validFrom,
                      onValidFromDatePicked: (DateTime validPickedDate) {
                        setState(() {
                          _validFrom = validPickedDate;
                          if (_validFrom.isAfter(_validUntil)) {
                            _validUntil = _validFrom.add(const Duration(days: 30));
                          }
                        });
                      },
                      validUntil: _validUntil,
                      onValidUntilDatePicked: (DateTime validUntilPickedDate)=> setState(()=> _validUntil = validUntilPickedDate))
                ],
              ),

              _buildSectionWidget(
                children: [
                  // Validity Period
                  Text('Redemption Settings',style: AppTextStyles.subHeadingTextStyle,),
                  _buildRedemptionSettings(),
                ],
              ),


              _buildSectionWidget(children: [
                // Location Targeting (Optional)
                Text('Location Targeting (Optional)',style: AppTextStyles.subHeadingTextStyle,),
                _buildLocationSettings(),
              ],),

              _buildSectionWidget(children: [
                // Location Targeting (Optional)
                Text('Terms & Conditions',style: AppTextStyles.subHeadingTextStyle,),
                _buildTermsSection(),
              ],),
              _buildActionButtons(),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionWidget({required List<Widget> children}) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: children
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        spacing: 12,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primaryColor,
            size: 24,
          ),
          Expanded(
            child: Text(
              'Your offer will be pending until approved by admin. This usually takes 24-48 hours.',
              style: AppTextStyles.bodyTextStyle.copyWith(color: AppColors.primaryColor,),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          'Category*',
          style: AppTextStyles.bodyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
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
      spacing: 12,
      children: [
        Text(
          'Select Offer Type*',
          style: AppTextStyles.bodyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OfferType.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text(_getOfferTypeName(type)),
              selected: isSelected,
              onSelected: (selected)=> setState(() =>_selectedType = type),
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


  Widget _buildRedemptionSettings() {
    return Column(
      spacing: 16,
      children: [
        AppTextFieldFilledWidget(
          controller: _maxRedemptionsController,
          label: 'Max Redemptions (Optional)',
          hint: 'Leave empty for unlimited',
          keyboardType: TextInputType.number,
        ),
        AppTextFieldFilledWidget(
          controller: _minPurchaseController,
          label: 'Minimum Purchase Amount (Optional)',
          hint: 'e.g., 100',
          keyboardType: TextInputType.number,
        ),
        AppTextFieldFilledWidget(
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
        Row(
          children: [
            Checkbox(
              value: _requiresReview,
              onChanged: (value)=> setState(()=>  _requiresReview = value ?? false),
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
            spacing: 12,
            children: [
              Icon(Icons.location_on, color: AppColors.primaryColor),
              Expanded(
                child: Row(
                  children: [
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
              )
            ],
          ),
        ),
        if (_targetLocation != null) ...[
          const SizedBox(height: 16),
          AppTextFieldFilledWidget(
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
      spacing: 8,
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
                    onPressed: () => setState(() =>  _termsAndConditions.removeAt(index)),
                  ),
                ],
              ),
            );
          }),
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
            onPressed: () => context.pop(),
            child: Text('Cancel', style: AppTextStyles.bodyTextStyle),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(()=> _termsAndConditions.add(controller.text.trim()));
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor,),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      spacing: 16,
      children: [
        Expanded(child: PrimaryBtn(btnText: 'Cancel', onTap: ()=> context.pop(), isLoading: _isLoading, bgColor: Colors.transparent, borderColor: AppColors.unSelectedGreyColor,)),
        Expanded(child: PrimaryBtn(btnText: 'Submit for Approval', onTap: _submitOffer, isLoading: _isLoading,)),
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

    setState(()=> _isLoading = true);

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
          context.pop();
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
          _isLoading = false;
        });
      }
    }
  }
}