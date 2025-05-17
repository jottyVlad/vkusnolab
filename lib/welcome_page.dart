import 'package:flutter/material.dart';
import 'login.dart'; // Импорт страницы входа
import 'registration.dart'; // Импорт страницы регистрации

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Цвета из дизайна (приблизительно)
    const Color topGradientColor = Color(0xFFF9A825); // Яркий оранжево-желтый
    const Color bottomGradientColor = Color(0xFFFFD54F); // Более светлый желтый
    const Color buttonBackgroundColor = Color(0xFFFDF5E6); // Очень светлый желто-бежевый
    const Color buttonTextColor = Color.fromARGB(233, 212, 68, 49); // Красно-оранжевый для текста кнопок
    const Color titleColor = Color.fromARGB(255, 42, 41, 41); // Темно-серый для заголовка

    return Scaffold(
      body: Container(
        // Градиентный фон
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              topGradientColor,
              bottomGradientColor,
            ],
          ),
        ),
        child: SafeArea( // Чтобы контент не залезал под статус-бар
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Растягиваем кнопки
              children: [
                const Spacer(flex: 2), // Больше места сверху

                // --- Логотип/Изображение (Замените на свое изображение) ---
                // Используем иконку книги как временный плейсхолдер
                // const Icon(
                //   Image.asset("assets/Logo.png"), // Замените на Image.asset('assets/your_logo.png')
                //   size: 150,
                //   color: Colors.white70, // Белесая иконка
                // ),
                Image.asset("assets/Logo.png"),
                const SizedBox(height: 20),

                
                const SizedBox(height: 60), // Отступ перед кнопками

                // --- Кнопка "Вход" ---
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => LoginPage(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF3E9B5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Сильно скругленные углы
                    ),
                    elevation: 5, // Небольшая тень
                  ),
                  child: const Text(
                    'Вход',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: buttonTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => RegistrationPage(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                   style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF3E9B5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Сильно скругленные углы
                    ),
                     elevation: 5, // Небольшая тень
                  ),
                  child: const Text(
                    'Регистрация',
                     style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: buttonTextColor,
                    ),
                  ),
                ),

                 const Spacer(flex: 3), // Больше места снизу
              ],
            ),
          ),
        ),
      ),
    );
  }
} 