import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/app_localizations.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();

  void _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'your_auth_token');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(loc.translate('login_title')),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 8.0),
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(hintText: loc.translate('enter_login')),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.translate('please_enter_email');
                    } else if (!RegExp(r'^[a-zA-Z0-9._]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(value)) {
                      return loc.translate('enter_valid_email'); // Локализованный текст
                    } else if (value.length > 30) {
                      return loc.translate('email_cannot_be_longer_than_30_chars');
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 8.0),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    hintText: loc.translate('enter_password'),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.length > 30) {
                      return loc.translate('password_cannot_be_longer_than_30_chars');
                    }
                    if (value != null && value.length < 6) {
                      return loc.translate('password_cannot_be_shorter_than_6_chars');
                    }
                    if (value != null && !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                      return loc.translate('password_letters_and_numbers_only');
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _login(context),
                child: Text(loc.translate('login_button')), // Локализованный текст
              ),
            ],
          ),
        ),
      ),
    );
  }
}