import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.language,
          style: AppTextStyles.headingTextStyle3,
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.changeLanguage,
              style: AppTextStyles.subHeadingTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // Language Options
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildLanguageOption(
                    context,
                    l10n,
                    localeProvider,
                    const Locale('en'),
                    'English',
                    'English',
                  ),
                  const Divider(
                    color: AppColors.borderColor,
                    height: 1,
                  ),
                  _buildLanguageOption(
                    context,
                    l10n,
                    localeProvider,
                    const Locale('ar'),
                    'العربية',
                    'Arabic',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Current Language Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBgColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Language',
                        style: AppTextStyles.smallBoldTextStyle.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localeProvider.getLanguageName(localeProvider.currentLocale),
                    style: AppTextStyles.bodyTextStyle.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Text Direction: ${localeProvider.isArabic ? 'Right to Left (RTL)' : 'Left to Right (LTR)'}',
                    style: AppTextStyles.captionTextStyle.copyWith(
                      color: AppColors.lightGreyColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    AppLocalizations l10n,
    LocaleProvider localeProvider,
    Locale locale,
    String displayName,
    String description,
  ) {
    final isSelected = localeProvider.currentLocale == locale;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryColor.withValues(alpha: 0.2)
              : AppColors.cardBgColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            locale.languageCode.toUpperCase(),
            style: TextStyle(
              color: isSelected ? AppColors.primaryColor : AppColors.lightGreyColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
      title: Text(
        displayName,
        style: AppTextStyles.tileTitleTextStyle.copyWith(
          color: isSelected ? AppColors.primaryColor : Colors.white,
        ),
      ),
      subtitle: Text(
        description,
        style: AppTextStyles.captionTextStyle.copyWith(
          color: AppColors.lightGreyColor,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: AppColors.primaryColor,
            )
          : null,
      onTap: () {
        if (!isSelected) {
          localeProvider.setLocale(locale);
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language changed to $displayName'),
              backgroundColor: AppColors.primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
}
