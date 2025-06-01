import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'home_page.dart';
import 'assistant_page.dart';
import 'profile_page.dart';
import 'product_list.dart';
import 'models/ingredient_item.dart';
import 'models/ingredient.dart';
import 'select_ingredient_page.dart';
import 'select_unit_page.dart';
import 'services/recipe_service.dart'; 

class CreateRecipePage extends StatefulWidget {
  @override
  _CreateRecipePageState createState() => _CreateRecipePageState();
}


class RecipeIngredientInput {
  int? ingredientId; 
  String name;      
  String quantity;
  String unit;


  RecipeIngredientInput({ 
    this.ingredientId,
    this.name = '',
    this.quantity = '',
    this.unit = '',
  });
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _recipeController = TextEditingController();
  final RecipeService _recipeService = RecipeService();
  final ImagePicker _picker = ImagePicker(); 


  List<RecipeIngredientInput> _ingredientItems = [RecipeIngredientInput()]; 
  List<TextEditingController> _quantityControllers = [];
  String? _selectedImagePath; 
  bool _isSaving = false; 

  @override
  void initState() {
    super.initState();
    _initializeQuantityControllers();
  }

  void _initializeQuantityControllers() {
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    _quantityControllers = _ingredientItems
        .map((item) => TextEditingController(text: item.quantity))
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _recipeController.dispose();
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }


  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
         source: ImageSource.gallery, 
       );

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
          print("Image selected: ${_selectedImagePath}");
        });
      }
    } catch (e) {
       print("Error picking image: $e");
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Ошибка выбора изображения: $e")),
       );
    }
  }


  Future<void> _selectIngredientName(int index) async {
    final selectedIngredient = await Navigator.push<Ingredient>(
      context,
      MaterialPageRoute(builder: (context) => const SelectIngredientPage()),
    );

    if (selectedIngredient != null) {
      setState(() {
        _ingredientItems[index].ingredientId = selectedIngredient.id;
        _ingredientItems[index].name = selectedIngredient.name;
        _ingredientItems[index].quantity = '';
        _ingredientItems[index].unit = '';
        if (index < _quantityControllers.length) {
             _quantityControllers[index].text = '';
        }
      });
    }
  }


  Future<void> _selectIngredientUnit(int index) async { 
      final selectedUnit = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const SelectUnitPage()),
      );
      if (selectedUnit != null && selectedUnit.isNotEmpty) {
        setState(() {
          _ingredientItems[index].unit = selectedUnit;
        });
      }
   }


  void _addIngredientRow() {
    setState(() {
      final newItem = RecipeIngredientInput();
      _ingredientItems.add(newItem);
      _quantityControllers.add(TextEditingController(text: newItem.quantity));
    });
  }

  void _removeIngredientRow(int index) {
    if (_ingredientItems.length > 1) {
      setState(() {
        _ingredientItems.removeAt(index);
        final controller = _quantityControllers.removeAt(index);
        controller.dispose();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Должен быть хотя бы один ингредиент')),
      );
    }
  }


  Future<void> _saveRecipe() async {

     if (_titleController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите название рецепта')));
       return;
     }
     if (_descriptionController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите описание рецепта')));
       return;
     }
      if (_recipeController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите шаги приготовления')));
       return;
     }

     final validIngredients = _ingredientItems.where((item) => 
         item.ingredientId != null && 
         item.ingredientId != 0 && 
         item.quantity.isNotEmpty && 
         item.unit.isNotEmpty
     ).toList();

     if (validIngredients.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Добавьте и заполните хотя бы один ингредиент (название, кол-во, ед. изм.)')));
         return;
     }

    setState(() { _isSaving = true; });

    try {
        final List<Map<String, dynamic>> ingredientsPayload = validIngredients.map((item) {
          final count = double.tryParse(item.quantity.replaceAll(',', '.')) ?? 0.0;
          return {
             'ingredient': item.ingredientId!,
             'count': count, 
             'visible_type_of_count': item.unit,
           };
        }).toList();


        final createdRecipe = await _recipeService.createRecipe(
          title: _titleController.text,
          description: _descriptionController.text,
          instructions: _recipeController.text,
          cookingTimeMinutes: 30, // TODO
          servings: 4, // TODO
          isActive: true, 
          isPrivate: false, 
          ingredients: ingredientsPayload,
          imagePath: _selectedImagePath,
        );

        print("Recipe successfully created with ID: ${createdRecipe.id}");
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Рецепт успешно создан!"), backgroundColor: Colors.green),
         );
         if (mounted) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomePage()),
            );
         }

    } catch (e) {
        print("Error saving recipe: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка сохранения рецепта: $e"), backgroundColor: Colors.red),
        );
    } finally {
        if (mounted) {
           setState(() { _isSaving = false; });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    double imageSize = 215;
    const Color hintColor = Colors.grey;
    const Color fieldColor = Color(0xFFF3E9B5);
    const Color primaryColor = Color(0xFFE95322);

    return Scaffold(
      backgroundColor: Color(0xFFFFA071),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: 24, right: 24, bottom: 16, top: 0),
                child: Center(
                  child: Text(
                    'Создание рецепта',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Stack(
              children: [
                Container(
                  margin: EdgeInsets.only(top: imageSize / 2 + 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, imageSize / 2 + 32, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Название',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE95322),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: fieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Описание',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Кратко опишите ваш рецепт...',
                            filled: true,
                            fillColor: fieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            hintStyle: TextStyle(color: hintColor),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Ингредиенты',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Column(
                          children: List.generate(_ingredientItems.length, (index) {
                            final item = _ingredientItems[index];
                            final quantityController = _quantityControllers[index];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: InkWell(
                                      onTap: () async {
                                        await _selectIngredientName(index);
                                      },
                                      borderRadius: BorderRadius.circular(15),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                        decoration: BoxDecoration(
                                          color: fieldColor,
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Text(
                                          item.name.isEmpty ? 'Ингредиент' : item.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: item.name.isEmpty ? hintColor : Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 70,
                                    child: TextField(
                                      controller: quantityController,
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        hintText: 'Кол-во',
                                        filled: true,
                                        fillColor: fieldColor,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 14.0),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide.none,
                                        ),
                                        hintStyle: TextStyle(color: hintColor, fontSize: 15),
                                      ),
                                      onChanged: (value) {
                                        _ingredientItems[index].quantity = value;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: InkWell(
                                      onTap: () => _selectIngredientUnit(index),
                                      borderRadius: BorderRadius.circular(15),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                        decoration: BoxDecoration(
                                          color: fieldColor,
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Text(
                                          item.unit.isEmpty ? 'Ед. изм.' : item.unit,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: item.unit.isEmpty ? hintColor : Colors.black87,
                                          ),
                                           overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_ingredientItems.length > 1)
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade300),
                                      onPressed: () => _removeIngredientRow(index),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    )
                                  else
                                      SizedBox(width: 48)
                                ],
                              ),
                            );
                          }),
                        ),
                        TextButton.icon(
                           icon: const Icon(Icons.add, color: primaryColor),
                           label: const Text('Добавить ингредиент', style: TextStyle(color: primaryColor)),
                           onPressed: _addIngredientRow,
                           style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                         ),
                        SizedBox(height: 16),
                        Text(
                          'Рецепт',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE95322),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _recipeController,
                          maxLines: 8,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: fieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveRecipe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          child: _isSaving
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text('Сохранить', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: (MediaQuery.of(context).size.width - imageSize) / 2,
                  child: InkWell(
                     onTap: _pickImage,
                     child: Container(
                       width: imageSize,
                       height: imageSize,
                       decoration: BoxDecoration(
                         color: Color(0xFFFFC6AE),
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: primaryColor.withOpacity(0.5), width: 1),
                         image: _selectedImagePath != null
                              ? DecorationImage(
                                  image: FileImage(File(_selectedImagePath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                       ),
                       child: _selectedImagePath == null
                          ? Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 48,
                                  color: Colors.black,
                                ),
                                Positioned(
                                  right: -25,
                                  bottom: -20,
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFE95322),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.black,
                                      size: 23,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : null,
                     ),
                  ),
                ),
              ],
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
                icon: Icon(Icons.edit, color: Colors.white),
                onPressed: () {},
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
                icon: Icon(Icons.person_outline, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => ProfilePage(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
