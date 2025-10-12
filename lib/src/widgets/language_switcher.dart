import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../res/app_colors.dart';
import '../../l10n/app_localizations.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool showAsDialog;
  
  const LanguageSwitcher({
    super.key,
    this.showAsDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    if (showAsDialog) {
      return _buildDialog(context, l10n, localeProvider);
    }
    
    return _buildDropdown(context, l10n, localeProvider);
  }
  
  Widget _buildDropdown(BuildContext context, AppLocalizations l10n, LocaleProvider localeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: localeProvider.currentLocale,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryColor),
          isDense: true,
          items: LocaleProvider.supportedLocales.map((Locale locale) {
            return DropdownMenuItem<Locale>(
              value: locale,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localeProvider.getLanguageName(locale),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (Locale? newLocale) {
            if (newLocale != null) {
              localeProvider.setLocale(newLocale);
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildDialog(BuildContext context, AppLocalizations l10n, LocaleProvider localeProvider) {
    return AlertDialog(
      backgroundColor: AppColors.cardBgColor,
      title: Text(
        l10n.changeLanguage,
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: LocaleProvider.supportedLocales.map((Locale locale) {
          final isSelected = localeProvider.currentLocale == locale;
          return ListTile(
            leading: Radio<Locale>(
              value: locale,
              groupValue: localeProvider.currentLocale,
              onChanged: (Locale? value) {
                if (value != null) {
                  localeProvider.setLocale(value);
                  Navigator.of(context).pop();
                }
              },
              activeColor: AppColors.primaryColor,
            ),
            title: Text(
              localeProvider.getLanguageName(locale),
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: () {
              localeProvider.setLocale(locale);
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: const TextStyle(color: AppColors.primaryColor),
          ),
        ),
      ],
    );
  }
}

// Quick language toggle button
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    return IconButton(
      onPressed: () => localeProvider.toggleLanguage(),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          localeProvider.isEnglish ? 'ع' : 'EN',
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
