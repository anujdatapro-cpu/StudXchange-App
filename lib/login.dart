import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🔥 REAL FIREBASE LOGIN / SIGNUP
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLoginMode) {
        await AuthService().signIn(email: email, password: password);
      } else {
        await AuthService().register(email: email, password: password);
      }

      if (!mounted) return;

      await _sendLoginNotifications();
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendLoginNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) return;

    final name = user?.displayName?.trim().split(' ').first ?? email.split('@').first;
    final welcomeTitle = 'Welcome back, $name 👋';
    final welcomeMessage = 'Explore fresh campus deals and discover something great today.';

    try {
      await FirebaseService.addNotification(
        userEmail: email,
        title: welcomeTitle,
        message: welcomeMessage,
      );

      final prefs = await SharedPreferences.getInstance();
      final key = 'first_app_open_sent_${email.toLowerCase()}';
      final alreadySent = prefs.getBool(key) ?? false;
      if (!alreadySent) {
        await FirebaseService.addNotification(
          userEmail: email,
          title: 'Explore trending deals in your campus 🔥',
          message: 'Check out what other students are selling today.',
        );
        await prefs.setBool(key, true);
      }
    } catch (_) {
      // Ignore notification failures to keep login flow stable.
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
    });
  }

  InputDecoration _inputDecoration(String hint, IconData icon, AppThemeColors colors) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.secondaryText),
      prefixIcon: Icon(icon, color: colors.accent),
      filled: true,
      fillColor: colors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: colors.accent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                    Text(
                      "StudXchange",
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: colors.primaryText),
                      decoration: _inputDecoration(
                        "Email",
                        Icons.email_outlined,
                        colors,
                      ),
                      validator: (v) => v == null || !v.contains('@')
                          ? "Enter valid email"
                          : null,
                    ),

                    const SizedBox(height: 15),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: colors.primaryText),
                      decoration: _inputDecoration(
                        "Password",
                        Icons.lock_outline,
                        colors,
                      ),
                      validator: (v) =>
                          v == null || v.length < 6 ? "Min 6 characters" : null,
                    ),

                    const SizedBox(height: 20),

                    // Error
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[400]),
                      ),

                    const SizedBox(height: 20),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: colors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                color: colors.background,
                              )
                            : Text(
                                _isLoginMode ? "Login" : "Sign Up",
                                style: TextStyle(
                                  color: colors.background,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextButton(
                      onPressed: _toggleMode,
                      child: Text(
                        _isLoginMode
                            ? "Create new account"
                            : "Already have account? Login",
                        style: TextStyle(color: colors.accent),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
