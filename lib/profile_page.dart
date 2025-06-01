import 'package:flutter/material.dart';
import 'home_page.dart';
import 'create_recipe_page.dart';
import 'assistant_page.dart';
import 'product_list.dart';
import 'edit_profile_page.dart';
import 'services/recipe_service.dart';
import 'services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/profile_service.dart';
import 'recipe_details_page.dart';
import 'package:provider/provider.dart';
import 'services/like_state_manager.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final RecipeService _recipeService = RecipeService();
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ProfileService _profileService = ProfileService();
  List<Recipe> _userRecipes = [];
  List<Recipe> _favoriteRecipes = [];
  bool _isLoading = true;
  String? _error;
  String? _userName;
  String _userBio = '';
  String? _profilePictureUrl;
  int? _userId;
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    _initProfile();
    context.read<LikeStateManager>().loadLikedRecipes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we're returning from a recipe details page
    final result = ModalRoute.of(context)?.settings.arguments;
    if (result == true) {
      _fetchFavorites();
    }
  }

  Future<void> _initProfile() async {
    await _loadUserId();
    await _loadUserProfile();
    await _fetchRecipes();
    await _fetchFavorites();
  }

  Future<void> _loadUserId() async {
    int? userId = await _authService.getCurrentUserId();
    setState(() {
      _userId = userId;
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profileService.getMe();
      setState(() {
        _userName = profile.username.isNotEmpty ? profile.username : 'Имя пользователя';
        _userBio = profile.bio.isNotEmpty ? profile.bio : '';
        _profilePictureUrl = profile.profilePicture;
      });
    } catch (e) {
      setState(() {
        _userName = 'Имя пользователя';
        _userBio = '';
        _profilePictureUrl = null;
      });
    }
  }

  Future<void> _fetchRecipes() async {
    if (_userId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final paginatedResult = await _recipeService.getRecipes(page: 1, authorId: _userId);
      setState(() {
        _userRecipes = paginatedResult.recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки рецептов: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // First get all liked recipe IDs
      final likedIds = await context.read<LikeStateManager>().loadLikedRecipes();
      List<Recipe> likedRecipes = [];
      
      // Then fetch full recipe details for each liked recipe
      for (final id in likedIds) {
        try {
          final recipe = await _recipeService.getRecipeById(id);
          likedRecipes.add(recipe);
        } catch (e) {
          print('Error fetching recipe $id: $e');
        }
      }
      
      setState(() {
        _favoriteRecipes = likedRecipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки избранных рецептов: $e';
        _isLoading = false;
      });
    }
  }

  void _onToggleChanged(bool showFavorites) async {
    setState(() {
      _showFavorites = showFavorites;
      _isLoading = true;
      _error = null;
    });
    if (showFavorites) {
      await _fetchFavorites();
    } else {
      await _fetchRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to LikeStateManager changes
    context.watch<LikeStateManager>();
    
    return Scaffold(
      backgroundColor: Color(0xFFFFC6AE),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.white,
                          backgroundImage: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                              ? NetworkImage(_profilePictureUrl!)
                              : null,
                          child: (_profilePictureUrl == null || _profilePictureUrl!.isEmpty)
                              ? Icon(
                                  Icons.person,
                                  size: 52,
                                  color: Color(0xFFE95322),
                                )
                              : null,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _userName ?? '',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color:Color(0xFFE95322),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                      _buildInfoSection('Обо мне', _userBio),
                      SizedBox(height: 16),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (_showFavorites) {
                                  setState(() { _showFavorites = false; _isLoading = true; });
                                  await _fetchRecipes();
                                }
                              },
                              child: Text(
                                'Мои рецепты',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: !_showFavorites ? Color(0xFFE95322) : Colors.grey,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            GestureDetector(
                              onTap: () async {
                                if (!_showFavorites) {
                                  setState(() { _showFavorites = true; _isLoading = true; });
                                  await _fetchFavorites();
                                }
                              },
                              child: Text(
                                'Избранное',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: _showFavorites ? Color(0xFFE95322) : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildRecipesGrid(),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              top: 40,
              child: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Color(0xFFE95322),
                  size: 30,
                ),
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfilePage()),
                  );
                  if (updated == true) {
                    _initProfile();
                  }
                },
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
                icon: Icon(Icons.home_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => HomePage(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => CreateRecipePage(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => ProductListScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => AssistantPage(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.person, color: Colors.white),
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
            (content.isNotEmpty ? content : 'Люблю готовить и пробовать что-то новое!'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesGrid() {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final recipes = _showFavorites ? _favoriteRecipes : _userRecipes;
    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _showFavorites ? 'У вас пока нет избранных рецептов.' : 'У вас пока нет рецептов.',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
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
        final recipe = recipes[index];
        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailsPage(
                  recipeId: recipe.id,
                  initialTitle: recipe.title,
                  initialImageUrl: recipe.image,
                ),
              ),
            );
            if (result == true) {
              await _fetchFavorites();
            }
          },
          child: RecipeCard(
            recipe: recipe,
            onLikeStateChanged: () async {
              await _fetchFavorites();
            },
          ),
        );
      },
    );
  }
} 