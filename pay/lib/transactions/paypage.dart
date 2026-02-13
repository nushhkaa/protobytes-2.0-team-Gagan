import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '/secure_storage/secure_storage.dart';
import '/dashboard/dollarsign_background.dart';
import '/helpers/connection_status.dart';

class PayPage extends StatefulWidget {
  const PayPage({Key? key}) : super(key: key);

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  bool? _isOnline;
  late StreamSubscription<bool> _statusSubscription;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _loadingUser = true;
  String? _username;
  String? _balance;
  String? _privateKeyBase64;
  String? _error;
  String? _qrData;
  int? _enteredAmount;

  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _isOnline = ConnectionStatus().isOnline;
    _statusSubscription = ConnectionStatus().statusStream.listen((online) {
      setState(() {
        _isOnline = online;
      });
    });

    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final username = await user_secureStorage.read(key: 'username');
      final balance = await user_secureStorage.read(key: 'balance');
      final priv = await user_secureStorage.read(key: 'private_key');
      setState(() {
        _username = username?.toUpperCase();
        _balance = balance;
        _privateKeyBase64 = priv;
        _loadingUser = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load user data';
        _loadingUser = false;
      });
    }
  }

  Future<void> _generateQR() async {
    setState(() => _error = null);

    if (_formKey.currentState?.validate() != true) return;
    if (_username == null || _balance == null || _privateKeyBase64 == null) {
      setState(() => _error = "User info not loaded");
      return;
    }

    try {
      final amount = int.parse(_amountController.text.trim());
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final dataString = '$_username$amount$timestamp';
      final privBytes = base64Decode(_privateKeyBase64!);
      final algorithm = Ed25519();
      final keyPair =
          await algorithm.newKeyPairFromSeed(Uint8List.fromList(privBytes));
      final sig = await algorithm.sign(
        utf8.encode(dataString),
        keyPair: keyPair,
      );
      final signatureB64 = base64Encode(sig.bytes);

      final payload = {
        "username": _username,
        "amount": amount,
        "timestamp": timestamp,
        "signature": signatureB64,
      };
      final qrJson = jsonEncode(payload);

      setState(() {
        _qrData = qrJson;
        _enteredAmount = amount;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not generate/sign QR: $e';
        _qrData = null;
        _enteredAmount = null;
      });
    }
  }

  String _formatCurrentTime() {
    final now = _currentTime;
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final date =
        "${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";
    return "$hh:$mm:$ss   $date";
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pay')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pay')),
        body: Center(
            child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pay')),
      body: Stack(
        children: [
          const DollarScribbleBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        "Username: ${_username ?? '...'}",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Balance: ${_balance ?? '...'}",
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Time:" + _formatCurrentTime(),
                            style: const TextStyle(
                                fontSize: 20, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_qrData != null && _enteredAmount != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Column(
                      children: [
                        const Text("Amount",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text(
                          "Rs. $_enteredAmount",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 32,
                            color: Color.fromARGB(255, 48, 63, 159),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_qrData == null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Enter Amount",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Colors.indigo[700],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Form(
                                key: _formKey,
                                child: TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20),
                                  decoration: const InputDecoration(
                                    labelText: "Payment Amount",
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return "Amount required";
                                    }
                                    if (int.tryParse(v.trim()) == null ||
                                        int.parse(v.trim()) <= 0) {
                                      return "Enter a valid amount";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              Material(
                                color: const Color.fromARGB(255, 48, 63, 159),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _generateQR,
                                  child: const Padding(
                                    padding: EdgeInsets.all(18),
                                    child: Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 34,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_qrData != null) ...[
                  const SizedBox(height: 24),
                  const Text("Show this QR to the receiver",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black87)),
                  const SizedBox(height: 14),
                  QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: 340.0,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: Colors.black,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: const Color.fromARGB(255, 48, 63, 159),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SelectableText(
                      _qrData!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
