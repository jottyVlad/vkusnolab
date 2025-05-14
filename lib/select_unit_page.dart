import 'package:flutter/material.dart';
// import '../data/mock_data.dart'; // Импорт моковых данных

// Моковые данные для страницы выбора единицы измерения
const List<String> _hardcodedUnits = [
  'стакан',
  'ст. л.',
  'ч. л.',
  'шт.',
  'зубчик',
  'г',
  'мл',
  'л',
  'кг',
  'лист',
  'пучок',
  'перо',
  'головка',
  'щепотка',
  'веточка',
  'по вкусу',
  'банка',
  'пачка',
];

class SelectUnitPage extends StatefulWidget {
  const SelectUnitPage({super.key});

  @override
  State<SelectUnitPage> createState() => _SelectUnitPageState();
}

class _SelectUnitPageState extends State<SelectUnitPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredUnits = [];

  @override
  void initState() {
    super.initState();
    _filteredUnits = List.from(_hardcodedUnits);
    _searchController.addListener(_filterUnits);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUnits);
    _searchController.dispose();
    super.dispose();
  }

  void _filterUnits() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUnits = List.from(_hardcodedUnits);
      } else {
        _filteredUnits = _hardcodedUnits
            .where((unit) => unit.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFE95322);

    return Scaffold(
      appBar: AppBar(
         leading: IconButton(
           icon: const Icon(Icons.arrow_back, color: primaryColor),
           onPressed: () => Navigator.of(context).pop(),
         ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Введите название ед. измерения...',
             border: InputBorder.none,
             hintStyle: TextStyle(color: Colors.grey)
          ),
          style: const TextStyle(color: Colors.black87, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: ListView.builder(
        itemCount: _filteredUnits.length,
        itemBuilder: (context, index) {
          final unit = _filteredUnits[index];
          return ListTile(
            title: Text(unit),
            onTap: () {
              Navigator.of(context).pop(unit);
            },
          );
        },
      ),
    );
  }
} 