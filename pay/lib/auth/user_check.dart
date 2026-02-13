import 'dart:convert';
import 'package:http/http.dart' as http;
import '/secure_storage/secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cryptography/cryptography.dart';

const String apiUrl =
    "https://aaraticosmetics.com.np/nonet/user_check.php"; // Edit to your endpoint

class UserChecker {
  Future<String?> getDeviceId() async {
    final info = DeviceInfoPlugin();
    final android = await info.androidInfo;
    return android.id;
  }

  Future<bool> performChecks(String username) async {

     final String updateUrl =
      'https://aaraticosmetics.com.np/nonet/update_user.php';
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

          String? local_public_key =
              await user_secureStorage.read(key: 'public_key');
          String? local_deviceId = await getDeviceId();

          if (publicKey != local_public_key || deviceId != local_deviceId) {
            final algorithm = Ed25519();
            final keyPair = await algorithm.newKeyPair();
            final publicKey = await keyPair.extractPublicKey();
            final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

            String generatedPublicKey = base64Encode(publicKey.bytes);
            String generatedPrivateKey = base64Encode(privateKeyBytes);

            // Send to server
            final response = await http.post(
              Uri.parse(updateUrl),
              body: {
                'username': username,
                'device_id': deviceId,
                'public_key': generatedPublicKey,
              },
            );

            // Validate server response
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);

              if (data['status'] == 'success') {
                // Save everything on success
                await user_secureStorage.write(
                    key: 'username', value: username);
                await user_secureStorage.write(
                    key: 'device_id', value: deviceId);
                await user_secureStorage.write(
                    key: 'private_key', value: generatedPrivateKey);
                await user_secureStorage.write(
                    key: 'public_key', value: generatedPublicKey);
                await user_secureStorage.write(key: 'balance', value: balance);
              }
            }
          }

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
