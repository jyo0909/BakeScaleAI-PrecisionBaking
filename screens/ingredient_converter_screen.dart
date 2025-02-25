import 'package:flutter/material.dart';

class IngredientConverterScreen extends StatefulWidget {
  const IngredientConverterScreen({Key? key}) : super(key: key);

  @override
  State<IngredientConverterScreen> createState() => _IngredientConverterScreenState();
}

class _IngredientConverterScreenState extends State<IngredientConverterScreen> {
  String? selectedIngredient;
  String? fromUnit;
  String? toUnit;
  final TextEditingController quantityController = TextEditingController();
  String? result;
  bool isConnectedToScale = false;
  double? scaleReading;

  final List<String> ingredients = [
    'Flour',
    'Sugar',
    'Butter',
    'Milk',
    'Water',
    'Oil',
    'Rice',
  ];

  final List<String> units = [
    'cups',
    'tbsp',
    'tsp',
    'grams',
    'ml',
    'oz',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Ingredient Converter',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ingredient Selection
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        return ingredients.where((String ingredient) {
                          return ingredient.toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        setState(() {
                          selectedIngredient = selection;
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Select Ingredient',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Unit Conversion Row
                    Row(
                      children: [
                        // From Unit
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: fromUnit,
                            decoration: InputDecoration(
                              labelText: 'From',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: units.map((String unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              setState(() {
                                fromUnit = value;
                              });
                            },
                          ),
                        ),
                        
                        // Swap Button
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: () {
                            setState(() {
                              final temp = fromUnit;
                              fromUnit = toUnit;
                              toUnit = temp;
                            });
                          },
                        ),
                        
                        // To Unit
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: toUnit,
                            decoration: InputDecoration(
                              labelText: 'To',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: units.map((String unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              setState(() {
                                toUnit = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quantity Input
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Convert Button
                    ElevatedButton(
                      onPressed: () {
                        // Simulate conversion
                        setState(() {
                          result = '100g';
                          scaleReading = 120;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Convert',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Result Display
                    if (result != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Result: $result',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (scaleReading != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Scale Reading: ${scaleReading}g',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                scaleReading! > 100 
                                    ? 'Remove ${(scaleReading! - 100).toInt()}g'
                                    : 'Add ${(100 - scaleReading!).toInt()}g',
                                style: TextStyle(
                                  color: scaleReading! > 100 
                                      ? Colors.red 
                                      : const Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Save Button
                    if (result != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          // Implement save functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Conversion saved'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Conversion'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavButton(
                    icon: Icons.home,
                    label: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildNavButton(
                    icon: Icons.calculate,
                    label: 'Convert Measurement',
                    isSelected: true,
                    onTap: () {},
                  ),
                  _buildNavButton(
                    icon: Icons.upload_file,
                    label: 'Import Recipe',
                    onTap: () {},
                  ),
                  _buildNavButton(
                    icon: Icons.bluetooth,
                    label: 'Connect Smart Scale',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}