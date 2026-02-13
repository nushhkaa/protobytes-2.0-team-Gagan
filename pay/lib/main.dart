import 'package:flutter/material.dart';
import 'auth/login.dart';
import 'helpers/connection_status.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ConnectionStatus().initialize();
  runApp(AuthApp());
}

class AuthApp extends StatelessWidget {
  const AuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nonet',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}
