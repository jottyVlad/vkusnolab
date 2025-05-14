import 'package:flutter/material.dart';
import '../models/ingredient.dart'; 
import '../services/ingredient_service.dart'; // Import the service


class SelectIngredientPage extends StatefulWidget {
  const SelectIngredientPage({super.key});

  @override
  State<SelectIngredientPage> createState() => _SelectIngredientPageState();
}

class _SelectIngredientPageState extends State<SelectIngredientPage> {
  final TextEditingController _searchController = TextEditingController();
  final IngredientService _ingredientService = IngredientService(); // Instantiate the service
  

  List<Ingredient> _allIngredients = [];
  List<Ingredient> _filteredIngredients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchIngredients();
    _searchController.addListener(_filterIngredients);
  }

  Future<void> _fetchIngredients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Fetch ingredients using the service
      final ingredients = await _ingredientService.getIngredients(); 
      if (mounted) {
         setState(() {
          _allIngredients = ingredients;
          _filteredIngredients = List.from(_allIngredients);
        });
      }
    } catch (e) {
       if (mounted) {
          setState(() {
             _error = "Ошибка загрузки ингредиентов: $e";
          });
       }
       print("Error fetching ingredients: $e");
    } finally {
      if (mounted) {
         setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterIngredients);
    _searchController.dispose();
    super.dispose();
  }

  void _filterIngredients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredIngredients = List.from(_allIngredients);
      } else {
        _filteredIngredients = _allIngredients
            .where((ingredient) => ingredient.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFE95322); // Оранжевый цвет для AppBar

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
           icon: const Icon(Icons.arrow_back, color: primaryColor),
           onPressed: () => Navigator.of(context).pop(), // Просто закрываем, не возвращая значения
         ),
        title: TextField(
          controller: _searchController,
          autofocus: true, // Автоматически фокусируемся на поиске
          decoration: const InputDecoration(
            hintText: 'Название ингредиента...',
            border: InputBorder.none, // Убираем рамку
            hintStyle: TextStyle(color: Colors.grey)
          ),
          style: const TextStyle(color: Colors.black87, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 1, // Небольшая тень для разделения
        iconTheme: const IconThemeData(color: primaryColor), // Цвет иконки назад
      ),
      body: _buildBody(), // Используем хелпер для отображения состояния
    );
  }


  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Padding(padding: EdgeInsets.all(16), child: Text(_error!, style: TextStyle(color: Colors.red))));
    }
    if (_filteredIngredients.isEmpty && _searchController.text.isNotEmpty) {
       return const Center(child: Text('Ингредиенты не найдены'));
    }
     if (_filteredIngredients.isEmpty && _allIngredients.isNotEmpty) {
       return const Center(child: Text('Нет доступных ингредиентов'));
    }


    return ListView.builder(
      itemCount: _filteredIngredients.length,
      itemBuilder: (context, index) {
        final ingredient = _filteredIngredients[index];
        return ListTile(
          title: Text(ingredient.name),
          onTap: () {
            Navigator.of(context).pop(ingredient);
          },
        );
      },
    );
  }
} 