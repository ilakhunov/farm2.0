import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const _userRoleKey = 'user_role';
  static const _userIdKey = 'user_id';
  static const _userPhoneKey = 'user_phone';

  static Future<void> saveUser({
    required String role,
    required String id,
    required String phoneNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
    await prefs.setString(_userIdKey, id);
    await prefs.setString(_userPhoneKey, phoneNumber);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userPhoneKey);
  }

  static Future<String?> get userRole async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  static Future<String?> get userId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String?> get userPhone async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  static Future<bool> get isFarmer async {
    final role = await userRole;
    return role == 'farmer';
  }

  static Future<bool> get isShop async {
    final role = await userRole;
    return role == 'shop';
  }
}


