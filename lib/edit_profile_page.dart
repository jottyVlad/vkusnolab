import 'package:flutter/material.dart';
import 'profile_page.dart'; // Для навигации назад
import 'services/profile_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;
  File? _selectedImageFile;
  String? _profilePictureUrl;
  final ImagePicker _picker = ImagePicker();

  // Для смены пароля
  bool _showPasswordForm = false;
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; });
    try {
      final profile = await _profileService.getMe();
      _loginController.text = profile.username;
      _emailController.text = profile.email;
      _infoController.text = profile.bio;
      _profilePictureUrl = profile.profilePicture;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки профиля: $e')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() { _isLoading = true; });
      try {
        final profile = await _profileService.uploadProfilePicture(File(pickedFile.path));
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _profilePictureUrl = profile.profilePicture;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Фото профиля обновлено!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки фото: $e')),
        );
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _infoController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
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
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: avatarBgColor,
                    backgroundImage: _selectedImageFile != null
                        ? FileImage(_selectedImageFile!)
                        : (_profilePictureUrl != null && _profilePictureUrl!.isNotEmpty)
                            ? NetworkImage(_profilePictureUrl!) as ImageProvider
                            : null,
                    child: (_selectedImageFile == null && (_profilePictureUrl == null || _profilePictureUrl!.isEmpty))
                        ? const Icon(
                            Icons.person_outline,
                            size: 70,
                            color: primaryColor,
                          )
                        : null,
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
                        onPressed: _isLoading ? null : _pickAndUploadPhoto,
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
            _buildTextField(label: 'Имя (логин)', controller: _loginController, accentColor: accentColor, readOnly: true),
            const SizedBox(height: 20),
            _buildTextField(label: 'Email', controller: _emailController, accentColor: accentColor, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            _buildTextField(label: 'Доп. информация', controller: _infoController, accentColor: accentColor, maxLines: 4),
            const SizedBox(height: 40),

            // --- Кнопка Поменять пароль ---
            if (!_showPasswordForm)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    setState(() { _showPasswordForm = true; });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Поменять пароль'),
                ),
              ),

            if (_showPasswordForm)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      label: 'Старый пароль',
                      controller: _oldPasswordController,
                      accentColor: accentColor,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Новый пароль',
                      controller: _newPasswordController,
                      accentColor: accentColor,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        setState(() { _isLoading = true; });
                        try {
                          await _profileService.changePassword(
                            _oldPasswordController.text.trim(),
                            _newPasswordController.text.trim(),
                          );
                          setState(() { _showPasswordForm = false; });
                          _oldPasswordController.clear();
                          _newPasswordController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Пароль успешно изменён!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка смены пароля: $e')),
                          );
                        } finally {
                          setState(() { _isLoading = false; });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        setState(() { _showPasswordForm = false; });
                        _oldPasswordController.clear();
                        _newPasswordController.clear();
                      },
                      child: const Text('Отмена'),
                    ),
                  ],
                ),
              ),

            if (!_showPasswordForm)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      setState(() { _isLoading = true; });
                      try {
                        await _profileService.patchMe(
                          email: _emailController.text.trim(),
                          bio: _infoController.text.trim(),
                        );
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context, true);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Данные успешно обновлены!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка сохранения: $e')),
                        );
                      } finally {
                        setState(() { _isLoading = false; });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
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
    bool readOnly = false,
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
          readOnly: readOnly,
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