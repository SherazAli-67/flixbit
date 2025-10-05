enum RouterEnum {
  //auth and onboarding flow
  welcomeView('/welcome_view'),
  loginView('/login_view'),
  signupView('/signup_view'),
  forgetPassView('/forgetPass_view'),
  personalizationView('/personalization_view'),


  //Rest pages
  subscriptionView('/subscription_view'),
  rewardsView('/rewards_view'),
  offersView('/offers_view'),
  referralView('/referral_view'),
  wheelOfFortuneView('/wheel_of_fortune_view'),

  //BottomNav
  homeView('/home_view'),
  qrScannerView('/qr_scanner_view'),
  walletView('/wallet_view'),
  profileView('/profile_view');


  final String routeName;

  const RouterEnum(this.routeName);
}
