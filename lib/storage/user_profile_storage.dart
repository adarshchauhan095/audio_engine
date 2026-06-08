import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserProfileStorage {
  static const String _userProfileKey = 'tinnitx_user_profile';
  static const String _userSessionsKey = 'tinnitx_user_sessions';

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(profile.toJson());
    await prefs.setString(_userProfileKey, jsonString);
  }

  Future<UserProfile> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_userProfileKey);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return UserProfile.fromJson(jsonMap);
      } catch (e) {
        // Fallback to default if parsing fails
        return UserProfile();
      }
    }
    return UserProfile(); // Default values
  }

  Future<void> saveUserSession(UserSessionRecord session) async {
    final prefs = await SharedPreferences.getInstance();
    List<UserSessionRecord> sessions = await getUserSessions();
    sessions.add(session);
    
    final List<Map<String, dynamic>> jsonList = sessions.map((s) => s.toJson()).toList();
    final String jsonString = jsonEncode(jsonList);
    await prefs.setString(_userSessionsKey, jsonString);
  }

  Future<List<UserSessionRecord>> getUserSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_userSessionsKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) => UserSessionRecord.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }
}
