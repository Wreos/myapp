import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// Welcome message shown on the auth screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to NextU'**
  String get welcomeToNextU;

  /// Subtitle shown on the auth screen
  ///
  /// In en, this message translates to:
  /// **'Your AI Career Coach'**
  String get aiCareerCoach;

  /// Title for the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Label for language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Label for email sign in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// Label for Google sign in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Label for Apple sign in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// Label for sign in action
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Label for sign up action
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Label for email field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Hint text for email field
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// Hint text for password field
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// Text for switching to sign in
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get alreadyHaveAccount;

  /// Text for switching to sign up
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccount;

  /// Validation message for empty email
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// Validation message for invalid email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// Validation message for empty password
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Validation message for short password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// Title for auth requirement dialog
  ///
  /// In en, this message translates to:
  /// **'Sign in Required'**
  String get signInRequired;

  /// Message for auth requirement dialog
  ///
  /// In en, this message translates to:
  /// **'Please sign in to use this feature'**
  String get pleaseSignInFeature;

  /// Label for cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Label for CV upload button
  ///
  /// In en, this message translates to:
  /// **'Upload CV'**
  String get uploadCV;

  /// Message shown while analyzing CV
  ///
  /// In en, this message translates to:
  /// **'Analyzing your CV...'**
  String get analyzingCV;

  /// Title for CV upload section
  ///
  /// In en, this message translates to:
  /// **'Upload your CV for analysis'**
  String get uploadCVAnalysis;

  /// Subtitle for CV upload section
  ///
  /// In en, this message translates to:
  /// **'Get detailed feedback and insights'**
  String get getDetailedFeedback;

  /// Label for CV strength section
  ///
  /// In en, this message translates to:
  /// **'CV Strength'**
  String get cvStrength;

  /// Label for technical skills section
  ///
  /// In en, this message translates to:
  /// **'Technical Skills'**
  String get technicalSkills;

  /// Label for experience section
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// Label for CV clarity section
  ///
  /// In en, this message translates to:
  /// **'CV Clarity'**
  String get cvClarity;

  /// Label for market fit section
  ///
  /// In en, this message translates to:
  /// **'Market Fit'**
  String get marketFit;

  /// Label for current position section
  ///
  /// In en, this message translates to:
  /// **'Current Position'**
  String get currentPosition;

  /// Label for recruiter's feedback section
  ///
  /// In en, this message translates to:
  /// **'Recruiter\'s Feedback'**
  String get recruitersFeedback;

  /// Label for CV structure section
  ///
  /// In en, this message translates to:
  /// **'CV Structure'**
  String get cvStructure;

  /// Label for improvements section
  ///
  /// In en, this message translates to:
  /// **'Recommended Improvements'**
  String get recommendedImprovements;

  /// Label for salary insights section
  ///
  /// In en, this message translates to:
  /// **'Salary Insights'**
  String get salaryInsights;

  /// Label for analyze another CV button
  ///
  /// In en, this message translates to:
  /// **'Analyze Another CV'**
  String get analyzeAnotherCV;

  /// Title for CV analysis error
  ///
  /// In en, this message translates to:
  /// **'Error analyzing CV'**
  String get errorAnalyzingCV;

  /// Label for try again button
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Message for excellent CV score
  ///
  /// In en, this message translates to:
  /// **'Excellent CV! Ready for top opportunities.'**
  String get excellentCV;

  /// Message for good CV score
  ///
  /// In en, this message translates to:
  /// **'Good CV with some room for improvement.'**
  String get goodCV;

  /// Message for CV needing improvement
  ///
  /// In en, this message translates to:
  /// **'CV needs several improvements.'**
  String get needsImprovement;

  /// Message for CV needing significant improvement
  ///
  /// In en, this message translates to:
  /// **'CV requires significant enhancement.'**
  String get needsSignificantImprovement;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
