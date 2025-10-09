import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flixbit/src/res/firebase_constants.dart';
import 'package:flutter/cupertino.dart';

class ProfileProvider extends ChangeNotifier{
  bool _isRegisteredAsSeller = false;
  bool _loading = false;

  bool get isRegisteredAsSeller => _isRegisteredAsSeller;
  bool get loading => _loading;

  ProfileProvider(){
    _initUserInfo();
  }

  void _initUserInfo() async{

    try{
      _loading = true;
      notifyListeners();

      initSellerInfo();
      _loading = false;
      notifyListeners();

    }catch(e){
      debugPrint("Error while initializing profile provider: ${e.toString()}");
    }
  }

  void initSellerInfo() async{
    String userID = FirebaseAuth.instance.currentUser!.uid;
    final docSnap = await FirebaseFirestore.instance.collection(FirebaseConstants.sellersCollection).doc(userID).get();
    if(docSnap.exists){
      _isRegisteredAsSeller = true;
      notifyListeners();
    }
  }
}