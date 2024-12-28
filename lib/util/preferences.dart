import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static Future setSharedValue(String key, String sharedVal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, sharedVal);
    print("${key} SET: ${sharedVal}");
  }

  static Future setListValue(String key, List<String> sharedVal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(key, sharedVal);
    print("${key} SET: ${sharedVal}");
  }

  static Future setSharedInt(String key, int sharedVal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(key, sharedVal);
    print("${key} SET: ${sharedVal}");
  }

  static Future getSharedValue(String key) async {
    SharedPreferences? prefs = await SharedPreferences.getInstance();
    String? sharedVal = prefs.getString(key);
    print("${key} GET: ${sharedVal}");
    return sharedVal;
  }

  static Future getListValue(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> sharedVal = prefs.getStringList(key) ?? [];
    print("${key} GET: ${sharedVal}");
    return sharedVal;
  }

  static Future getSharedInt(String key) async {
    SharedPreferences? prefs = await SharedPreferences.getInstance();
    int? sharedVal = prefs.getInt(key);
    print("${key} GET: ${sharedVal}");
    return sharedVal;
  }

  static Future clearPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }

  static Future clearSpecificPreferences(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }
}