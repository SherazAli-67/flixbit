import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flixbit/src/models/seller_model.dart';
import 'package:flutter/cupertino.dart';

import '../res/firebase_constants.dart';

class SellerService {
  static Future<bool> createSellerAccount({required Seller seller})async {
    bool result = false;
    try{
      await FirebaseFirestore.instance.collection(FirebaseConstants.sellersCollection).doc(seller.id).set(seller.toJson());
      result = true;
    }catch(e){
      debugPrint("Error while creating seller account: ${e.toString()}");
    }

    return result;
  }
}