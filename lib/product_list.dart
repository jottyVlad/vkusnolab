import 'package:flutter/material.dart';
import 'home_page.dart'; 
import 'create_recipe_page.dart'; 
import 'assistant_page.dart'; 
import 'profile_page.dart';
import 'services/product_list_service.dart'; 


class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductListService _productListService = ProductListService();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }


  Future<void> _showProductDialog({int? index}) async {
    final bool isEditing = index != null;
    _textController.text = isEditing ? _productListService.productsNotifier.value[index] : '';

    return showDialog<void>(
      context: context,
      barrierDismissible: true, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEditing ? 'Редактировать продукт' : 'Добавить продукт'),
          content: TextField(
            controller: _textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Название продукта'),
            onSubmitted: (_) => _submitDialog(index: index), 
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(isEditing ? 'Сохранить' : 'Добавить'),
              onPressed: () => _submitDialog(index: index),
            ),
          ],
        );
      },
    );
  }


  void _submitDialog({int? index}) {
    final newProduct = _textController.text.trim();
    if (newProduct.isNotEmpty) {
      if (index != null) {
        _productListService.editProduct(index, newProduct);
      } else {
        _productListService.addProduct(newProduct);
      }
    }
    Navigator.of(context).pop(); 
    _textController.clear(); 
  }


  void _deleteProduct(int index) {
    _productListService.removeProduct(index);
  }

  @override
  Widget build(BuildContext context) {

    const Color primaryColor = Color(0xFFF37A3A); 
    const Color backgroundColor = Color(0xFFFFF8E1); 
    const Color itemBackgroundColor = Color(0xFFF5EAAA); 
    const Color titleColor = primaryColor; 

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
        backgroundColor: backgroundColor, 
        elevation: 0, 
        automaticallyImplyLeading: false, 
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ValueListenableBuilder<List<String>>(
          valueListenable: _productListService.productsNotifier,
          builder: (context, productList, child) {
            return ListView.builder(
              itemCount: productList.length + 1,
              itemBuilder: (context, index) {
                if (index < productList.length) {
                  final product = productList[index];
                  return Container(
                     margin: const EdgeInsets.symmetric(vertical: 6.0),
                     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                     decoration: BoxDecoration(
                       color: itemBackgroundColor,
                       borderRadius: BorderRadius.circular(20.0),
                     ),
                     constraints: const BoxConstraints(minHeight: 48.0),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Expanded(
                           child: Text(
                             product,
                             style: const TextStyle(
                               fontSize: 18,
                               color: Colors.black87,
                             ),
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                         Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             IconButton(
                               icon: const Icon(Icons.edit_outlined, color: Colors.black54),
                               onPressed: () => _showProductDialog(index: index),
                               constraints: const BoxConstraints(),
                               padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                               iconSize: 20,
                             ),
                             IconButton(
                               icon: const Icon(Icons.delete_outline, color: Colors.black54),
                               onPressed: () => _deleteProduct(index),
                               constraints: const BoxConstraints(),
                               padding: const EdgeInsets.only(left: 4.0),
                               iconSize: 20,
                             ),
                           ],
                         ),
                       ],
                     ),
                  );
                } 
                else {
                  return GestureDetector(
                    onTap: () => _showProductDialog(),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: itemBackgroundColor.withOpacity(0.7), 
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: primaryColor.withOpacity(0.5), width: 1) 
                      ),
                      constraints: const BoxConstraints(minHeight: 48.0),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.black54, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Добавить продукт',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
      bottomNavigationBar: Container( 
        color: backgroundColor, 
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
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.white), 
                onPressed: () {
                   Navigator.of(context).pushReplacement(
                     PageRouteBuilder(
                       pageBuilder: (context, animation1, animation2) => HomePage(),
                       transitionDuration: Duration.zero,
                       reverseTransitionDuration: Duration.zero,
                     ),
                   );
                }),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => CreateRecipePage(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                }),
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white), 
                onPressed: () {}, 
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                 onPressed: () {
                   Navigator.of(context).pushReplacement(
                     PageRouteBuilder(
                       pageBuilder: (context, animation1, animation2) => AssistantPage(),
                       transitionDuration: Duration.zero,
                       reverseTransitionDuration: Duration.zero,
                     ),
                   );
                 }),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white), 
                 onPressed: () {
                   Navigator.of(context).pushReplacement(
                     PageRouteBuilder(
                       pageBuilder: (context, animation1, animation2) => ProfilePage(),
                       transitionDuration: Duration.zero,
                       reverseTransitionDuration: Duration.zero,
                     ),
                   );
                 }),
            ],
          ),
        ),
      ),
    );
  }
}