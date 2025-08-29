import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthToggleScreen extends StatefulWidget {
  const AuthToggleScreen({Key? key}) : super(key: key);

  @override
  _AuthToggleScreenState createState() => _AuthToggleScreenState();
}

class _AuthToggleScreenState extends State<AuthToggleScreen> {
  bool _showLogin = true;

  void _toggleView() {
    setState(() => _showLogin = !_showLogin);
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginScreen(onSwitchToRegister: _toggleView);
    } else {
      return RegisterScreen(onSwitchToLogin: _toggleView);
    }
  }
}
