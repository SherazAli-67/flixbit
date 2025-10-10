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

  uploadVideoAdView('/upload_video_ad_view'),
  videoDetailsView('/video_details_view'),
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

  //Profile pages
  linkedAccountsView('/linked_accounts_view'),

  //BottomNav
  homeView('/home_view'),
  qrScannerView('/qr_scanner_view'),
  walletView('/wallet_view'),
  profileView('/profile_view'),

  //Seller-only bottom nav
  sellerHomeView('/seller_home_view'),
  sellerOffersView('/seller_offers_view'),
  sellerVideoAdsView('/seller_video_ads_view'),
  sellerTournamentsView('/seller_tournaments_view'),
  sellerMainProfileView('/seller_main_profile_view');

  final String routeName;

  const RouterEnum(this.routeName);
}
