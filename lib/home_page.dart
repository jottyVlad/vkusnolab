import 'package:flutter/material.dart';
import 'assistant_page.dart';
import 'create_recipe_page.dart';
import 'profile_page.dart';
import 'product_list.dart';
import 'recipe_details_page.dart';
import 'services/search_history_service.dart';
import 'auth_service.dart';

class Recipe {
    final String title;
    final String imageUrl;
    
    Recipe({required this.title, required this.imageUrl});
  }

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final SearchHistoryService _searchHistoryService = SearchHistoryService();
  final FocusNode _searchFocusNode = FocusNode();

  List<SearchHistory> _searchHistorySuggestions = [];
  bool _isLoadingHistory = false;
  String? _historyError;

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
    ),
    Recipe(
      title: 'Тушёная картошка с мясом и грибами',
      imageUrl: ''
    ),
    Recipe(
      title: 'Тушёная картошка с мясом и грибами',
      imageUrl: ''
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (_searchFocusNode.hasFocus && _searchHistorySuggestions.isEmpty && !_isLoadingHistory) {
        _loadSearchHistory();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final history = await _searchHistoryService.getSearchHistory();
      if (!mounted) return;
      setState(() {
        _searchHistorySuggestions = history;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка доступа к истории: ${e.message}'), backgroundColor: Colors.orange)
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = 'Не удалось загрузить историю поиска.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки истории поиска'), backgroundColor: Colors.red)
        );
      });
       print("History loading error: $e");
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _saveSearchQuery(String query) async {
    if (query.isEmpty) return;
    try {
      await _searchHistoryService.saveSearchQuery(query);
      _loadSearchHistory(); 
    } catch (e) {
      print("Failed to save search query '$query': $e");
    }
  }

  void _performSearch(String query) {
    final trimmedQuery = query.trim();
    print("Performing search for: $trimmedQuery");
    _saveSearchQuery(trimmedQuery);
    _searchFocusNode.unfocus(); 
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldShowHistoryOverlay = _searchFocusNode.hasFocus && 
                                          (_isLoadingHistory || _historyError != null || _searchHistorySuggestions.isNotEmpty);

    return Scaffold(
      backgroundColor: Color(0xFFF5CB58),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Color(0xFFF5CB58),
              padding: EdgeInsets.fromLTRB(22, 4, 22, 16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Поиск рецептов, пользователей',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (query) {
                  _performSearch(query);
                },
                onChanged: (value) {
                  setState(() {}); 
                 },
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    margin: EdgeInsets.only(top: 1), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Center(
                            child: Text(
                              'Рецепты',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEC9706),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: EdgeInsets.only(left: 24, right: 24, bottom: 16, top: 4),
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
                        ),
                      ],
                    ),
                  ),
                  if (shouldShowHistoryOverlay) 
                    Positioned(
                      top: 0,
                      left: 22,
                      right: 22,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        child: _buildSearchHistoryList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                onPressed: () {},
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
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => ProductListScreen()),
                  );
                },
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
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHistoryList() {
    if (_isLoadingHistory) {
      return Container(
          padding: EdgeInsets.all(16),
          height: 100,
          child: Center(child: CircularProgressIndicator())
      );
    }
    if (_historyError != null) {
      return Container(
          padding: EdgeInsets.all(16),
          height: 100,
          child: Center(child: Text(_historyError!, style: TextStyle(color: Colors.red)))
      );
    }
    if (_searchHistorySuggestions.isEmpty) {
      return Container(
          padding: EdgeInsets.all(16),
          height: 60,
          child: Center(child: Text('История поиска пуста.', style: TextStyle(color: Colors.grey)))
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 250,
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: _searchHistorySuggestions.length,
        itemBuilder: (context, index) {
          final historyItem = _searchHistorySuggestions[index];
          return ListTile(
            leading: Icon(Icons.history, color: Colors.grey),
            title: Text(historyItem.text),
            onTap: () {
              _searchController.text = historyItem.text;
              _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _searchController.text.length));
              _performSearch(historyItem.text);
            },
          );
        },
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsPage(recipe: recipe),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF3E9B5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  recipe.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.restaurant, size: 50, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  recipe.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 