import 'package:flutter/material.dart';
import 'login.dart'; 
import 'registration.dart'; 

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
  
    const Color topGradientColor = Color(0xFFF9A825); 
    const Color bottomGradientColor = Color(0xFFFFD54F);
    const Color buttonBackgroundColor = Color(0xFFFDF5E6); 
    const Color buttonTextColor = Color.fromARGB(233, 212, 68, 49); 
    const Color titleColor = Color.fromARGB(255, 42, 41, 41); 

    return Scaffold(
      body: Container(
     
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
        child: SafeArea( 
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, 
              children: [
                const Spacer(flex: 2), 

           
                Image.asset("assets/Logo.png"),
                const SizedBox(height: 20),

                
                const SizedBox(height: 60), 

              
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
                      borderRadius: BorderRadius.circular(30), 
                    ),
                    elevation: 5, 
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
                      borderRadius: BorderRadius.circular(30),
                    ),
                     elevation: 5, 
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

                 const Spacer(flex: 3), 
              ],
            ),
          ),
        ),
      ),
    );
  }
} 