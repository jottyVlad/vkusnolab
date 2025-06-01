import 'package:flutter/foundation.dart';
import 'like_service.dart';

class LikeStateManager extends ChangeNotifier {
  final LikeService _likeService = LikeService();
  final Set<int> _likedRecipeIds = {};

  bool isLiked(int recipeId) => _likedRecipeIds.contains(recipeId);

  Future<List<int>> loadLikedRecipes() async {
    try {
      final likedIds = await _likeService.getLikedRecipeIds();
      _likedRecipeIds.clear();
      _likedRecipeIds.addAll(likedIds);
      notifyListeners();
      return likedIds;
    } catch (e) {
      print('Error loading liked recipes: $e');
      return [];
    }
  }

  Future<void> toggleLike(int recipeId) async {
    try {
      if (isLiked(recipeId)) {
        final likeId = await _likeService.getLikeIdForRecipe(recipeId);
        if (likeId != null) {
          await _likeService.unlikeRecipe(likeId);
          _likedRecipeIds.remove(recipeId);
          notifyListeners();
        }
      } else {
        await _likeService.likeRecipe(recipeId);
        _likedRecipeIds.add(recipeId);
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }
} 