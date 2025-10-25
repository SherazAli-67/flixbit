import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flixbit/src/res/app_icons.dart';
import 'package:flixbit/src/res/firebase_constants.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthenticationProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Initialize auth state listener
  AuthenticationProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      _errorMessage = 'Failed to load user data: $e';
    }
    notifyListeners();
  }

  // Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    File? profileImage,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        _setError('Failed to create user account');
        return false;
      }

/*// 👇 Refresh token to make sure Firebase Storage has the correct auth context
      final token = await user.getIdToken(true);
      debugPrint("ID token: $token");*/
      String profileImageUrl = '';
      if (profileImage != null) {
        profileImageUrl = await _uploadProfileImage(user.uid, profileImage);
      }

      // Create user model
      final userModel = UserModel(
        userID: user.uid,
        name: name,
        email: email,
        profileImg: profileImageUrl,
        createdAt: DateTime.now().toIso8601String()
      );

      await _firestore.collection(FirebaseConstants.usersCollection).doc(user.uid).set(userModel.toMap());
      _userModel = userModel;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("Exception while creating account: ${e.toString()}");
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint("Exception while creating account: ${e.toString()}");

      _setError('An unexpected error occurred: $e');
      _setLoading(false);
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        _setError('Failed to sign in');
        return false;
      }

      // Load user data
      await _loadUserData(user.uid);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred: $e');
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userModel = null;
      _clearError();
    } catch (e) {
      _setError('Failed to sign out: $e');
    }
    notifyListeners();
  }

  // Upload profile image to Firebase Storage
  Future<String> _uploadProfileImage(String userId, File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(userId) // must match rule structure
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get user-friendly error messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    File? profileImage,
  }) async {
    if (_user == null || _userModel == null) return false;

    try {
      _setLoading(true);
      _clearError();

      String profileImageUrl = _userModel!.profileImg;

      // Upload new profile image if provided
      if (profileImage != null) {
        profileImageUrl = await _uploadProfileImage(_user!.uid, profileImage);
      }

      // Update user model
      final updatedUserModel = UserModel(
        userID: _userModel!.userID,
        name: name ?? _userModel!.name,
        email: _userModel!.email,
        profileImg: profileImageUrl,
          createdAt: DateTime.now().toIso8601String()
      );

      // Update Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': updatedUserModel.name,
        'profileImg': updatedUserModel.profileImg,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      _userModel = updatedUserModel;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      _setLoading(false);
      return false;
    }
  }
}
