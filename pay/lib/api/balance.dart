// user_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class UserApi {
  // Returns a Map with user info, throws on error
  static Future<Map<String, dynamic>> fetchUserInfo(String username) async {
    final url = 'https://aaraticosmetics.com.np/nonet/get_balance.php';
    final response = await http.post(
      Uri.parse(url),
      body: {'username': username},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['balance'] != null) {
      return data; // contains balance and username
    } else {
      throw data['error'] ?? 'Unknown error';
    }
  }
}
