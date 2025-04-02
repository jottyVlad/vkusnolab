import 'package:flutter/material.dart';
import 'home_page.dart'; // Импорт HomePage
import 'create_recipe_page.dart'; // Импорт CreateRecipePage
import 'assistant_page.dart'; // Импорт AssistantPage
import 'profile_page.dart'; // Импорт ProfilePage

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Пример данных (замените на ваши реальные данные)
    final List<String> products = [
      '120 г сливочного масла',
      '200 г творожного сыра',
      '20 г сливок жирностью 33%',
      '20 г сахарной пудры',
      // Добавьте больше продуктов или пустых строк для дизайна
      '', '', '', '', '', '', '',
    ];

    const Color primaryColor = Color(0xFFF37A3A); // Оранжевый цвет
    const Color backgroundColor = Color(0xFFFFF8E1); // Светло-желтый фон
    const Color itemBackgroundColor = Color(0xFFF5EAAA); // Цвет фона элемента списка
    const Color titleColor = primaryColor; // Цвет заголовка

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Список продуктов',
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor, // Фон AppBar как у основного фона
        elevation: 0, // Убрать тень AppBar
        automaticallyImplyLeading: false, // Убираем автоматическую кнопку "назад"
      ),
      body: Padding(
        // Отступы для всего списка
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final isEmptyItem = product.isEmpty;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6.0), // Отступы между элементами
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: itemBackgroundColor,
                borderRadius: BorderRadius.circular(20.0), // Скругленные углы
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded( // Чтобы текст занимал доступное место
                    child: Text(
                      product,
                      style: TextStyle(
                        fontSize: 18,
                        color: isEmptyItem ? Colors.transparent : Colors.black87, // Скрываем текст для пустых
                      ),
                      overflow: TextOverflow.ellipsis, // Обрезка текста, если не влезает
                    ),
                  ),
                  if (!isEmptyItem) // Показываем иконки только если элемент не пустой
                    Row(
                      mainAxisSize: MainAxisSize.min, // Уменьшаем размер Row до содержимого
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.black54),
                          onPressed: () {
                            // TODO: Добавить логику редактирования
                            print('Edit: $product');
                          },
                          constraints: const BoxConstraints(), // Убрать доп. паддинги IconButton
                          padding: const EdgeInsets.only(left: 8.0, right: 4.0), // Небольшой отступ
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.black54),
                          onPressed: () {
                            // TODO: Добавить логику удаления
                            print('Delete: $product');
                          },
                          constraints: const BoxConstraints(), // Убрать доп. паддинги IconButton
                          padding: const EdgeInsets.only(left: 4.0), // Небольшой отступ
                          iconSize: 20,
                        ),
                      ],
                    ),
                  if (isEmptyItem) // Заглушка для пустых элементов, чтобы сохранить высоту
                    const SizedBox(height: 24) // Примерная высота текста + иконок
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container( // Обертка для белого фона под скруглением
        color: backgroundColor, // Используем фон страницы, чтобы не было резкого перехода
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFE95322), // Цвет из home_page.dart
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 8), // Паддинг как в home_page.dart
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.white), // Используем home_outlined как в дизайне
                onPressed: () {
                   Navigator.of(context).pushReplacement(
                     MaterialPageRoute(builder: (context) => HomePage()), // Переход на HomePage
                   );
                }),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white), // Используем edit как в home_page
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => CreateRecipePage()), // Переход на CreateRecipePage
                  );
                }),
              IconButton(
                // Текущая страница, можно сделать иконку активной или оставить без onPressed
                icon: const Icon(Icons.shopping_cart, color: Colors.white), // Используем shopping_cart как в home_page
                onPressed: () {}, // На этой странице, поэтому действие не требуется
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white), // Используем chat_bubble_outline как в home_page
                 onPressed: () {
                   Navigator.of(context).pushReplacement(
                     MaterialPageRoute(builder: (context) => AssistantPage()), // Переход на AssistantPage
                   );
                 }),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white), // Используем person_outline как в home_page
                 onPressed: () {
                   Navigator.of(context).pushReplacement(
                     MaterialPageRoute(builder: (context) => ProfilePage()), // Переход на ProfilePage
                   );
                 }),
            ],
          ),
        ),
      ),
    );
  }
}