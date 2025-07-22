import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static late SharedPreferences sharedPreferences;

  //! Initialize shared preferences
  Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  //! Get String data from cache
  String? getDataString({required String key}) {
    return sharedPreferences.getString(key);
  }

  //! Save data to local storage using key-value pairs
  Future<bool> saveData({required String key, required dynamic value}) async {
    if (value == null) {
      print("Value is null for key: $key");
      return false; // Handle null case
    }

    if (value is bool) {
      return await sharedPreferences.setBool(key, value);
    }

    if (value is String) {
      return await sharedPreferences.setString(key, value);
    }

    if (value is int) {
      return await sharedPreferences.setInt(key, value);
    }

    if (value is double) {
      return await sharedPreferences.setDouble(key, value);
    }

    print("Unsupported data type: ${value.runtimeType}");
    return false; // Handle unsupported types
  }

  //! Get data from local storage using key
  dynamic getData({required String key}) {
    return sharedPreferences.get(key);
  }

  //! Remove data using a specific key
  Future<bool> removeData({required String key}) async {
    return await sharedPreferences.remove(key);
  }

  //! Check if key exists in local storage
  Future<bool> containsKey({required String key}) async {
    return sharedPreferences.containsKey(key);
  }

  //! Clear all data
  Future<bool> clearData() async {
    return sharedPreferences.clear();
  }

  //! Save any value type into shared preferences
  Future<bool> put({required String key, required dynamic value}) async {
    if (value == null) {
      print("Null value can't be saved for key: $key");
      return false; // Handle null case
    }

    if (value is String) {
      return await sharedPreferences.setString(key, value);
    } else if (value is bool) {
      return await sharedPreferences.setBool(key, value);
    } else if (value is int) {
      return await sharedPreferences.setInt(key, value);
    } else if (value is double) {
      return await sharedPreferences.setDouble(key, value);
    } else {
      print("Unsupported value type: ${value.runtimeType}");
      return false;
    }
  }

  //! Save user id specifically to shared preferences
  Future<bool> saveUserId(String id) async {
    // Check if id is null or empty
    if (id.isNotEmpty) {
      return await saveData(key: 'id', value: id);
    } else {
      print("Invalid ID provided.");
      return false;
    }
  }

  //! Retrieve user id from shared preferences
  String? getUserId() {
    return getDataString(key: 'id');
  }

  //! Save token data to shared preferences
  Future<bool> saveToken(String token) async {
    return await saveData(key: 'token', value: token);
  }

  //! Retrieve token from shared preferences
  String? getToken() {
    return getDataString(key: 'token');
  }
}
