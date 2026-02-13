import 'package:flutter/material.dart';

class ConnectionStatusDot extends StatelessWidget {
  final bool? isOnline;
  const ConnectionStatusDot({required this.isOnline, super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.only(top: 28, right: 24),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 12,
              color: isOnline == null
                  ? Colors.grey
                  : (isOnline! ? Colors.green : Colors.red),
            ),
            const SizedBox(width: 7),
            Text(
              isOnline == null
                  ? "Checking..."
                  : (isOnline! ? "Online" : "Offline"),
              style: TextStyle(
                color: isOnline == null
                    ? Colors.grey
                    : (isOnline! ? Colors.green[800] : Colors.red[700]),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
