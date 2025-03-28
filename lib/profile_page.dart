import 'package:flutter/material.dart';
import 'home_page.dart';
import 'create_recipe_page.dart';
import 'assistant_page.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  // Временные данные для примера
  final List<Recipe> recipes = [
    Recipe(
      title: 'Капкейки с творожным кремом',
      imageUrl: ''
    ),
    Recipe(
      title: 'Тушёная картошка с мясом и грибами',
      imageUrl: ''
    ),
    Recipe(
      title: 'Тушёная картошка с мясом и грибами',
      imageUrl: ''
    ),
    Recipe(
      title: 'Тушёная картошка с мясом и грибами',
      imageUrl: ''
    ),
    Recipe(
      title: 'Тушёная картошка с мясом и грибами',
      imageUrl: ''
    ),
    Recipe(
      title: 'Тушёная картошка с мясом и грибами',
      imageUrl: ''
    ),
    Recipe(
      title: 'Тушёная картошка с мясом и грибами',
      imageUrl: ''
    ),
    Recipe(
      title: 'Тушёная картошка с мясом и грибами',
      imageUrl: ''
    ),
    Recipe(
      title: 'Тушёная картошка с мясом и грибами',
      imageUrl: ''
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFC6AE),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                // Верхняя часть с аватаром и именем
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 52,
                            color: Color(0xFFE95322),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Имя',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE95322),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Основной контент
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: EdgeInsets.only(left: 24, right: 24, bottom: 16, top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection('Обо мне', 'алолывлаылваывлалвалывлаыдлоллдолдьллдлвлфылвфыльвлофывлфывлфлд'),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Рецепты',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE95322),
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.only(top: 12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          return RecipeCard(recipe: recipes[index]);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Кнопка меню
            Positioned(
              right: 16,
              top: 40,
              child: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Color(0xFFE95322),
                  size: 30,
                ),
                onPressed: () {
                  // Обработчик нажатия на кнопку меню
                },
              ),
            ),
          ],
        ),
      ),
      // Нижняя навигация
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFE95322),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.home, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => CreateRecipePage()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => AssistantPage()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.person_outline, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF3E9B5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE95322),
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
} 