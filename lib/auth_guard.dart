import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  AuthGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    if (!appState.isAuthenticated) {
      // If not authenticated, navigate to the login page
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
      return Container(); // Return an empty container until the navigation completes
    }
    return child;
  }
}
