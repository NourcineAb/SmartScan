import 'package:flutter/material.dart';

class LocaleService {
  /// Obtenir tous les locales supportées
  static const List<Locale> supportedLocales = [
    Locale('en'), // Anglais
    Locale('fr'), // Français
    Locale('ar'), // Arabe
  ];

  /// Obtenir la locale par code
  static Locale getLocaleByCode(String code) {
    switch (code.toLowerCase()) {
      case 'fr':
        return const Locale('fr');
      case 'ar':
        return const Locale('ar');
      case 'en':
      default:
        return const Locale('en');
    }
  }

  /// Obtenir le code de langue de la locale
  static String getLocaleCode(Locale locale) {
    return locale.languageCode.toLowerCase();
  }

  /// Obtenir le nom de la langue
  static String getLanguageName(String code) {
    switch (code.toLowerCase()) {
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      case 'en':
      default:
        return 'English';
    }
  }

  /// Vérifier si la locale est RTL (Arabe)
  static bool isLocaleRTL(Locale locale) {
    return locale.languageCode.toLowerCase() == 'ar';
  }
}
