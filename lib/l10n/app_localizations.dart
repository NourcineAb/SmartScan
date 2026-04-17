import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SmartScan'**
  String get appName;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Smart Document Scanning & OCR'**
  String get appSlogan;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SmartScan'**
  String get welcome;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @home_title.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_title;

  /// No description provided for @home_recent_scans.
  ///
  /// In en, this message translates to:
  /// **'Recent Scans'**
  String get home_recent_scans;

  /// No description provided for @home_quick_actions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get home_quick_actions;

  /// No description provided for @home_statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get home_statistics;

  /// No description provided for @scan_new.
  ///
  /// In en, this message translates to:
  /// **'New Scan'**
  String get scan_new;

  /// No description provided for @scan_from_camera.
  ///
  /// In en, this message translates to:
  /// **'Scan from Camera'**
  String get scan_from_camera;

  /// No description provided for @scan_from_gallery.
  ///
  /// In en, this message translates to:
  /// **'Import from Gallery'**
  String get scan_from_gallery;

  /// No description provided for @scan_document.
  ///
  /// In en, this message translates to:
  /// **'Scan Document'**
  String get scan_document;

  /// No description provided for @take_photo.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get take_photo;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @process.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get process;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @processing_ocr.
  ///
  /// In en, this message translates to:
  /// **'Extracting text...'**
  String get processing_ocr;

  /// No description provided for @processing_translation.
  ///
  /// In en, this message translates to:
  /// **'Translating...'**
  String get processing_translation;

  /// No description provided for @processing_categorization.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get processing_categorization;

  /// No description provided for @preview_title.
  ///
  /// In en, this message translates to:
  /// **'Preview & Crop'**
  String get preview_title;

  /// No description provided for @preview_adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust the image if needed'**
  String get preview_adjust;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @contrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get contrast;

  /// No description provided for @sharpness.
  ///
  /// In en, this message translates to:
  /// **'Sharpness'**
  String get sharpness;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @confirm_image.
  ///
  /// In en, this message translates to:
  /// **'Confirm Image'**
  String get confirm_image;

  /// No description provided for @result_title.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get result_title;

  /// No description provided for @original_text.
  ///
  /// In en, this message translates to:
  /// **'Original Text'**
  String get original_text;

  /// No description provided for @translated_text.
  ///
  /// In en, this message translates to:
  /// **'Translated Text'**
  String get translated_text;

  /// No description provided for @detected_language.
  ///
  /// In en, this message translates to:
  /// **'Detected Language'**
  String get detected_language;

  /// No description provided for @target_language.
  ///
  /// In en, this message translates to:
  /// **'Target Language'**
  String get target_language;

  /// No description provided for @translate_to.
  ///
  /// In en, this message translates to:
  /// **'Translate to'**
  String get translate_to;

  /// No description provided for @entities.
  ///
  /// In en, this message translates to:
  /// **'Extracted Entities'**
  String get entities;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @assign_category.
  ///
  /// In en, this message translates to:
  /// **'Assign Category'**
  String get assign_category;

  /// No description provided for @save_scan.
  ///
  /// In en, this message translates to:
  /// **'Save Scan'**
  String get save_scan;

  /// No description provided for @saved_successfully.
  ///
  /// In en, this message translates to:
  /// **'Scan saved successfully'**
  String get saved_successfully;

  /// No description provided for @scan_title.
  ///
  /// In en, this message translates to:
  /// **'Scan Title'**
  String get scan_title;

  /// No description provided for @enter_title.
  ///
  /// In en, this message translates to:
  /// **'Enter a title for this scan'**
  String get enter_title;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @created_at.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created_at;

  /// No description provided for @updated_at.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated_at;

  /// No description provided for @history_title.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history_title;

  /// No description provided for @history_empty.
  ///
  /// In en, this message translates to:
  /// **'No scans yet. Start by creating a new scan.'**
  String get history_empty;

  /// No description provided for @no_results.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get no_results;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @search_scans.
  ///
  /// In en, this message translates to:
  /// **'Search scans...'**
  String get search_scans;

  /// No description provided for @filter_by_category.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filter_by_category;

  /// No description provided for @filter_by_date.
  ///
  /// In en, this message translates to:
  /// **'Filter by date range'**
  String get filter_by_date;

  /// No description provided for @sort_by.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sort_by;

  /// No description provided for @sort_newest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sort_newest;

  /// No description provided for @sort_oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sort_oldest;

  /// No description provided for @delete_scan.
  ///
  /// In en, this message translates to:
  /// **'Delete scan'**
  String get delete_scan;

  /// No description provided for @edit_scan.
  ///
  /// In en, this message translates to:
  /// **'Edit scan'**
  String get edit_scan;

  /// No description provided for @view_details.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get view_details;

  /// No description provided for @confirm_delete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this scan?'**
  String get confirm_delete;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @dashboard_title.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard_title;

  /// No description provided for @total_scans.
  ///
  /// In en, this message translates to:
  /// **'Total Scans'**
  String get total_scans;

  /// No description provided for @scans_per_category.
  ///
  /// In en, this message translates to:
  /// **'Scans by Category'**
  String get scans_per_category;

  /// No description provided for @most_used_language.
  ///
  /// In en, this message translates to:
  /// **'Most Used Language'**
  String get most_used_language;

  /// No description provided for @recent_activity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recent_activity;

  /// No description provided for @stats_scans.
  ///
  /// In en, this message translates to:
  /// **'Scans'**
  String get stats_scans;

  /// No description provided for @stats_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get stats_categories;

  /// No description provided for @stats_languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get stats_languages;

  /// No description provided for @stats_storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get stats_storage;

  /// No description provided for @action_new_scan.
  ///
  /// In en, this message translates to:
  /// **'New Scan'**
  String get action_new_scan;

  /// No description provided for @action_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get action_history;

  /// No description provided for @action_translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get action_translation;

  /// No description provided for @action_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get action_categories;

  /// No description provided for @categories_title.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories_title;

  /// No description provided for @create_category.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get create_category;

  /// No description provided for @edit_category.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get edit_category;

  /// No description provided for @delete_category.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get delete_category;

  /// No description provided for @category_name.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get category_name;

  /// No description provided for @category_color.
  ///
  /// In en, this message translates to:
  /// **'Category Color'**
  String get category_color;

  /// No description provided for @category_icon.
  ///
  /// In en, this message translates to:
  /// **'Category Icon'**
  String get category_icon;

  /// No description provided for @custom_categories.
  ///
  /// In en, this message translates to:
  /// **'Custom Categories'**
  String get custom_categories;

  /// No description provided for @export_title.
  ///
  /// In en, this message translates to:
  /// **'Export & Share'**
  String get export_title;

  /// No description provided for @export_pdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get export_pdf;

  /// No description provided for @export_csv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get export_csv;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @share_via.
  ///
  /// In en, this message translates to:
  /// **'Share via'**
  String get share_via;

  /// No description provided for @save_to_gallery.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get save_to_gallery;

  /// No description provided for @copy_to_clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copy_to_clipboard;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied;

  /// No description provided for @export_success.
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get export_success;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_light;

  /// No description provided for @theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_dark;

  /// No description provided for @theme_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get theme_system;

  /// No description provided for @language_settings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language_settings;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @translation_settings.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation_settings;

  /// No description provided for @default_target_language.
  ///
  /// In en, this message translates to:
  /// **'Default Target Language'**
  String get default_target_language;

  /// No description provided for @sound_settings.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound_settings;

  /// No description provided for @enable_sounds.
  ///
  /// In en, this message translates to:
  /// **'Enable Sounds'**
  String get enable_sounds;

  /// No description provided for @enable_button_sounds.
  ///
  /// In en, this message translates to:
  /// **'Button Tap Sounds'**
  String get enable_button_sounds;

  /// No description provided for @vibration_settings.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration_settings;

  /// No description provided for @enable_vibration.
  ///
  /// In en, this message translates to:
  /// **'Enable Vibration'**
  String get enable_vibration;

  /// No description provided for @notification_settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notification_settings;

  /// No description provided for @enable_notifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enable_notifications;

  /// No description provided for @reminder_frequency.
  ///
  /// In en, this message translates to:
  /// **'Reminder Frequency'**
  String get reminder_frequency;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @storage_settings.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage_settings;

  /// No description provided for @cloud_sync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloud_sync;

  /// No description provided for @sync_now.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get sync_now;

  /// No description provided for @clear_all_data.
  ///
  /// In en, this message translates to:
  /// **'Clear All Local Data'**
  String get clear_all_data;

  /// No description provided for @confirm_clear.
  ///
  /// In en, this message translates to:
  /// **'This will delete all local data. Continue?'**
  String get confirm_clear;

  /// No description provided for @about_app.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about_app;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy_policy;

  /// No description provided for @terms_of_service.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get terms_of_service;

  /// No description provided for @error_camera_permission.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get error_camera_permission;

  /// No description provided for @error_storage_permission.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required'**
  String get error_storage_permission;

  /// No description provided for @error_notification_permission.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required'**
  String get error_notification_permission;

  /// No description provided for @error_ocr_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to extract text. Please try again.'**
  String get error_ocr_failed;

  /// No description provided for @error_translation_failed.
  ///
  /// In en, this message translates to:
  /// **'Translation failed. Please try again.'**
  String get error_translation_failed;

  /// No description provided for @error_network.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get error_network;

  /// No description provided for @error_offline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Some features may not work.'**
  String get error_offline;

  /// No description provided for @success_title.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success_title;

  /// No description provided for @success_scan_saved.
  ///
  /// In en, this message translates to:
  /// **'Scan saved successfully'**
  String get success_scan_saved;

  /// No description provided for @success_data_cleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared'**
  String get success_data_cleared;

  /// No description provided for @success_synced.
  ///
  /// In en, this message translates to:
  /// **'Synced successfully'**
  String get success_synced;

  /// No description provided for @entity_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get entity_date;

  /// No description provided for @entity_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get entity_address;

  /// No description provided for @entity_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get entity_phone;

  /// No description provided for @entity_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get entity_price;

  /// No description provided for @entity_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get entity_email;

  /// No description provided for @entity_url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get entity_url;

  /// No description provided for @entity_unknown.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get entity_unknown;

  /// No description provided for @set_reminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get set_reminder;

  /// No description provided for @reminder_set.
  ///
  /// In en, this message translates to:
  /// **'Reminder set for {date}'**
  String reminder_set(Object date);

  /// No description provided for @offline_badge.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline_badge;

  /// No description provided for @online_badge.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online_badge;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @last_synced.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {time}'**
  String last_synced(Object time);

  /// No description provided for @action_history_title.
  ///
  /// In en, this message translates to:
  /// **'Action History'**
  String get action_history_title;

  /// No description provided for @action_history_empty.
  ///
  /// In en, this message translates to:
  /// **'No actions recorded'**
  String get action_history_empty;

  /// No description provided for @actions_help_text.
  ///
  /// In en, this message translates to:
  /// **'The actions you perform will appear here'**
  String get actions_help_text;

  /// No description provided for @total_actions.
  ///
  /// In en, this message translates to:
  /// **'Total Actions'**
  String get total_actions;

  /// No description provided for @action_types.
  ///
  /// In en, this message translates to:
  /// **'Action Types'**
  String get action_types;

  /// No description provided for @search_actions.
  ///
  /// In en, this message translates to:
  /// **'Search actions...'**
  String get search_actions;

  /// No description provided for @action_not_found.
  ///
  /// In en, this message translates to:
  /// **'No actions found'**
  String get action_not_found;

  /// No description provided for @clear_history.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clear_history;

  /// No description provided for @delete_action.
  ///
  /// In en, this message translates to:
  /// **'Delete Action'**
  String get delete_action;

  /// No description provided for @confirm_delete_action.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this action?'**
  String get confirm_delete_action;

  /// No description provided for @action_deleted.
  ///
  /// In en, this message translates to:
  /// **'Action deleted'**
  String get action_deleted;

  /// No description provided for @history_cleared.
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get history_cleared;

  /// No description provided for @instant.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get instant;

  /// No description provided for @minutes_ago.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutes_ago(Object count);

  /// No description provided for @hours_ago.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hours_ago(Object count);

  /// No description provided for @days_ago.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String days_ago(Object count);

  /// No description provided for @categories_empty.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get categories_empty;

  /// No description provided for @no_documents_in_category.
  ///
  /// In en, this message translates to:
  /// **'No documents in this category yet'**
  String get no_documents_in_category;

  /// No description provided for @documents_count.
  ///
  /// In en, this message translates to:
  /// **'documents'**
  String get documents_count;

  /// No description provided for @new_category.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get new_category;

  /// No description provided for @category_created.
  ///
  /// In en, this message translates to:
  /// **'Category created'**
  String get category_created;

  /// No description provided for @category_updated.
  ///
  /// In en, this message translates to:
  /// **'Category updated'**
  String get category_updated;

  /// No description provided for @category_deleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get category_deleted;

  /// No description provided for @confirm_delete_category.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get confirm_delete_category;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @view_documents.
  ///
  /// In en, this message translates to:
  /// **'View Documents'**
  String get view_documents;

  /// No description provided for @system_language.
  ///
  /// In en, this message translates to:
  /// **'System Language'**
  String get system_language;

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change Application Language'**
  String get change_language;

  /// No description provided for @language_changed.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String language_changed(Object language);

  /// No description provided for @requires_restart.
  ///
  /// In en, this message translates to:
  /// **'The app will restart to apply the language change'**
  String get requires_restart;

  /// No description provided for @settings_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_appearance;

  /// No description provided for @settings_features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get settings_features;

  /// No description provided for @settings_advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settings_advanced;

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// No description provided for @settings_choose_theme.
  ///
  /// In en, this message translates to:
  /// **'Choose display mode'**
  String get settings_choose_theme;

  /// No description provided for @settings_app_language.
  ///
  /// In en, this message translates to:
  /// **'Application Language'**
  String get settings_app_language;

  /// No description provided for @settings_select_language.
  ///
  /// In en, this message translates to:
  /// **'Select your language'**
  String get settings_select_language;

  /// No description provided for @settings_target_language.
  ///
  /// In en, this message translates to:
  /// **'Translation Target Language'**
  String get settings_target_language;

  /// No description provided for @settings_default_translation.
  ///
  /// In en, this message translates to:
  /// **'Default language for translation'**
  String get settings_default_translation;

  /// No description provided for @settings_sounds.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get settings_sounds;

  /// No description provided for @settings_sound_effects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects for actions'**
  String get settings_sound_effects;

  /// No description provided for @settings_vibrations.
  ///
  /// In en, this message translates to:
  /// **'Vibrations'**
  String get settings_vibrations;

  /// No description provided for @settings_haptic_feedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback for actions'**
  String get settings_haptic_feedback;

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// No description provided for @settings_app_reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders to use the app'**
  String get settings_app_reminders;

  /// No description provided for @settings_cloud_sync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Synchronization'**
  String get settings_cloud_sync;

  /// No description provided for @settings_save_data_cloud.
  ///
  /// In en, this message translates to:
  /// **'Save your data to the cloud'**
  String get settings_save_data_cloud;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
