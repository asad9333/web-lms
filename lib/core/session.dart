import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'repo.dart';

class Session {
  Session._();

  static AppUser? user;
  static const String _key = 'logged_in_user_id';

  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_key);
    if (id == null) {
      user = null;
      return;
    }
    user = await Repo.userById(id);
    if (user == null) {
      await prefs.remove(_key);
    }
  }

  static Future<void> login(AppUser u) async {
    user = u;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, u.id);
  }

  static Future<void> refresh() async {
    final u = user;
    if (u == null) return;
    user = await Repo.userById(u.id);
  }

  static Future<void> logout() async {
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
