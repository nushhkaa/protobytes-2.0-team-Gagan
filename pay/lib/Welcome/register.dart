import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/dashboard/dashboard.dart'; // Adjust if needed
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cryptography/cryptography.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '/secure_storage/secure_storage.dart';

class NewUserPage extends StatefulWidget {
  final String username;
  const NewUserPage({super.key, required this.username});

  @override
  State<NewUserPage> createState() => _NewUserPageState();
}

class _NewUserPageState extends State<NewUserPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _welcomeOffset;
  late TextEditingController _nameController;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _welcomeOffset = Tween<Offset>(
      begin: Offset(0, 1), // Slide up from bottom
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _nameController = TextEditingController();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<String> getDeviceId() async {
    final info = DeviceInfoPlugin();
    final android = await info.androidInfo;
    return android.id;
  }

  Future<void> _saveuser() async {
  final String registerUrl =
      'https://aaraticosmetics.com.np/nonet/user_register.php';
  final displayName = _nameController.text.trim();
  setState(() {
    _error = null;
  });

  if (displayName.isEmpty) {
    setState(() {
      _error = "Name cannot be empty!";
    });
    return;
  }

  setState(() => _isSaving = true);

  try {
    final username = widget.username;
    final name = displayName;

    // Get device ID
    String deviceId = await getDeviceId();
    if (deviceId.isEmpty) {
      setState(() {
        _error = "Couldn't get device ID.";
      });
      return;
    }

    // Generate Ed25519 Keypair
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    // Base64 for transmission/saving
    String generatedPublicKey = base64Encode(publicKey.bytes);
    String generatedPrivateKey = base64Encode(privateKeyBytes);

    // Send to server
    final response = await http.post(
      Uri.parse(registerUrl),
      body: {
        'username': username,
        'device_id': deviceId,
        'name': name,
        'public_key': generatedPublicKey,
      },
    );

    // Validate server response
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        // Save everything on success
        String balance = "0.00";
        await user_secureStorage.write(key: 'username', value: username);
        await user_secureStorage.write(key: 'device_id', value: deviceId);
        await user_secureStorage.write(key: 'name', value: name);
        await user_secureStorage.write(key: 'private_key', value: generatedPrivateKey);
        await user_secureStorage.write(key: 'public_key', value: generatedPublicKey);
        await user_secureStorage.write(key: 'balance', value: balance);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) =>
                DashboardPage(username: widget.username),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0, 1);
              const end = Offset(0, 0);
              final tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: Curves.easeInOut));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      } else {
        setState(() {
          _error = data['message'] ?? "Registration failed.";
        });
      }
    } else {
      setState(() {
        _error = "Network error: ${response.statusCode}";
      });
    }
  } catch (e) {
    setState(() {
      _error = "Failed to save. Please try again.";
    });
  } finally {
    setState(() => _isSaving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 206, 214, 223),
      body: SafeArea(
        child: Center(
          child: SlideTransition(
            position: _welcomeOffset,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Greeting
                  Text(
                    "Hey ${widget.username.toUpperCase()},",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Typing animation
                  AnimatedTextKit(
                    repeatForever: false,
                    isRepeatingAnimation: false,
                    totalRepeatCount: 1,
                    animatedTexts: [
                      TyperAnimatedText(
                        "You seem to be new here.\nWhat should we call you?",
                        textAlign: TextAlign.center,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.indigo[800],
                        ),
                        speed: const Duration(milliseconds: 20),
                      ),
                    ],
                    displayFullTextOnTap: true,
                    pause: const Duration(milliseconds: 100),
                  ),

                  const SizedBox(height: 30),

                  // Name input field
                  TextField(
                    controller: _nameController,
                    enabled: !_isSaving,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: "Enter your name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _saveuser(),
                  ),

                  const SizedBox(height: 15),

                  // Arrow button *below* field
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(10),
                        shape: const CircleBorder(),
                        backgroundColor: Colors.indigo[700],
                      ),
                      onPressed: _isSaving ? null : _saveuser,
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_circle_down_rounded,
                              size: 40, color: Colors.white),
                    ),
                  ),

                  // Error message
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
