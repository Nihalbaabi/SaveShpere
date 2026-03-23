import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  String? currentUser;

  bool get isLoggedIn => currentUser != null && currentUser!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    currentUser = prefs.getString('userId');
    notifyListeners();
  }

  Future<bool> login(String userId, String password) async {
    if (userId.isEmpty || password.isEmpty) return false;
    
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('users').child(userId).child('password').get();
    
    if (snapshot.exists && snapshot.value == password) {
      currentUser = userId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }
}
