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
  videoAdsView('/video_ads_view'),
  wheelOfFortuneView('/wheel_of_fortune_view'),
  gamePredictionView('/game_predication_view'),
  tournamentMatchesView('/tournament_matches_view'),
  makePredictionView('/make_prediction_view'),
  buyFlixbitPointsView('/buy_flixbit_points_view'),

  //Reviews
  sellerProfileView('/seller_profile_view'),
  writeReviewView('/write_review_view'),
  mySellersView('/my_sellers_view'),
  reviewsListView('/reviews_list_view'),

  //BottomNav
  homeView('/home_view'),
  qrScannerView('/qr_scanner_view'),
  walletView('/wallet_view'),
  profileView('/profile_view');


  final String routeName;

  const RouterEnum(this.routeName);
}
