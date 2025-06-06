import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';
import 'home_page.dart'; 
import 'models/comment.dart'; 
import 'services/comment_service.dart'; 
import 'services/product_list_service.dart';
import 'package:vkusnolab/models/recipe_ingredient.dart'; 
import 'services/recipe_service.dart';
import 'services/like_state_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';


class RecipeDetailsPage extends StatefulWidget {
  final int recipeId;
  final String? initialTitle;
  final String? initialImageUrl;

  const RecipeDetailsPage({
    super.key, 
    required this.recipeId,
    this.initialTitle,
    this.initialImageUrl,
  });

  @override
  State<RecipeDetailsPage> createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  final CommentService _commentService = CommentService();
  final ProductListService _productListService = ProductListService();
  final TextEditingController _commentController = TextEditingController();
  final RecipeService _recipeService = RecipeService();
  final LikeService _likeService = LikeService();

  // State for fetched recipe details
  Recipe? _detailedRecipe;
  bool _isDetailsLoading = true;
  String? _detailsError;

  // State for comments (kept separate)
  List<Comment> _comments = [];
  bool _isLoadingComments = true; // Renamed for clarity
  String? _commentsError; // Renamed for clarity
  bool _isPostingComment = false;

  // --- Состояние для Выбранных Ингредиентов ---
  // Используем Set для хранения **форматированных строк** выбранных ингредиентов
  final Set<String> _selectedIngredients = {};

  bool _isLiked = false;
  int? _likeId;
  bool _isLikeLoading = true;

  @override
  void initState() {
    super.initState();
    print("[RecipeDetailsPage] initState started for Recipe ID: ${widget.recipeId}");
    
    // Fetch both recipe details and comments
    _fetchRecipeDetails();
    _fetchComments();
    _checkIfLiked();
  }

  @override
  void dispose() {
    _commentController.dispose(); // Clean up the controller
    super.dispose();
  }

  // --- Fetch Full Recipe Details Logic ---
  Future<void> _fetchRecipeDetails() async {
     if (!mounted) return;
     setState(() {
       _isDetailsLoading = true;
       _detailsError = null;
     });

     try {
       final fetchedRecipe = await _recipeService.getRecipeById(widget.recipeId);
       if (!mounted) return;
       setState(() {
         _detailedRecipe = fetchedRecipe;
         _isDetailsLoading = false;
         print("[RecipeDetailsPage] Successfully fetched details for Recipe ID: ${widget.recipeId}, Ingredients count: ${fetchedRecipe.ingredients.length}");
       });
     } catch (e) {
       print("[RecipeDetailsPage] Error fetching recipe details for ID ${widget.recipeId}: $e");
       if (!mounted) return;
       setState(() {
         _detailsError = "Ошибка загрузки данных рецепта: $e";
         _isDetailsLoading = false;
       });
     }
  }

  // --- Fetch Comments Logic (Updated state names) ---
  Future<void> _fetchComments() async {
    if (widget.recipeId == 0) {
       setState(() { _isLoadingComments = false; _commentsError = "Invalid Recipe ID (0)"; });
       return;
    }

    setState(() {
      _isLoadingComments = true;
      _commentsError = null;
    });
    try {
      final comments = await _commentService.getComments(widget.recipeId);
       print("[RecipeDetailsPage] Successfully fetched ${comments.length} comments.");
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
       print("[RecipeDetailsPage] Error fetching comments: $e");
       if (!mounted) return;
       setState(() {
        _isLoadingComments = false;
        _commentsError = 'Не удалось загрузить комментарии: $e';
      });
    }
  }

  // --- Post Comment Logic (unchanged, uses widget.recipeId) ---
  Future<void> _postComment() async {
    if (widget.recipeId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: Не удается определить ID рецепта.'))
      );
      return;
    }
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Комментарий не может быть пустым.'))
      );
      return;
    }

    setState(() {
        _isPostingComment = true;
    });

    try {
      await _commentService.createComment(widget.recipeId, text);
      _commentController.clear(); 
      FocusScope.of(context).unfocus();
      await _fetchComments(); // Refresh comments list
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Комментарий добавлен!'), duration: Duration(seconds: 2)),
      );
    } catch (e) {
       print('Error posting comment: $e');
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Ошибка добавления комментария: $e')),
       );
    } finally {
       if (mounted) {
         setState(() {
            _isPostingComment = false;
         });
       }
    }
  }

  // --- Логика Добавления в Корзину (unchanged) ---
  void _addSelectedIngredientsToCart() {
    final List<String> itemsToAdd = _selectedIngredients.toList();

    if (itemsToAdd.isNotEmpty) {
      _productListService.addProducts(itemsToAdd);
      setState(() {
        _selectedIngredients.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${itemsToAdd.length} ${ _getCorrectNoun(itemsToAdd.length, 'продукт', 'продукта', 'продуктов')} добавлено в список'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала выберите ингредиенты'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Хелпер для правильного склонения слова "продукт" (unchanged)
  String _getCorrectNoun(int number, String one, String two, String five) {
    number %= 100;
    if (number >= 11 && number <= 19) {
      return five;
    }
    number %= 10;
    if (number == 1) {
      return one;
    }
    if (number >= 2 && number <= 4) {
      return two;
    }
    return five;
  }

  Future<void> _checkIfLiked() async {
    setState(() { _isLikeLoading = true; });
    try {
      final likeId = await _likeService.getLikeIdForRecipe(widget.recipeId);
      setState(() {
        _isLiked = likeId != null;
        _likeId = likeId;
        _isLikeLoading = false;
      });
    } catch (e) {
      setState(() { _isLikeLoading = false; });
    }
  }

  Future<void> _toggleLike() async {
    if (_isLikeLoading) return;
    setState(() { _isLikeLoading = true; });
    try {
      await context.read<LikeStateManager>().toggleLike(widget.recipeId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при обновлении избранного: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLikeLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("[RecipeDetailsPage] Build method started. isDetailsLoading: $_isDetailsLoading, detailsError: ${_detailsError != null}");
    
    const Color primaryColor = Color(0xFFF37A3A);
    const Color textColor = Colors.black87;
    const Color titleColor = primaryColor;
    const Color lightBgColor = Color(0xFFFFF8E1);

    final Recipe? recipeToShow = _detailedRecipe; 
    final String displayTitle = recipeToShow?.title ?? widget.initialTitle ?? 'Загрузка...';
    final String displayDescription = recipeToShow?.description ?? '';
    final String displayInstructions = recipeToShow?.instructions ?? '';
    final List<RecipeIngredient> recipeIngredients = recipeToShow?.ingredients ?? [];
    final String? imageUrl = recipeToShow?.image ?? widget.initialImageUrl;
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: lightBgColor, 
      body: _isDetailsLoading
        ? const Center(child: CircularProgressIndicator()) 
        : _detailsError != null
          ? Center( 
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                    _detailsError!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                 ),
              ),
            )
          : CustomScrollView( 
              slivers: <Widget>[
                SliverAppBar(
                  expandedHeight: 250.0,
                  pinned: false,
                  backgroundColor: Color(0xFFF3E9B5),
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)),
                          child: hasImage
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print("[RecipeDetailsPage] Error loading image $imageUrl: $error");
                                  return Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF3E9B5),
                                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.broken_image, size: 60, color: Colors.grey[600]),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF3E9B5),
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                              ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          left: 15,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha((0.4 * 255).round()),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  // Navigate back to HomePage instead of replacing stack
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (context) => HomePage()),
                                    (Route<dynamic> route) => false, // Remove all previous routes
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
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Title --- 
                          Center(
                            child: Text(
                              displayTitle.replaceAll('\\n', '\n'), 
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: titleColor,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.3, 
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // --- Description --- 
                          if (displayDescription.isNotEmpty)
                            Center(
                              child: Text(
                                displayDescription,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: textColor, 
                                  fontSize: 16, 
                                  height: 1.4,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          Container(height: 2, color: primaryColor.withAlpha((0.5 * 255).round())),
                          const SizedBox(height: 20),
                          // --- Ingredients --- 
                          const Text('Ингредиенты', style: TextStyle(color: titleColor, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          _buildSelectableIngredientList(recipeIngredients, _selectedIngredients),
                          const SizedBox(height: 30),
                          // --- Кнопка "Добавить в корзину" ---
                          Center(
                            child: ElevatedButton(
                              onPressed: _addSelectedIngredientsToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE95322),
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              child: const Text('Добавить в корзину', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // --- Instructions --- 
                          const Text('Рецепт', style: TextStyle(color: titleColor, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(
                            displayInstructions.isNotEmpty ? displayInstructions : "Инструкции не указаны.", 
                            style: const TextStyle(color: textColor, fontSize: 16, height: 1.5)
                          ),
                          const SizedBox(height: 20),
                          // --- Like (Favorite) ---
                          Row(
                            children: [
                              _isLikeLoading
                                ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2))
                                : IconButton(
                                    icon: Icon(
                                      context.watch<LikeStateManager>().isLiked(widget.recipeId) 
                                        ? Icons.favorite 
                                        : Icons.favorite_border,
                                      color: context.watch<LikeStateManager>().isLiked(widget.recipeId) 
                                        ? Colors.red 
                                        : Colors.grey,
                                      size: 32,
                                    ),
                                    onPressed: _toggleLike,
                                    tooltip: context.watch<LikeStateManager>().isLiked(widget.recipeId) 
                                      ? 'Убрать из избранного' 
                                      : 'В избранное',
                                  ),
                              const SizedBox(width: 8),
                              if (context.watch<LikeStateManager>().isLiked(widget.recipeId))
                                const Text('Рецепт в избранном', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 30),
                          // --- Comments Section ---
                          const Text('Комментарии', style: TextStyle(color: titleColor, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          _buildCommentInput(), 
                          const SizedBox(height: 10),
                          _buildCommentsSection(), 
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // --- Helper Widgets ---

  // --- Comment Helper Widgets ---
  Widget _buildCommentInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Оставить комментарий...',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            minLines: 1,
            maxLines: 4, // Allow multi-line input
            textInputAction: TextInputAction.newline, // Suggest newline on enter
            enabled: !_isPostingComment, // Disable while posting
          ),
        ),
        const SizedBox(width: 8),
        _isPostingComment
            ? const SizedBox(
                width: 40, height: 40,
                child: CircularProgressIndicator(strokeWidth: 3)
              )
            : IconButton(
                icon: const Icon(Icons.send, color: Color(0xFFE95322)),
                onPressed: _postComment,
                tooltip: 'Отправить',
              ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    if (_isLoadingComments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_commentsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(_commentsError!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_comments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text('Комментариев пока нет.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(comment.createdAt.toLocal());

        return Card(
           elevation: 1,
           margin: const EdgeInsets.symmetric(vertical: 6.0),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
           child: Padding(
             padding: const EdgeInsets.all(12.0),
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                       CircleAvatar(
                         radius: 18,
                         backgroundColor: Colors.grey.shade300,
                         child: Text(
                           comment.author.username.isNotEmpty ? comment.author.username[0].toUpperCase() : '?',
                           style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                         ),
                       ),
                       const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          comment.author.username,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment.commentText,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
           ),
        );
      },
    );
  }

  // --- Обновленный Helper для Списка Ингредиентов --- 
  Widget _buildSelectableIngredientList(List<RecipeIngredient> ingredients, Set<String> selectedSet) {
    // Add detailed logging
    print("[RecipeDetailsPage] _buildSelectableIngredientList called with ${ingredients.length} ingredients.");
    // You could even print the first ingredient if the list is not empty:
    // if (ingredients.isNotEmpty) { 
    //   print("[RecipeDetailsPage] First ingredient: ${ingredients.first.displayString}"); 
    // }

    const Color primaryColor = Color(0xFFF37A3A);
    const Color textColor = Colors.black87;

    if (ingredients.isEmpty) {
      print("[RecipeDetailsPage] Ingredients list is empty, showing placeholder text.");
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Нет ингредиентов для отображения.', style: TextStyle(color: Colors.grey)),
      );
    }

    print("[RecipeDetailsPage] Building ingredient list UI...");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ingredients.map((recipeIngredient) {
        final String displayIngredient = recipeIngredient.displayString;
        final bool isSelected = selectedSet.contains(displayIngredient);

        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedSet.remove(displayIngredient);
              } else {
                selectedSet.add(displayIngredient);
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayIngredient,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
} 