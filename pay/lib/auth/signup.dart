import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '/helpers/connection_status.dart';
import '/helpers/status.dart';
import 'dart:async';

// --- Color Palette (as before) ---
const Color kPrimary = Color(0xFF3949ab);  // Indigo[600]
const Color kCardBg = Color(0xFFe3eafc);
const Color kBg = Color(0xFFedf2fb);
const Color kText = Color(0xFF283149);
const API_URL = "https://aaraticosmetics.com.np/nonet/";

// --- Preferred Input Width ---
const double inputFieldWidth = 280;

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

  bool? _isOnline;
  late StreamSubscription<bool> _statusSubscription;

    @override
  void initState() {
    super.initState();
    // Listen to global online/offline status
    _isOnline = ConnectionStatus().isOnline;
    _statusSubscription = ConnectionStatus().statusStream.listen((online) {
      setState(() {
        _isOnline = online;
      });
    });
  }

  @override
  void dispose() {
    _statusSubscription.cancel();
    super.dispose();
  }

  Future<void> showDialogBox(String title, String content) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: GoogleFonts.nunito(color: kPrimary)),
        content: Text(content, style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> sendOtp() async {

    if(_isOnline==true){

final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      showDialogBox("Error", "Please fill all fields");
      return;
    }
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();
    try {
      final response = await http.post(
        Uri.parse('${API_URL}signup.php'),
        body: {
          "username": username,
          "email": email,
          "password": hashedPassword,
        },
      );
      final result = response.body.trim();
      if (result == 'otp_sent') {
        showDialogBox("OTP Sent", "Check your email for the OTP");
      } else {
        showDialogBox("Error", result);
      }
    } catch (e) {
      showDialogBox("Error", e.toString());
    }
  }

  else{

      showDialogBox("Error", "No Internet Connection");


  }
    }

    

  Future<void> verifySignup() async {
    final username = usernameController.text.trim();
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      showDialogBox("Error", "Enter OTP to verify");
      return;
    }

      if (_isOnline==false) {
      showDialogBox("Error", "No Internet Connection");
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('${API_URL}verify_otp.php'),
        body: {
          "username": username,
          "otp": otp,
        },
      );
      final result = response.body.trim();
      if (result == 'success') {
        await showDialogBox("Signup Success", "You can now login");
        emailController.clear();
        passwordController.clear();
        otpController.clear();
        Navigator.pop(context);
      } else {
        showDialogBox("Error", result);
      }
    } catch (e) {
      showDialogBox("Error", e.toString());
    }
  }

  void goBackToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "NONET",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: kPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: kCardBg,
                elevation: 9,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 18, horizontal: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_rounded, color: kPrimary, size: 34),
                      const SizedBox(height: 2),
                      Text(
                        "Sign Up",
                        style: GoogleFonts.nunito(
                          color: kPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: SizedBox(
                          width: inputFieldWidth,
                          child: TextField(
                            controller: usernameController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: "Username",
                              hintStyle: GoogleFonts.nunito(
                                  fontSize: 15, color: kText.withAlpha(170)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: kPrimary, width: 1)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            style: GoogleFonts.nunito(fontSize: 15, color: kText),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: SizedBox(
                          width: inputFieldWidth,
                          child: TextField(
                            controller: emailController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: "Email",
                              hintStyle: GoogleFonts.nunito(
                                  fontSize: 15, color: kText.withAlpha(170)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: kPrimary, width: 1)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            style: GoogleFonts.nunito(fontSize: 15, color: kText),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: SizedBox(
                          width: inputFieldWidth,
                          child: TextField(
                            controller: passwordController,
                            obscureText: true,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: "Password",
                              hintStyle: GoogleFonts.nunito(
                                  fontSize: 15, color: kText.withAlpha(170)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: kPrimary, width: 1)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            style: GoogleFonts.nunito(fontSize: 15, color: kText),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: inputFieldWidth,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9)),
                          ),
                          onPressed: sendOtp,
                          child: Text(
                            "Send OTP",
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: SizedBox(
                          width: inputFieldWidth,
                          child: TextField(
                            controller: otpController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: "Enter OTP",
                              hintStyle: GoogleFonts.nunito(
                                  fontSize: 15, color: kText.withAlpha(170)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: kPrimary, width: 1)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            style: GoogleFonts.nunito(fontSize: 15, color: kText),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: inputFieldWidth,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9)),
                          ),
                          onPressed: verifySignup,
                          child: Text(
                            "Register",
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: goBackToLogin,
                        child: Text(
                          "Back to Login",
                          style: GoogleFonts.nunito(
                            color: kPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}