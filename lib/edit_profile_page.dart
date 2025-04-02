import 'package:flutter/material.dart';
import 'profile_page.dart'; // Для навигации назад

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();

  // TODO: Загрузить существующие данные пользователя в контроллеры

  @override
  void dispose() {
    _loginController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFE95322); // Основной оранжевый цвет
    const Color accentColor = Color(0xFFF3E9B5); // Цвет полей ввода
    const Color avatarBgColor = Color(0xFFFFC6AE); // Цвет фона аватара
    const Color backButtonBgColor = Color(0xFFE0E0E0); // Цвет фона кнопки назад (примерный)

    return Scaffold(
      backgroundColor: Colors.white, // Фон страницы
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Без тени
        leadingWidth: 80, // Увеличиваем ширину для круглого фона
        leading: Center( // Центрируем кнопку с фоном
          child: Container(
             margin: const EdgeInsets.only(left: 15), // Отступ слева
            decoration: const BoxDecoration(
              color: backButtonBgColor, // Светло-серый фон
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54, size: 20),
              onPressed: () {
                 // Переход назад на ProfilePage
                 // Используем pop, если пришли с ProfilePage через push
                 if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                 } else {
                    // Если не можем вернуться, переходим на ProfilePage как fallback
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                 }
              },
              tooltip: 'Назад',
            ),
          ),
        ),
        title: const Text(
          'Редактирование данных',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false, // Не центрируем заголовок
      ),
      body: SingleChildScrollView( // Позволяет прокручивать контент, если не влезает
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Растягиваем кнопку Сохранить
          children: [
            // --- Аватар с иконкой камеры ---
            Center(
              child: Stack(
                clipBehavior: Clip.none, // Позволяет иконке камеры выходить за пределы Stack
                alignment: Alignment.center,
                children: [
                  const CircleAvatar(
                    radius: 70,
                    backgroundColor: avatarBgColor,
                    child: Icon(
                      Icons.person_outline, // Используем outline иконку
                      size: 70,
                      color: primaryColor,
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 24),
                        onPressed: () {
                          // TODO: Добавить логику выбора/смены фото
                          print('Change photo pressed');
                        },
                         constraints: const BoxConstraints(), // Убираем лишние отступы
                         padding: const EdgeInsets.all(8), // Небольшой паддинг для иконки
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- Поля ввода ---
            _buildTextField(label: 'Имя', controller: _loginController, accentColor: accentColor),
            const SizedBox(height: 20),
            _buildTextField(label: 'Email', controller: _emailController, accentColor: accentColor, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            _buildTextField(label: 'Пароль', controller: _passwordController, accentColor: accentColor, obscureText: true),
            const SizedBox(height: 20),
            _buildTextField(label: 'Доп. информация', controller: _infoController, accentColor: accentColor, maxLines: 4),
            const SizedBox(height: 40),

            // --- Кнопка Сохранить ---
            ElevatedButton(
              onPressed: () {
                // TODO: Добавить логику сохранения данных
                print('Save pressed');
                // Возможно, вернуться на ProfilePage после сохранения
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Сильно скругленные углы
                ),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20), // Отступ снизу
          ],
        ),
      ),
    );
  }

  // Вспомогательный виджет для создания полей ввода
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Color accentColor,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: accentColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), // Скругление поля
              borderSide: BorderSide.none, // Убираем границу
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            isDense: true, // Уменьшаем высоту поля
          ),
        ),
      ],
    );
  }
} 