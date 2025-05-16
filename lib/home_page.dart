import 'package:flutter/material.dart';
import 'assistant_page.dart';
import 'create_recipe_page.dart';
import 'profile_page.dart';
import 'product_list.dart';
import 'recipe_details_page.dart';
import 'services/search_history_service.dart';
import 'package:vkusnolab/auth_service.dart';
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
  final ScrollController _scrollController = ScrollController();

  List<SearchHistory> _searchHistorySuggestions = [];
  bool _isLoadingHistory = false;
  String? _historyError;

  final RecipeService _recipeService = RecipeService();
  List<Recipe> _recipes = [];
  bool _isLoadingRecipes = false;
  String? _recipesError;

  // --- Pagination State ---
  int _currentPage = 1;
  int _totalPages = 1; // Will be calculated after first fetch
  final int _pageSize = 10; // Items per page
  int _totalRecipeCount = 0; // Total items available from API
  String? _currentSearchQuery; // Store current search query

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

    _scrollController.addListener(_scrollListener);

    // Fetch recipes for the initial page
    _fetchRecipes(page: 1, searchQuery: null); // Initial fetch
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < 300 &&
        !_isLoadingRecipes &&
        _currentPage < _totalPages) {
      print("[HomePage] Scroll listener triggered: Reached near bottom, loading next page.");
      _fetchRecipes(page: _currentPage + 1, searchQuery: _currentSearchQuery);
    }
  }

  // --- Fetch Recipes Logic (Updated for Pagination and Search) ---
  Future<void> _fetchRecipes({required int page, String? searchQuery}) async {
    if (_isLoadingRecipes && page != 1) return;
    if (!mounted) return;

    final isNewSearch = searchQuery != _currentSearchQuery;
    final targetPage = (isNewSearch || (searchQuery == null && _currentSearchQuery != null)) ? 1 : page;

    setState(() {
      _isLoadingRecipes = true;
      _recipesError = null;
      if (isNewSearch) {
        _recipes = []; 
        _currentSearchQuery = searchQuery; 
        _currentPage = 1;
      } else if (targetPage == 1 && _currentSearchQuery != null && searchQuery == null) {
        _recipes = [];
        _currentSearchQuery = null;
        _currentPage = 1;
      }
    });
    
    print("[HomePage] Fetching recipes for page: $targetPage, query: '${_currentSearchQuery ?? ''}'");

    try {
      final paginatedResult = await _recipeService.getRecipes(
        page: targetPage, 
        pageSize: _pageSize,
        searchQuery: _currentSearchQuery, 
      );
      if (!mounted) return;

      final totalCount = paginatedResult.count;
      final newTotalPages = (totalCount / _pageSize).ceil();
      
      setState(() {
        if (targetPage == 1) { 
          _recipes = paginatedResult.recipes;
        } else { 
          _recipes.addAll(paginatedResult.recipes);
        }
        _totalRecipeCount = totalCount;
        _totalPages = (newTotalPages == 0 && totalCount > 0) ? 1 : newTotalPages;
        _currentPage = targetPage;
        _isLoadingRecipes = false;
      });
      print("[HomePage] Fetched page $targetPage for query '${_currentSearchQuery ?? ''}'. Total pages: $_totalPages. Total recipes: $_totalRecipeCount. Loaded recipes: ${paginatedResult.recipes.length}");

    } catch (e) {
      print("[HomePage] Error fetching recipes for page $targetPage, query '${_currentSearchQuery ?? ''}': $e");
      if (!mounted) return;
      setState(() {
        _isLoadingRecipes = false;
        _recipesError = 'Ошибка загрузки рецептов: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить рецепты для страницы $targetPage'), backgroundColor: Colors.red)
        );
      }
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
        _isLoadingHistory = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = e.message;
        _isLoadingHistory = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка доступа к истории: ${e.message}'), backgroundColor: Colors.orange)
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = 'Не удалось загрузить историю поиска.';
        _isLoadingHistory = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки истории поиска'), backgroundColor: Colors.red)
          );
        }
      });
       print("History loading error: $e");
    }
  }

  Future<void> _saveSearchQuery(String query) async {
    if (query.isEmpty) return;
    try {
      await _searchHistoryService.saveSearchQuery(query);
    } catch (e) {
      print("Failed to save search query '$query': $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось сохранить запрос "$query" в историю.'), backgroundColor: Colors.amber[800])
        );
      }
    }
  }

  void _performSearch(String query) {
    final trimmedQuery = query.trim();
    
    print("Performing search for: '$trimmedQuery'");
    if (trimmedQuery.isNotEmpty) {
        _saveSearchQuery(trimmedQuery);
    }
    _searchFocusNode.unfocus();
    _fetchRecipes(page: 1, searchQuery: trimmedQuery.isNotEmpty ? trimmedQuery : null);
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldShowHistoryOverlay = _searchFocusNode.hasFocus &&
                                          (_isLoadingHistory || _historyError != null || _searchHistorySuggestions.isNotEmpty);

    return Scaffold(
      backgroundColor: Color(0xFFF5CB58),
      resizeToAvoidBottomInset: true, // Important for TextField with overlay
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
                   suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch(''); 
                          setState(() {});
                        },
                      )
                    : null,
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
                  if (_searchFocusNode.hasFocus && value.isNotEmpty) {
                  }
                  setState(() {}); 
                 },
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  GestureDetector( // Add GestureDetector to unfocus search on tap outside
                    onTap: () {
                      if (_searchFocusNode.hasFocus) {
                        _searchFocusNode.unfocus();
                      }
                    },
                    child: Container(
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
                  ),
                  if (shouldShowHistoryOverlay)
                    Positioned(
                      top: 0, // Adjusted to be right below the search bar
                      left: 22,
                      right: 22,
                      child: Material( // Using Material for elevation and theming
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                        color: Colors.white, // Background color for the list
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
                onPressed: () {
                  // Already on home, or navigate to reset state if needed
                  // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
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
    if (_isLoadingRecipes && _recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recipesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _recipesError!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _fetchRecipes(page: _currentPage, searchQuery: _currentSearchQuery),
                child: Text("Попробовать снова"),
              )
            ],
          ),
        ),
      );
    }
    if (!_isLoadingRecipes && _recipes.isEmpty) {
       return Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
             _currentSearchQuery != null && _currentSearchQuery!.isNotEmpty
                ? 'По запросу "$_currentSearchQuery" ничего не найдено.'
                : 'Пока нет доступных рецептов.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column( // Changed from SingleChildScrollView to Column
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Center(
            child: Text(
              _currentSearchQuery != null && _currentSearchQuery!.isNotEmpty
              ? 'Результаты поиска'
              : 'Рецепты',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEC9706),
              ),
            ),
          ),
        ),
        Expanded( // Make GridView take available space
          child: GridView.builder(
            controller: _scrollController,
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
        ),
        if (_isLoadingRecipes && _recipes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
    );
  }

  Widget _buildSearchHistoryList() {
    if (_isLoadingHistory) {
      return Container(
          padding: EdgeInsets.all(16),
          height: 100, // Give it some default height or it might collapse
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
        maxHeight: 250, // Max height for the suggestions list
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero, // Remove any default padding
        shrinkWrap: true, // Important for ConstrainedBox
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
    // print("Building RecipeCard for ID: ${recipe.id}, Title: ${recipe.title}, HasImage: $hasImage, ImageURL: ${recipe.image}");

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
                        // print("Error loading image ${recipe.image}: $error");
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