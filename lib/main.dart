import 'package:flutter/material.dart';
import 'package:vkusnolab/auth_service.dart';
import 'package:vkusnolab/home_page.dart';
import 'welcome_page.dart';   

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  bool isLoggedIn = false;

  try {
    isLoggedIn = await authService.verifyToken();
    if (!isLoggedIn) {
      isLoggedIn = await authService.refreshToken();
    }
  } catch (e) {
    print("Error checking token on startup: $e");
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VkusnoLab',
      theme: ThemeData(
        primaryColor: Color(0xFFE95322),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFF5CB58)),
      ),
      locale: Locale('ru'),
      home: isLoggedIn ? HomePage() : WelcomePage(),
    );
  }
}
