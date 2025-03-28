import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'redirected_page.dart';
import 'auth_service.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>{
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _second_passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _registration() async {
    bool success = await _authService.registration(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
        _second_passwordController.text
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful!'))
      );
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return RedirectedPage();
          })
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match or registration failed'))
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          margin: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _header(context),
              _inputField(context),
            ],
          ),
        ),
      ),
    );
  }

  _header(context) {
    return Column(
      children: [
        Text(
          'Registration!',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  _inputField(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
            controller: _usernameController,
            decoration: InputDecoration(
                hintText: 'Username',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none),
                fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                filled: true
            )
        ),
        SizedBox(height: 10),
        TextField(
            controller: _emailController,
            decoration: InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none),
                fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                filled: true
            )
        ),
        SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
              hintText: 'Password',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              filled: true
          ),
          obscureText: true,
        ),
        SizedBox(height: 10),
        TextField(
          controller: _second_passwordController,
          decoration: InputDecoration(
              hintText: 'Repeat password',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              filled: true
          ),
          obscureText: true,
        ),
        SizedBox(height: 30),
        ElevatedButton(
          onPressed: _registration,
          child: Text(
            'Registration',
            style: TextStyle(fontSize: 20),
          ),
        )
      ],
    );
  }
}