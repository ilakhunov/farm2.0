import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/models/auth_models.dart';

class UserStorage {
  static const _userKey = 'current_user';
  static const _userRoleKey = 'user_role';
  static const _userIdKey = 'user_id';

  static Future<void> saveUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, user.role);
    await prefs.setString(_userIdKey, user.id);
    // Save full user data as JSON string for future use
    await prefs.setString(_userKey, '${user.id}|${user.role}|${user.phoneNumber}');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userIdKey);
  }

  static Future<String?> get userRole async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  static Future<String?> get userId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
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

