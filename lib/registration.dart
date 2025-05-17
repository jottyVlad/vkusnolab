import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'home_page.dart';
import 'login.dart';

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

  bool _isLoading = false;

  void _registration() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    try {
      await _authService.registration(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
          _second_passwordController.text
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Регистрация прошла успешно!'))
      );
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => LoginPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );

    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red)
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Произошла неизвестная ошибка: $e'), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color appBarColor = Color(0xFFF5CB58);
    const Color primaryButtonColor = Color(0xFFE95322);
    const Color textFieldFillColor = Color(0xFFF3E9B5);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                 padding: const EdgeInsets.only(top: 80, bottom: 140),
                 width: double.infinity,
                 color: appBarColor, 
                 child: const Center(
                   child: Text(
                    'Регистрация',
                     style: TextStyle(
                       fontSize: 32,
                       fontWeight: FontWeight.bold,
                       color: Colors.white,
                     ),
                   ),
                 ),
              ),
            ],
          ),
           Positioned(
             top: 40,
             left: 10,
             child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                tooltip: 'Назад',
             ),
           ),
           Positioned(
            top: 180,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                 color: Colors.white, 
                 borderRadius: BorderRadius.only(
                   topLeft: Radius.circular(20),
                   topRight: Radius.circular(20),
                 ),
              ),
              child: SingleChildScrollView(
                 padding: EdgeInsets.all(24),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.stretch, 
                   children: [
                     SizedBox(height: 40),
                     
                     _buildTextField(label: 'Логин', controller: _usernameController, fillColor: textFieldFillColor),
                     const SizedBox(height: 20), 
                     _buildTextField(label: 'Email', controller: _emailController, fillColor: textFieldFillColor, keyboardType: TextInputType.emailAddress),
                     const SizedBox(height: 20),
                     _buildTextField(label: 'Пароль', controller: _passwordController, fillColor: textFieldFillColor, obscureText: true),
                     const SizedBox(height: 20),
                     _buildTextField(label: 'Повторите пароль', controller: _second_passwordController, fillColor: textFieldFillColor, obscureText: true),
                     const SizedBox(height: 32),
    
                     ElevatedButton(
                       onPressed: _isLoading ? null : _registration,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: primaryButtonColor,
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(30),
                         ),
                       ),
                       child: _isLoading
                           ? SizedBox(
                               width: 24, 
                               height: 24, 
                               child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                             )
                           : const Text(
                               'Зарегистрироваться',
                               style: TextStyle(
                                 fontSize: 18,
                                 color: Colors.white,
                               ),
                             ),
                     ),
                     const SizedBox(height: 20),
                   ],
                 ),
               ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Color fillColor,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            isDense: true,
          ),
        ),
      ],
    );
  }
}