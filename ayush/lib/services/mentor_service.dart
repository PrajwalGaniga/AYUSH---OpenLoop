import 'package:shared_preferences/shared_preferences.dart';
import '../models/mentor_type.dart';

class MentorService {
  static const String _mentorKey = 'openloop_mentor';

  static Future<void> saveMentor(MentorType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mentorKey, type.name);
  }

  static Future<MentorType> loadMentor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_mentorKey);
    
    if (value == MentorType.sloth.name) {
      return MentorType.sloth;
    }
    
    return MentorType.rabbit; // Default
  }

  static Future<bool> isFirstVisit(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'first_visit_$screenKey';
    
    final hasVisited = prefs.getBool(key) ?? false;
    
    if (!hasVisited) {
      await prefs.setBool(key, true);
      return true;
    }
    
    return false;
  }

  static Future<void> resetFirstVisit(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'first_visit_$screenKey';
    await prefs.remove(key);
  }
}
