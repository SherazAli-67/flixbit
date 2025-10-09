import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LinkedAccountsProvider extends ChangeNotifier{
  final String _isSellerAccountKey = 'isSeller';
  bool _isSellerAccount = false;

  bool get isSellerAccount => _isSellerAccount;

  LinkedAccountsProvider({bool? initialIsSellerAccount}){
    if (initialIsSellerAccount != null) {
      _isSellerAccount = initialIsSellerAccount;
    } else {
      _initSelectedAccountType();
    }
  }

  void _initSelectedAccountType() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isSellerAccount = prefs.getBool(_isSellerAccountKey) ?? false;
    notifyListeners();
  }

  void changeAccountType({required bool isSeller})async{
    _isSellerAccount = isSeller;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isSellerAccountKey, isSeller);

  }
}