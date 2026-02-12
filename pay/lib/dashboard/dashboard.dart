
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dollarsign_background.dart';
import '/api/balance.dart';
import '/helpers/status.dart';
import '/helpers/connection_status.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/secure_storage/secure_storage.dart';



class DashboardPage extends StatefulWidget {
  final String username;
  const DashboardPage({
    super.key,
    required this.username,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool? _isOnline;
  late StreamSubscription<bool> _statusSubscription;

  bool isLoading = true;
  bool greetingShown = false;

  String? _result;
  String? _error;
  String? _as_of;
  bool _loading = false;

  void _getBalance() async {
    if (_isOnline == true) {
      final username = widget.username;
      setState(() {
        _loading = true;
        _error = null;
        _result = null;
      });
      try {
        final data = await UserApi.fetchUserInfo(username);
        setState(() => _result = data['balance'].toString());
        setState(() => _as_of = DateTime.now().toString());
        await user_secureStorage.write(key: 'balance', value: _result);
        await user_secureStorage.write(
            key: 'as_of', value: DateTime.now().toString());
      } catch (e) {
        setState(() => _error = e.toString());
      }
      setState(() {
        _loading = false;
      });
    } else {
      final storedbalance = await user_secureStorage.read(key: 'balance');
      final stored_as_of = await user_secureStorage.read(key: 'as_of');
      setState(() {
        _result = storedbalance;
        _as_of = stored_as_of;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getBalance();
    _isOnline = ConnectionStatus().isOnline; // initial value
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

  @override
  Widget build(BuildContext context) {
    final bool? isOnline = ConnectionStatus().isOnline; // get current status
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: DashboardAppBar(
          username: widget.username,
          greetingShown: greetingShown,
          onGreetingFinished: () => setState(() => greetingShown = true),
        ),
        body: Stack(
          children: [
            ConnectionStatusDot(isOnline: _isOnline),
            const DollarScribbleBackground(),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, kToolbarHeight + 32, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountBalanceCard(
                    isLoading: _loading, // or isLoading
                    accountBalance:
                        _result == null ? null : double.tryParse(_result!),
                    onRefresh: _getBalance,
                    isOnline: _isOnline,
                    asOf: _as_of, // <-- pass it in!
                  ),
                  const SizedBox(height: 20),
                  // Add additional cards/features below:
                  // RecentTransactions(),
                  // QuickActions(),
                  // etc.
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Sub-widgets ====================

// AppBar with animated greeting
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String username;
  final bool greetingShown;
  final VoidCallback onGreetingFinished;

  const DashboardAppBar({
    super.key,
    required this.username,
    required this.greetingShown,
    required this.onGreetingFinished,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: greetingShown
          ? Text(
              'Yo, ${username.toUpperCase()}!',
              style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.indigo[700],
              ),
            )
          : FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 750)),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox.shrink();
                }
                return AnimatedTextKit(
                  repeatForever: false,
                  isRepeatingAnimation: false,
                  totalRepeatCount: 1,
                  animatedTexts: [
                    TyperAnimatedText(
                      'Yo, ${username.toUpperCase()}!',
                      textStyle: GoogleFonts.nunito(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.indigo[700],
                      ),
                      speed: const Duration(milliseconds: 50),
                    ),
                  ],
                  onFinished: onGreetingFinished,
                );
              },
            ),
    );
  }
}

class AccountBalanceCard extends StatelessWidget {
  final bool isLoading;
  final double? accountBalance;
  final VoidCallback? onRefresh;
  final bool? isOnline; // <-- add this
  final String? asOf; // <-- NEW!

  const AccountBalanceCard({
    super.key,
    required this.isLoading,
    required this.accountBalance,
    required this.onRefresh,
    required this.isOnline, // <-- add this
    required this.asOf,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: const Color.fromARGB(255, 162, 196, 219),
      color: const Color.fromARGB(255, 210, 221, 238),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Account Balance",
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 50, 66, 73),
              ),
            ),
            const SizedBox(height: 8),
            // Row puts balance and refresh button on the same line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: isLoading
                      ? const SizedBox(
                          height: 36,
                          child: Center(child: CircularProgressIndicator()))
                      : Text(
                          accountBalance == null
                              ? "XXXX"
                              : "Rs.${accountBalance!.toStringAsFixed(2)}",
                          style: GoogleFonts.nunito(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.indigo[700],
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.indigo[600],
                  child: IconButton(
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 28),
                    onPressed: onRefresh,
                    tooltip: 'Refresh Balance',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isOnline == false && asOf != null)
              Padding(
                padding: const EdgeInsets.only(top: 2.0, left: 4.0),
                child: Text(
                  "Last synced: ${_formatAsOf(asOf!)}",
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.red[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (isOnline == false)
              Padding(
                padding: const EdgeInsets.only(left: 4.0, top: 3),
                child: Text(
                  "Showing last available balance (offline mode)",
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.red[400],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
 static String _formatAsOf(String asOf) {
    // Example: parse and format date/time, else just return as is.
    try {
      final dt = DateTime.parse(asOf);
      // Example format: '2024-07-31 20:38:25'
      return "${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}";
    } catch (_) {
      return asOf;
    }
  }
  static String _two(int x) => x.toString().padLeft(2, '0');
}
// ========== Add further widgets below for each new dashboard section ==========
/* 
Example:
class RecentTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card( ... );
  }
}
*/
