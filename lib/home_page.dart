import 'package:flutter/material.dart';
import 'assistant_page.dart';
import 'create_recipe_page.dart';
import 'profile_page.dart';
import 'product_list.dart';
import 'recipe_details_page.dart';
import 'services/search_history_service.dart';
import 'auth_service.dart';
import 'services/recipe_service.dart';
import 'package:vkusnolab/models/user_profile.dart'; 
import 'package:vkusnolab/models/recipe_ingredient.dart'; 

class Recipe {
    final int id;
    final List<RecipeIngredient> ingredients;
    final UserProfile? author; 
    final String? image; 
    final String title;
    final String description;
    final String instructions;
    final int cookingTimeMinutes;
    final int servings;
    final DateTime? createdAt; 
    final DateTime? updatedAt; 
    final bool isActive; 
    final bool isPrivate;

    Recipe({
      required this.id,
      required this.ingredients,
      this.author,
      this.image,
      required this.title,
      required this.description,
      required this.instructions,
      required this.cookingTimeMinutes,
      required this.servings,
      this.createdAt,
      this.updatedAt,
      required this.isActive,
      required this.isPrivate,
    });

    // Factory constructor to create a Recipe from JSON
    factory Recipe.fromJson(Map<String, dynamic> json) {
      // Helper to safely parse DateTime
      DateTime? safeParseDateTime(String? dateString) {
          if (dateString == null) return null;
          try {
              return DateTime.parse(dateString);
          } catch (e) {
              print("Error parsing date: $dateString, Error: $e");
              return null;
          }
      }

      // Parse ingredients list
      List<RecipeIngredient> parsedIngredients = [];
      if (json['ingredients'] != null && json['ingredients'] is List) {
        try {
          parsedIngredients = (json['ingredients'] as List)
              .map((item) => RecipeIngredient.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (e) {
          print("Error parsing ingredients for recipe ID ${json['id']}: $e");
          // Keep parsedIngredients as empty list on error
        }
      } else {
          print("Warning: 'ingredients' field is null or not a list for recipe ID ${json['id']}");
      }

      return Recipe(
        id: json['id'] as int? ?? 0,
        // Use the parsed ingredients list
        ingredients: parsedIngredients,
        // Safely parse author - check if null and if it's a map
        author: json['author'] != null && json['author'] is Map<String, dynamic>
            ? UserProfile.fromJson(json['author'] as Map<String, dynamic>)
            : null,
        image: json['image'] as String?,
        title: json['title'] as String? ?? 'Без названия',
        description: json['description'] as String? ?? '',
        instructions: json['instructions'] as String? ?? '',
        cookingTimeMinutes: json['cooking_time_minutes'] as int? ?? 0,
        servings: json['servings'] as int? ?? 0,
        createdAt: safeParseDateTime(json['created_at'] as String?),
        updatedAt: safeParseDateTime(json['updated_at'] as String?),
        isActive: json['is_active'] as bool? ?? true, // Default value
        isPrivate: json['is_private'] as bool? ?? false, // Default value
      );
    }

    // TODO: Add toJson method for POST/PUT/PATCH requests if needed
    // Map<String, dynamic> toJson() => {
    //   ...
    //   'ingredients': ingredients.map((i) => i.toJson()).toList(),
    //   ...
    // };
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

  final RecipeService _recipeService = RecipeService();
  List<Recipe> _recipes = [];
  bool _isLoadingRecipes = true;
  String? _recipesError;

  // --- Pagination State ---
  int _currentPage = 1;
  int _totalPages = 1; // Will be calculated after first fetch
  final int _pageSize = 10; // Items per page
  int _totalRecipeCount = 0; // Total items available from API

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
    // Fetch recipes for the initial page
    _fetchRecipes(page: _currentPage);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // --- Fetch Recipes Logic (Updated for Pagination) ---
  Future<void> _fetchRecipes({required int page}) async {
    if (!mounted) return;
    // Reset error before fetching
    // Keep existing recipes visible while loading next page?
    // Or clear them: _recipes = []; 
    setState(() {
      _isLoadingRecipes = true;
      _recipesError = null; 
    });

    print("[HomePage] Fetching recipes for page: $page");

    try {
      // Call service with page and pageSize
      final paginatedResult = await _recipeService.getRecipes(page: page, pageSize: _pageSize);
      if (!mounted) return;

      // Calculate total pages
      final totalCount = paginatedResult.count;
      final totalPages = (totalCount / _pageSize).ceil();
      if (totalPages == 0 && totalCount > 0) {
         // Handle case where ceil results in 0 pages for non-zero items (shouldn't happen with ceil)
         _totalPages = 1;
      } else {
        _totalPages = totalPages;
      }
      
      setState(() {
        _recipes = paginatedResult.recipes;
        _totalRecipeCount = totalCount;
        _currentPage = page; // Update current page *after* successful fetch
        _isLoadingRecipes = false;
      });
      print("[HomePage] Fetched page $page. Total pages: $_totalPages. Total recipes: $_totalRecipeCount");

    } catch (e) {
      print("[HomePage] Error fetching recipes for page $page: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingRecipes = false;
        _recipesError = 'Ошибка загрузки рецептов: $e';
        // Keep existing recipes on error? Or clear them?
        // _recipes = []; 
        // _totalPages = 1; // Reset pagination on error?
        // _currentPage = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить рецепты для страницы $page'), backgroundColor: Colors.red)
      );
    }
  }
  
  // --- Pagination Navigation --- 
  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _fetchRecipes(page: _currentPage - 1);
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      _fetchRecipes(page: _currentPage + 1);
    }
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
                    child: _buildRecipeContent(),
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

  Widget _buildRecipeContent() {
    if (_isLoadingRecipes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recipesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _recipesError!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_recipes.isEmpty) {
       return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Пока нет доступных рецептов.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Wrap the Column content in a SingleChildScrollView
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16), // Adjusted padding
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
          // Remove Expanded, add shrinkWrap and physics
          GridView.builder(
            shrinkWrap: true, 
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.only(left: 24, right: 24, bottom: 16, top: 4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: _recipes.length,
            itemBuilder: (context, index) {
              return RecipeCard(recipe: _recipes[index]);
            },
          ),
          // --- Pagination Controls --- 
          if (_totalPages > 1) 
            Padding(
              // Reduced vertical padding
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, 
                           color: _currentPage > 1 ? Colors.black : Colors.grey),
                    onPressed: _currentPage > 1 ? _goToPreviousPage : null, 
                    tooltip: 'Предыдущая страница',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      'Страница $_currentPage / $_totalPages',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, 
                           color: _currentPage < _totalPages ? Colors.black : Colors.grey),
                    onPressed: _currentPage < _totalPages ? _goToNextPage : null, 
                    tooltip: 'Следующая страница',
                  ),
                ],
              ),
            )
        ],
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
    // Add a check for null or empty image URL
    final bool hasImage = recipe.image != null && recipe.image!.isNotEmpty;
    print("Building RecipeCard for ID: ${recipe.id}, Title: ${recipe.title}, HasImage: $hasImage, ImageURL: ${recipe.image}"); // Add logging

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsPage(
              recipeId: recipe.id, 
              initialTitle: recipe.title, 
              initialImageUrl: recipe.image,
            ),
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
                // Conditionally display Image.network or a placeholder
                child: hasImage
                  ? Image.network(
                      recipe.image!, // Safe to use ! here because hasImage is true
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print("Error loading image ${recipe.image}: $error");
                        return Container(
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: Icon(Icons.broken_image, size: 40, color: Colors.grey[600]),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child; // Image loaded
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    )
                  : Container( // Placeholder when image is null or empty
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: Icon(Icons.restaurant_menu, size: 50, color: Colors.grey[600]),
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