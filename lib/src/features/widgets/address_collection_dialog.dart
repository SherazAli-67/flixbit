import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/reward_redemption_model.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';

class AddressCollectionDialog extends StatefulWidget {
  final Function(DeliveryAddress) onAddressSubmitted;

  const AddressCollectionDialog({
    super.key,
    required this.onAddressSubmitted,
  });

  @override
  State<AddressCollectionDialog> createState() => _AddressCollectionDialogState();
}

class _AddressCollectionDialogState extends State<AddressCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _fullNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _selectedCountry = 'United States';

  final List<String> _countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
    'India',
    'Brazil',
    'Mexico',
    'Japan',
    'Other',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _phoneNumberController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 24,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      color: AppColors.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Delivery Address',
                        style: AppTextStyles.headingTextStyle3,
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.lightGreyColor,
                      ),
                    ),
                  ],
                ),
                
                Text(
                  'Please provide your delivery address for physical reward shipment',
                  style: AppTextStyles.bodyTextStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),

                // Full Name
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'Enter recipient name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter full name';
                    }
                    return null;
                  },
                ),

                // Address Line 1
                _buildTextField(
                  controller: _addressLine1Controller,
                  label: 'Address Line 1',
                  hint: 'Street address, P.O. box',
                  icon: Icons.home,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),

                // Address Line 2
                _buildTextField(
                  controller: _addressLine2Controller,
                  label: 'Address Line 2 (Optional)',
                  hint: 'Apartment, suite, unit, building, floor',
                  icon: Icons.apartment,
                  required: false,
                ),

                // City
                _buildTextField(
                  controller: _cityController,
                  label: 'City',
                  hint: 'Enter city',
                  icon: Icons.location_city,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
                ),

                // State/Province
                _buildTextField(
                  controller: _stateController,
                  label: 'State/Province',
                  hint: 'Enter state or province',
                  icon: Icons.map,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter state';
                    }
                    return null;
                  },
                ),

                // Postal Code
                _buildTextField(
                  controller: _postalCodeController,
                  label: 'Postal Code',
                  hint: 'Enter postal code',
                  icon: Icons.pin,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter postal code';
                    }
                    return null;
                  },
                ),

                // Country
                _buildDropdownField(
                  label: 'Country',
                  icon: Icons.public,
                  value: _selectedCountry,
                  items: _countries,
                  onChanged: (value) => setState(() => _selectedCountry = value!),
                ),

                // Phone Number
                _buildTextField(
                  controller: _phoneNumberController,
                  label: 'Phone Number (Optional)',
                  hint: 'Enter contact number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  required: false,
                ),

                // Delivery Instructions
                _buildTextField(
                  controller: _instructionsController,
                  label: 'Delivery Instructions (Optional)',
                  hint: 'Any special delivery instructions',
                  icon: Icons.notes,
                  maxLines: 3,
                  required: false,
                ),

                // Buttons
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.whiteColor,
                          side: BorderSide(color: AppColors.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.whiteColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Confirm'),
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
    required String hint,
    required IconData icon,
    bool required = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          label,
          style: AppTextStyles.smallBoldTextStyle,
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: required ? validator : null,
          style: AppTextStyles.bodyTextStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.smallTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
            prefixIcon: Icon(icon, color: AppColors.primaryColor),
            filled: true,
            fillColor: AppColors.inputFieldBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.errorColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          label,
          style: AppTextStyles.smallBoldTextStyle,
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputFieldBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: AppColors.cardBgColor,
            style: AppTextStyles.bodyTextStyle,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _submitAddress() {
    if (_formKey.currentState!.validate()) {
      final address = DeliveryAddress(
        fullName: _fullNameController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim().isEmpty 
            ? null 
            : _addressLine2Controller.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: _selectedCountry,
        phoneNumber: _phoneNumberController.text.trim().isEmpty 
            ? null 
            : _phoneNumberController.text.trim(),
        instructions: _instructionsController.text.trim().isEmpty 
            ? null 
            : _instructionsController.text.trim(),
      );

      widget.onAddressSubmitted(address);
      context.pop();
    }
  }
}
