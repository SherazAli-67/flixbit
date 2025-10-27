import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Flixbit'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @scanner.
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get scanner;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offers;

  /// No description provided for @gifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get gifts;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @gamePredictions.
  ///
  /// In en, this message translates to:
  /// **'Game Predictions'**
  String get gamePredictions;

  /// No description provided for @predictMatchOutcomes.
  ///
  /// In en, this message translates to:
  /// **'Predict match outcomes and win prizes'**
  String get predictMatchOutcomes;

  /// No description provided for @activeTournaments.
  ///
  /// In en, this message translates to:
  /// **'Active Tournaments'**
  String get activeTournaments;

  /// No description provided for @startPredicting.
  ///
  /// In en, this message translates to:
  /// **'Start Predicting'**
  String get startPredicting;

  /// No description provided for @viewMatches.
  ///
  /// In en, this message translates to:
  /// **'View Matches'**
  String get viewMatches;

  /// No description provided for @qualificationProgress.
  ///
  /// In en, this message translates to:
  /// **'Qualification Progress'**
  String get qualificationProgress;

  /// No description provided for @qualifiedForFinalDraw.
  ///
  /// In en, this message translates to:
  /// **'Qualified for Final Draw!'**
  String get qualifiedForFinalDraw;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @predictions.
  ///
  /// In en, this message translates to:
  /// **'Predictions'**
  String get predictions;

  /// No description provided for @qrScanner.
  ///
  /// In en, this message translates to:
  /// **'QR Scanner'**
  String get qrScanner;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// No description provided for @flixbitBalance.
  ///
  /// In en, this message translates to:
  /// **'Flixbit Balance'**
  String get flixbitBalance;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No description provided for @buyFlixbitPoints.
  ///
  /// In en, this message translates to:
  /// **'Buy Flixbit Points'**
  String get buyFlixbitPoints;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @referrals.
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get referrals;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends and earn'**
  String get inviteFriends;

  /// No description provided for @shareReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Share Referral Code'**
  String get shareReferralCode;

  /// No description provided for @wheelOfFortune.
  ///
  /// In en, this message translates to:
  /// **'Wheel of Fortune'**
  String get wheelOfFortune;

  /// No description provided for @spinToWin.
  ///
  /// In en, this message translates to:
  /// **'Spin to win'**
  String get spinToWin;

  /// No description provided for @subscriptionPackages.
  ///
  /// In en, this message translates to:
  /// **'Subscription Packages'**
  String get subscriptionPackages;

  /// No description provided for @upgradeForMoreFeatures.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for more features'**
  String get upgradeForMoreFeatures;

  /// No description provided for @coupons.
  ///
  /// In en, this message translates to:
  /// **'Coupons'**
  String get coupons;

  /// No description provided for @viewCoupons.
  ///
  /// In en, this message translates to:
  /// **'View coupons'**
  String get viewCoupons;

  /// No description provided for @sellerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Seller Dashboard'**
  String get sellerDashboard;

  /// No description provided for @sellerOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get sellerOffers;

  /// No description provided for @videoAds.
  ///
  /// In en, this message translates to:
  /// **'Video Ads'**
  String get videoAds;

  /// No description provided for @tournaments.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get tournaments;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @soldFlixbit.
  ///
  /// In en, this message translates to:
  /// **'Sold Flixbits'**
  String get soldFlixbit;

  /// No description provided for @boughtFlixbit.
  ///
  /// In en, this message translates to:
  /// **'Bought Flixbits'**
  String get boughtFlixbit;

  /// No description provided for @redeemPoints.
  ///
  /// In en, this message translates to:
  /// **'Redeem Points'**
  String get redeemPoints;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @linkedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Linked Accounts'**
  String get linkedAccounts;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @tournamentPoints.
  ///
  /// In en, this message translates to:
  /// **'Tournament Points'**
  String get tournamentPoints;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Points Earned'**
  String get earned;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Points Spent'**
  String get spent;

  /// No description provided for @bought.
  ///
  /// In en, this message translates to:
  /// **'Points Bought'**
  String get bought;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'Points Sold'**
  String get sold;

  /// No description provided for @giftReceived.
  ///
  /// In en, this message translates to:
  /// **'Gift Received'**
  String get giftReceived;

  /// No description provided for @rewardEarned.
  ///
  /// In en, this message translates to:
  /// **'Reward Earned'**
  String get rewardEarned;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Points Refunded'**
  String get refunded;

  /// No description provided for @filterTransactions.
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get filterTransactions;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noTournamentPoints.
  ///
  /// In en, this message translates to:
  /// **'No tournament points available'**
  String get noTournamentPoints;

  /// No description provided for @convertPoints.
  ///
  /// In en, this message translates to:
  /// **'Convert Points'**
  String get convertPoints;

  /// No description provided for @convertPointsDescription.
  ///
  /// In en, this message translates to:
  /// **'Convert your tournament points to Flixbit points. Each tournament point is worth 5 Flixbit points.'**
  String get convertPointsDescription;

  /// No description provided for @pointsToConvert.
  ///
  /// In en, this message translates to:
  /// **'Points to Convert'**
  String get pointsToConvert;

  /// No description provided for @invalidPointsAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid points amount'**
  String get invalidPointsAmount;

  /// No description provided for @pointsConverted.
  ///
  /// In en, this message translates to:
  /// **'Points converted successfully'**
  String get pointsConverted;

  /// No description provided for @convert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convert;

  /// No description provided for @pointsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Points Breakdown'**
  String get pointsBreakdown;

  /// No description provided for @tournament.
  ///
  /// In en, this message translates to:
  /// **'Tournament'**
  String get tournament;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @qrScans.
  ///
  /// In en, this message translates to:
  /// **'QR Scans'**
  String get qrScans;

  /// No description provided for @allOffers.
  ///
  /// In en, this message translates to:
  /// **'All Offers'**
  String get allOffers;

  /// No description provided for @nearbyOffers.
  ///
  /// In en, this message translates to:
  /// **'Nearby Offers'**
  String get nearbyOffers;

  /// No description provided for @followedSellers.
  ///
  /// In en, this message translates to:
  /// **'Followed Sellers'**
  String get followedSellers;

  /// No description provided for @searchOffers.
  ///
  /// In en, this message translates to:
  /// **'Search Offers'**
  String get searchOffers;

  /// No description provided for @noOffersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No offers available'**
  String get noOffersAvailable;

  /// No description provided for @offerDetails.
  ///
  /// In en, this message translates to:
  /// **'Offer Details'**
  String get offerDetails;

  /// No description provided for @redeemOffer.
  ///
  /// In en, this message translates to:
  /// **'Redeem Offer'**
  String get redeemOffer;

  /// No description provided for @redeemNow.
  ///
  /// In en, this message translates to:
  /// **'Redeem Now'**
  String get redeemNow;

  /// No description provided for @showQRCode.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code to the seller'**
  String get showQRCode;

  /// No description provided for @couponCode.
  ///
  /// In en, this message translates to:
  /// **'Coupon Code'**
  String get couponCode;

  /// No description provided for @copyCouponCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Coupon Code'**
  String get copyCouponCode;

  /// No description provided for @couponCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Coupon code copied!'**
  String get couponCodeCopied;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @followSeller.
  ///
  /// In en, this message translates to:
  /// **'Follow Seller'**
  String get followSeller;

  /// No description provided for @followingSeller.
  ///
  /// In en, this message translates to:
  /// **'Following Seller'**
  String get followingSeller;

  /// No description provided for @unfollowSeller.
  ///
  /// In en, this message translates to:
  /// **'Unfollow Seller'**
  String get unfollowSeller;

  /// No description provided for @alreadyRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Already Redeemed'**
  String get alreadyRedeemed;

  /// No description provided for @offerRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Offer Redeemed!'**
  String get offerRedeemed;

  /// No description provided for @youEarnedPoints.
  ///
  /// In en, this message translates to:
  /// **'You earned {points} Flixbit points'**
  String youEarnedPoints(Object points);

  /// No description provided for @offerExpired.
  ///
  /// In en, this message translates to:
  /// **'Offer Expired'**
  String get offerExpired;

  /// No description provided for @offerNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Offer Not Started'**
  String get offerNotStarted;

  /// No description provided for @offerFullyRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Fully Redeemed'**
  String get offerFullyRedeemed;

  /// No description provided for @offerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Offer Unavailable'**
  String get offerUnavailable;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String validUntil(Object date);

  /// No description provided for @expiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days} days'**
  String expiresIn(Object days);

  /// No description provided for @redemptions.
  ///
  /// In en, this message translates to:
  /// **'Redemptions'**
  String get redemptions;

  /// No description provided for @viewCount.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get viewCount;

  /// No description provided for @conversionRate.
  ///
  /// In en, this message translates to:
  /// **'Conversion Rate'**
  String get conversionRate;

  /// No description provided for @myRedemptions.
  ///
  /// In en, this message translates to:
  /// **'My Redemptions'**
  String get myRedemptions;

  /// No description provided for @redemptionHistory.
  ///
  /// In en, this message translates to:
  /// **'Redemption History'**
  String get redemptionHistory;

  /// No description provided for @markAsUsed.
  ///
  /// In en, this message translates to:
  /// **'Mark as Used'**
  String get markAsUsed;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @usedOffer.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get usedOffer;

  /// No description provided for @unusedOffer.
  ///
  /// In en, this message translates to:
  /// **'Ready to Use'**
  String get unusedOffer;

  /// No description provided for @noRedemptionsYet.
  ///
  /// In en, this message translates to:
  /// **'No Redemptions Yet'**
  String get noRedemptionsYet;

  /// No description provided for @startRedeemingOffers.
  ///
  /// In en, this message translates to:
  /// **'Start redeeming offers to see them here'**
  String get startRedeemingOffers;

  /// No description provided for @createOffer.
  ///
  /// In en, this message translates to:
  /// **'Create Offer'**
  String get createOffer;

  /// No description provided for @createNewOffer.
  ///
  /// In en, this message translates to:
  /// **'Create New Offer'**
  String get createNewOffer;

  /// No description provided for @editOffer.
  ///
  /// In en, this message translates to:
  /// **'Edit Offer'**
  String get editOffer;

  /// No description provided for @offerTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer Title'**
  String get offerTitle;

  /// No description provided for @offerDescription.
  ///
  /// In en, this message translates to:
  /// **'Offer Description'**
  String get offerDescription;

  /// No description provided for @offerType.
  ///
  /// In en, this message translates to:
  /// **'Offer Type'**
  String get offerType;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @freeItem.
  ///
  /// In en, this message translates to:
  /// **'Free Item'**
  String get freeItem;

  /// No description provided for @buyOneGetOne.
  ///
  /// In en, this message translates to:
  /// **'Buy One Get One'**
  String get buyOneGetOne;

  /// No description provided for @cashback.
  ///
  /// In en, this message translates to:
  /// **'Cashback'**
  String get cashback;

  /// No description provided for @pointsReward.
  ///
  /// In en, this message translates to:
  /// **'Points Reward'**
  String get pointsReward;

  /// No description provided for @voucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get voucher;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectCategory;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @fashion.
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get fashion;

  /// No description provided for @electronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get electronics;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @sports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get sports;

  /// No description provided for @entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainment;

  /// No description provided for @beauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get beauty;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @discountPercentage.
  ///
  /// In en, this message translates to:
  /// **'Discount Percentage'**
  String get discountPercentage;

  /// No description provided for @discountAmount.
  ///
  /// In en, this message translates to:
  /// **'Discount Amount'**
  String get discountAmount;

  /// No description provided for @validFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid From'**
  String get validFrom;

  /// No description provided for @validUntilDate.
  ///
  /// In en, this message translates to:
  /// **'Valid Until'**
  String get validUntilDate;

  /// No description provided for @maxRedemptions.
  ///
  /// In en, this message translates to:
  /// **'Max Redemptions'**
  String get maxRedemptions;

  /// No description provided for @minPurchaseAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum Purchase Amount'**
  String get minPurchaseAmount;

  /// No description provided for @rewardPoints.
  ///
  /// In en, this message translates to:
  /// **'Reward Points'**
  String get rewardPoints;

  /// No description provided for @targetLocation.
  ///
  /// In en, this message translates to:
  /// **'Target Location'**
  String get targetLocation;

  /// No description provided for @targetRadius.
  ///
  /// In en, this message translates to:
  /// **'Target Radius (km)'**
  String get targetRadius;

  /// No description provided for @submitForApproval.
  ///
  /// In en, this message translates to:
  /// **'Submit for Approval'**
  String get submitForApproval;

  /// No description provided for @offerSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Offer submitted for approval'**
  String get offerSubmitted;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingApproval;

  /// No description provided for @pendingAdminApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Admin Approval'**
  String get pendingAdminApproval;

  /// No description provided for @offerPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your offer will be pending until approved by admin. This usually takes 24-48 hours.'**
  String get offerPendingMessage;

  /// No description provided for @addTerm.
  ///
  /// In en, this message translates to:
  /// **'Add Term'**
  String get addTerm;

  /// No description provided for @deleteTerm.
  ///
  /// In en, this message translates to:
  /// **'Delete Term'**
  String get deleteTerm;

  /// No description provided for @enterTermOrCondition.
  ///
  /// In en, this message translates to:
  /// **'Enter term or condition'**
  String get enterTermOrCondition;

  /// No description provided for @activeOffers.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeOffers;

  /// No description provided for @pendingOffers.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingOffers;

  /// No description provided for @expiredOffers.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredOffers;

  /// No description provided for @draftOffers.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get draftOffers;

  /// No description provided for @noActiveOffers.
  ///
  /// In en, this message translates to:
  /// **'No active offers'**
  String get noActiveOffers;

  /// No description provided for @noPendingOffers.
  ///
  /// In en, this message translates to:
  /// **'No pending offers'**
  String get noPendingOffers;

  /// No description provided for @noExpiredOffers.
  ///
  /// In en, this message translates to:
  /// **'No expired offers'**
  String get noExpiredOffers;

  /// No description provided for @pauseOffer.
  ///
  /// In en, this message translates to:
  /// **'Pause Offer'**
  String get pauseOffer;

  /// No description provided for @activateOffer.
  ///
  /// In en, this message translates to:
  /// **'Activate Offer'**
  String get activateOffer;

  /// No description provided for @viewAnalytics.
  ///
  /// In en, this message translates to:
  /// **'View Analytics'**
  String get viewAnalytics;

  /// No description provided for @cloneOffer.
  ///
  /// In en, this message translates to:
  /// **'Clone Offer'**
  String get cloneOffer;

  /// No description provided for @deleteOffer.
  ///
  /// In en, this message translates to:
  /// **'Delete Offer'**
  String get deleteOffer;

  /// No description provided for @offerPaused.
  ///
  /// In en, this message translates to:
  /// **'Offer paused'**
  String get offerPaused;

  /// No description provided for @offerActivated.
  ///
  /// In en, this message translates to:
  /// **'Offer activated'**
  String get offerActivated;

  /// No description provided for @offerCloned.
  ///
  /// In en, this message translates to:
  /// **'Offer cloned successfully'**
  String get offerCloned;

  /// No description provided for @offerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Offer deleted'**
  String get offerDeleted;

  /// No description provided for @deleteOfferConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this offer? This action cannot be undone.'**
  String get deleteOfferConfirm;

  /// No description provided for @cloneOfferConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create a copy of this offer?'**
  String get cloneOfferConfirm;

  /// No description provided for @totalViews.
  ///
  /// In en, this message translates to:
  /// **'Total Views'**
  String get totalViews;

  /// No description provided for @totalRedemptions.
  ///
  /// In en, this message translates to:
  /// **'Total Redemptions'**
  String get totalRedemptions;

  /// No description provided for @offerAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Offer Analytics'**
  String get offerAnalytics;

  /// No description provided for @analyticsPageComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Analytics page coming soon'**
  String get analyticsPageComingSoon;

  /// No description provided for @locationPickerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Location picker coming soon'**
  String get locationPickerComingSoon;

  /// No description provided for @noLocationSet.
  ///
  /// In en, this message translates to:
  /// **'No location set (available everywhere)'**
  String get noLocationSet;

  /// No description provided for @locationSet.
  ///
  /// In en, this message translates to:
  /// **'Location set'**
  String get locationSet;

  /// No description provided for @setLocation.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setLocation;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeLocation;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get referralCode;

  /// No description provided for @referralCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Referral Code (Optional)'**
  String get referralCodeOptional;

  /// No description provided for @referralCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Have a referral code? Enter it here'**
  String get referralCodeHint;

  /// No description provided for @enterReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Enter referral code'**
  String get enterReferralCode;

  /// No description provided for @referralCodeApplied.
  ///
  /// In en, this message translates to:
  /// **'Referral code applied successfully!'**
  String get referralCodeApplied;

  /// No description provided for @invalidReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid referral code'**
  String get invalidReferralCode;

  /// No description provided for @referralCodeAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This referral code has already been used'**
  String get referralCodeAlreadyUsed;

  /// No description provided for @shareYourCode.
  ///
  /// In en, this message translates to:
  /// **'Share your referral code'**
  String get shareYourCode;

  /// No description provided for @inviteFriendsAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Invite friends and earn rewards'**
  String get inviteFriendsAndEarn;

  /// No description provided for @copyReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Referral Code'**
  String get copyReferralCode;

  /// No description provided for @referralCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Referral code copied to clipboard!'**
  String get referralCodeCopied;

  /// No description provided for @shareVia.
  ///
  /// In en, this message translates to:
  /// **'Share via'**
  String get shareVia;

  /// No description provided for @totalReferrals.
  ///
  /// In en, this message translates to:
  /// **'Total Referrals'**
  String get totalReferrals;

  /// No description provided for @activeFriends.
  ///
  /// In en, this message translates to:
  /// **'Active Friends'**
  String get activeFriends;

  /// No description provided for @pointsEarned.
  ///
  /// In en, this message translates to:
  /// **'Points Earned'**
  String get pointsEarned;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get yourReferralCode;

  /// No description provided for @referredUsers.
  ///
  /// In en, this message translates to:
  /// **'Referred Users'**
  String get referredUsers;

  /// No description provided for @noReferralsYet.
  ///
  /// In en, this message translates to:
  /// **'No referrals yet'**
  String get noReferralsYet;

  /// No description provided for @startReferringFriends.
  ///
  /// In en, this message translates to:
  /// **'Start referring friends to earn rewards'**
  String get startReferringFriends;

  /// No description provided for @alreadyRegisteredMessage.
  ///
  /// In en, this message translates to:
  /// **'You already have an account. Share your referral code with friends!'**
  String get alreadyRegisteredMessage;

  /// No description provided for @joinFlixbit.
  ///
  /// In en, this message translates to:
  /// **'Join me on Flixbit!'**
  String get joinFlixbit;
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
      <String>['ar', 'en'].contains(locale.languageCode);

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
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
