import 'package:flutter/material.dart';
import 'home_page.dart'; // Нужен для Recipe и навигации
import 'create_recipe_page.dart';
import 'product_list.dart';
import 'assistant_page.dart';
import 'profile_page.dart';

// Теперь страница принимает объект Recipe
class RecipeDetailsPage extends StatelessWidget {
  final Recipe recipe; // Добавляем поле для рецепта

  // Обновляем конструктор
  const RecipeDetailsPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    // --- Используем данные из recipe ---

    // Пример данных для ингредиентов и шагов (оставляем пока так, т.к. их нет в Recipe)
    // TODO: Добавить эти данные в модель Recipe и передавать их
    final List<String> mainIngredients = [
      '120 г сливочного масла;',
      '130 г сахара;',
      'ванильный сахар по вкусу;',
      '3 яйца;',
      '200 г муки;',
      '1½ чайной ложки\nразрыхлителя;', // Используем \n для переноса строки
      '1¼ чайной ложки соли;',
      '60 мл молока.',
    ];
     final List<String> creamIngredients = [
      '200 г творожного сыра;',
      '20 г сливок жирностью 33%;',
      '20 г сахарной пудры;',
    ];
    const String recipeSteps = 'Все ингредиенты для капкейков должны быть комнатной температуры...'; // Добавьте полный текст

    const Color primaryColor = Color(0xFFF37A3A); // Оранжевый
    const Color whiteBgColor = Colors.white;
    const Color textColor = Colors.black87;
    const Color titleColor = primaryColor;
    const Color lightBgColor = Color(0xFFFFF8E1); // Светло-желтый фон

    // Обработка переносов строк в заголовке
    final String displayTitle = recipe.title.replaceAll('\\n', '\n'); // Используем \n

    return Scaffold(
      backgroundColor: lightBgColor, // Устанавливаем фон Scaffold
      body: CustomScrollView( // Используем CustomScrollView для AppBar внутри списка
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 250.0, // Высота картинки
            pinned: false, // Не закрепляем AppBar при скролле
            backgroundColor: Color(0xFFF3E9B5), // Фон AppBar соответствует фону Scaffold
            elevation: 0,
            automaticallyImplyLeading: false, // Убираем стандартную кнопку назад
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // --- Изображение ---
                  ClipRRect(
                     borderRadius: const BorderRadius.vertical(
                       bottom: Radius.circular(0), // Скругляем только низ картинки
                     ),
                    child: Image.network(
                      // Используем recipe.imageUrl или заглушку, если URL пустой
                      recipe.imageUrl.isNotEmpty ? recipe.imageUrl : 'https://via.placeholder.com/600x400.png?text=No+Image',
                      fit: BoxFit.cover,
                       errorBuilder: (context, error, stackTrace) {
                         // Заглушка на случай ошибки загрузки
                         return Container(
                           decoration: const BoxDecoration(
                              color: Color(0xFFF3E9B5), // Цвет как у карточки
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
                           ),
                           alignment: Alignment.center,
                           child: const Icon(Icons.restaurant, size: 60, color: Colors.grey),
                         );
                       },
                    ),
                  ),
                  // --- Кнопка назад ---
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10, // Отступ сверху + статус бар
                    left: 15,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () {
                          // Используем pop, если страница была открыта через push
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                             // Если не можем вернуться (например, открыли как первую страницу),
                             // то переходим на HomePage
                             Navigator.of(context).pushReplacement(
                               MaterialPageRoute(builder: (context) => HomePage()),
                             );
                          }
                        },
                        tooltip: 'Назад',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // --- Основной контент ---
          SliverToBoxAdapter(
            child: Container(
              // Добавляем BoxDecoration для скругления и белого фона
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                // Переносим Padding сюда
                padding: const EdgeInsets.all(20.0),
                // Убираем BoxDecoration из этого Container, если он был
                // decoration: const BoxDecoration(
                //   color: Colors.white, // Явно задаем белый фон для контента
                // ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Заголовок ---
                    Center(
                      child: Text(
                        displayTitle, // Используем обработанный заголовок
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: titleColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.3, // Межстрочный интервал
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                     // Разделитель
                     Container(height: 2, color: primaryColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 20),

                    // --- Ингредиенты ---
                    const Text(
                      'Ингредиенты',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Список основных ингредиентов
                    _buildIngredientList(mainIngredients),
                    const SizedBox(height: 20),

                     // --- Ингредиенты для крема ---
                    const Text(
                      'Для крема и украшения:',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                     const SizedBox(height: 10),
                    _buildIngredientList(creamIngredients),
                    const SizedBox(height: 30),

                    // --- Кнопка "Добавить в корзину" ---
                     Center(
                       child: ElevatedButton(
                         onPressed: () {
                           // TODO: Добавить логику добавления ингредиентов в корзину (ProductList)
                           // Убираем переход на ProductListScreen
                           // Navigator.of(context).push(
                           //   MaterialPageRoute(builder: (context) => ProductListScreen()),
                           // );
                           print('Add to cart pressed - Navigation removed'); // Можно добавить для отладки
                         },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFFE95322),
                           padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(20),
                           ),
                           textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                         ),
                         child: const Text('Добавить в корзину', style: TextStyle(color: Colors.white)),
                       ),
                     ),
                    const SizedBox(height: 30),

                     // --- Рецепт ---
                     const Text(
                      'Рецепт',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      recipeSteps, // Используем заглушку для текста рецепта
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20), // Дополнительный отступ внизу перед BottomNavBar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // --- Нижняя панель навигации (копия из HomePage) ---
      bottomNavigationBar: Container(
        color: Colors.white, // Цвет фона под навигацией остается белым
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE95322), // Оранжевый цвет панели
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavBarIcon(context, Icons.home_outlined, HomePage()),
              _buildNavBarIcon(context, Icons.edit, CreateRecipePage()),
              _buildNavBarIcon(context, Icons.shopping_cart, ProductListScreen()),
              _buildNavBarIcon(context, Icons.chat_bubble_outline, AssistantPage()),
              _buildNavBarIcon(context, Icons.person_outline, ProfilePage()),
            ],
          ),
        ),
      ),
    );
  }

  // Вспомогательный виджет для отрисовки списка ингредиентов
  Widget _buildIngredientList(List<String> ingredients) {
    const Color primaryColor = Color(0xFFF37A3A); // Оранжевый цвет для иконок
    const Color textColor = Colors.black87; // Цвет текста

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ingredients.map((ingredient) {
        // Обработка переносов строк в ингредиентах
        final String displayIngredient = ingredient.replaceAll('\\n', '\n'); // Используем \n
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание по верху для многострочного текста
            children: [
              // Иконка перед текстом
              const Padding(
                padding: EdgeInsets.only(top: 3.0), // Небольшой отступ сверху для иконки
                child: Icon(Icons.radio_button_unchecked, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              // Используем Expanded, чтобы текст корректно переносился
              Expanded(
                child: Text(
                  displayIngredient, // Используем обработанный текст ингредиента
                  style: const TextStyle(fontSize: 16, color: textColor, height: 1.4),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

   // Вспомогательный метод для создания кнопок навигации
  Widget _buildNavBarIcon(BuildContext context, IconData icon, Widget targetPage) {
    // Сравниваем тип целевой страницы с типом текущего виджета (страницы)
    bool isCurrentPage = targetPage.runtimeType == runtimeType;

    // Пока все иконки одного цвета, активную не выделяем
    Color iconColor = Colors.white;

    return IconButton(
      icon: Icon(icon, color: iconColor),
      onPressed: () {
         // Не выполняем навигацию, если уже находимся на целевой странице
         if (!isCurrentPage) {
             Navigator.of(context).pushReplacement(
               // Используем pushReplacement для имитации переключения вкладок
               MaterialPageRoute(builder: (context) => targetPage),
             );
         }
      },
    );
  }
} 