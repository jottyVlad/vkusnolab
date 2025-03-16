import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'redirected_page.dart';
import 'registration.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _login() async {
    bool success = await _authService.login(
      _usernameController.text,
      _passwordController.text
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful!'))
      );
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) {
          return RedirectedPage();
        })
        );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid login or password'))
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
              _signup(context)
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
          'Welcome back!',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
        Text('Enter your creditial to login')
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
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _login, 
          child: Text(
            'Login',
            style: TextStyle(fontSize: 20),
          ),
        )
      ],
    );
  }

  _signup(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Don\'t have an account?'),
        TextButton(onPressed: () {Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return RegistrationPage();
            })
        );}, child: Text('Sign up'))
      ],
    );
  }
}