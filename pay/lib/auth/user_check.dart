import 'dart:convert';
import 'package:http/http.dart' as http;
import '/secure_storage/secure_storage.dart';
const String apiUrl =
    "https://aaraticosmetics.com.np/nonet/user_check.php"; // Edit to your endpoint

class UserChecker {
  Future<bool> performChecks(String username) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'username': username,
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          String deviceId = data['device_id'];
          String publicKey = data['public_key'];
          String balance = data['balance'];
          String name = data['name'];

          await user_secureStorage.write(key: 'balance', value: balance);








          return true;
        } else if (data['status'] == 'no user') {




          // User not found, "new" user
          return false;
        } else {
          // Unexpected status
          return false;
        }
      } else {
        // Server error
        return false;
      }
    } catch (e) {
      // Network error or JSON error
      print('UserChecker error: $e');
      return false;
    }
  }
}
