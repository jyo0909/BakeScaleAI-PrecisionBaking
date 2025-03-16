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
  
  // Add list for saved conversions
  List<Map<String, dynamic>> savedConversions = [];

  // Sample ingredient database with density values (g/ml per cup)
  final Map<String, double> ingredientDensities = {
    'Flour': 120.0,
    'Sugar': 200.0,
    'Brown Sugar': 220.0,
    'Butter': 227.0,
    'Milk': 240.0,
    'Water': 240.0,
    'Oil': 224.0,
    'Honey': 340.0,
    'Rice': 185.0,
    'Salt': 273.0,
  };

  final List<String> ingredients = [
    'Flour',
    'Sugar',
    'Brown Sugar',
    'Butter',
    'Milk',
    'Water',
    'Oil',
    'Honey',
    'Rice',
    'Salt',
  ];

  final List<String> units = [
    'cups',
    'tbsp',
    'tsp',
    'grams',
    'ml',
    'oz',
    'lb',
  ];

  // Conversion factors relative to grams/ml
  final Map<String, Map<String, double>> conversionFactors = {
    'Flour': {
      'cups': 120.0,
      'tbsp': 7.5,
      'tsp': 2.5,
      'grams': 1.0,
      'oz': 28.35,
      'lb': 453.6,
    },
    'Sugar': {
      'cups': 200.0,
      'tbsp': 12.5,
      'tsp': 4.2,
      'grams': 1.0,
      'oz': 28.35,
      'lb': 453.6,
    },
    'Butter': {
      'cups': 227.0,
      'tbsp': 14.2,
      'tsp': 4.7,
      'grams': 1.0,
      'oz': 28.35,
      'lb': 453.6,
    },
    'Water': {
      'cups': 240.0,
      'tbsp': 15.0,
      'tsp': 5.0,
      'ml': 1.0,
      'grams': 1.0,
      'oz': 29.57,
      'lb': 453.6,
    },
  };

  // Convert the measurement
  void _convertMeasurement() {
    if (selectedIngredient == null || fromUnit == null || toUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select ingredient and units'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      double quantity = double.parse(quantityController.text);
      double convertedValue;
      String densitySource = 'Database';
      
      // Check if we have conversion factors for this ingredient
      if (conversionFactors.containsKey(selectedIngredient)) {
        // Direct conversion using predefined factors
        double valueInGrams = quantity * (conversionFactors[selectedIngredient]![fromUnit] ?? 1.0);
        convertedValue = valueInGrams / (conversionFactors[selectedIngredient]![toUnit] ?? 1.0);
      } else {
        // AI prediction simulation for unknown ingredients
        // In a real app, this would call an AI service
        double estimatedDensity = ingredientDensities.values.reduce((a, b) => a + b) / ingredientDensities.length;
        
        // Convert to grams first using estimated density
        double valueInGrams;
        if (fromUnit == 'grams' || fromUnit == 'ml') {
          valueInGrams = quantity;
        } else if (fromUnit == 'cups') {
          valueInGrams = quantity * estimatedDensity;
        } else if (fromUnit == 'tbsp') {
          valueInGrams = quantity * (estimatedDensity / 16);
        } else if (fromUnit == 'tsp') {
          valueInGrams = quantity * (estimatedDensity / 48);
        } else if (fromUnit == 'oz') {
          valueInGrams = quantity * 28.35;
        } else if (fromUnit == 'lb') {
          valueInGrams = quantity * 453.6;
        } else {
          valueInGrams = quantity;
        }
        
        // Convert from grams to target unit
        if (toUnit == 'grams' || toUnit == 'ml') {
          convertedValue = valueInGrams;
        } else if (toUnit == 'cups') {
          convertedValue = valueInGrams / estimatedDensity;
        } else if (toUnit == 'tbsp') {
          convertedValue = valueInGrams / (estimatedDensity / 16);
        } else if (toUnit == 'tsp') {
          convertedValue = valueInGrams / (estimatedDensity / 48);
        } else if (toUnit == 'oz') {
          convertedValue = valueInGrams / 28.35;
        } else if (toUnit == 'lb') {
          convertedValue = valueInGrams / 453.6;
        } else {
          convertedValue = valueInGrams;
        }
        
        densitySource = 'AI Prediction';
      }
      
      // Get the final value in grams for scale comparison
      double valueInGrams;
      if (toUnit == 'grams' || toUnit == 'ml') {
        valueInGrams = convertedValue;
      } else if (conversionFactors.containsKey(selectedIngredient) && 
                 conversionFactors[selectedIngredient]!.containsKey(toUnit)) {
        valueInGrams = convertedValue * conversionFactors[selectedIngredient]![toUnit]!;
      } else {
        // Estimated for unknown ingredients
        valueInGrams = convertedValue * 120; // Default estimate
      }
      
      setState(() {
        if (toUnit == 'grams' || toUnit == 'ml') {
          result = '${convertedValue.toStringAsFixed(1)}${toUnit == 'grams' ? 'g' : 'ml'}';
        } else {
          result = '${convertedValue.toStringAsFixed(2)} $toUnit (${valueInGrams.toStringAsFixed(1)}g)';
        }
        
        // Simulate scale reading with slight variance
        if (isConnectedToScale) {
          scaleReading = valueInGrams * (0.9 + (0.2 * (DateTime.now().millisecond / 1000)));
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveConversion() {
    if (selectedIngredient != null && result != null) {
      setState(() {
        savedConversions.add({
          'ingredient': selectedIngredient,
          'quantity': quantityController.text,
          'fromUnit': fromUnit,
          'toUnit': toUnit,
          'result': result,
          'timestamp': DateTime.now(),
        });
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversion saved'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  void _connectToScale() {
    // Simulate connecting to a smart scale
    setState(() {
      isConnectedToScale = !isConnectedToScale;
      if (isConnectedToScale) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Smart Scale connected'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        if (result != null) {
          // Update scale reading if there's a current result
          _convertMeasurement();
        }
      } else {
        scaleReading = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Smart Scale disconnected'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'AI Ingredient Converter',
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
                    // Scale connection indicator
                    if (isConnectedToScale)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF4CAF50)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bluetooth_connected, color: Color(0xFF4CAF50)),
                            const SizedBox(width: 8),
                            const Text(
                              'Smart Scale Connected',
                              style: TextStyle(color: Color(0xFF4CAF50)),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _connectToScale,
                              child: const Text('Disconnect'),
                            ),
                          ],
                        ),
                      ),

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
                            labelText: 'Enter Ingredient',
                            hintText: 'Type to search or add new ingredient',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                // Add custom ingredient
                                if (controller.text.isNotEmpty && 
                                    !ingredients.contains(controller.text)) {
                                  setState(() {
                                    ingredients.add(controller.text);
                                    selectedIngredient = controller.text;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added ${controller.text} to ingredients'),
                                      backgroundColor: const Color(0xFF4CAF50),
                                    ),
                                  );
                                }
                              },
                            ),
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
                              // Re-convert if all fields are filled
                              if (selectedIngredient != null && 
                                  fromUnit != null && 
                                  toUnit != null && 
                                  quantityController.text.isNotEmpty) {
                                _convertMeasurement();
                              }
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
                      onPressed: _convertMeasurement,
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${selectedIngredient?.toUpperCase()}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${quantityController.text} $fromUnit = $result',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  radius: 24,
                                  child: Icon(
                                    Icons.kitchen,
                                    color: const Color(0xFF4CAF50),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              conversionFactors.containsKey(selectedIngredient) 
                                  ? 'Source: Database' 
                                  : 'Source: AI Prediction',
                              style: TextStyle(
                                color: conversionFactors.containsKey(selectedIngredient)
                                  ? Colors.grey[600]
                                  : const Color(0xFF4CAF50),
                                fontSize: 12,
                              ),
                            ),
                            
                            if (scaleReading != null && isConnectedToScale) ...[
                              const Divider(height: 24),
                              const Text(
                                'SMART SCALE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Extract the gram value for comparison
                              Builder(
                                builder: (context) {
                                  double targetGrams = 0;
                                  if (result!.contains('g')) {
                                    targetGrams = double.parse(
                                      result!.substring(0, result!.indexOf('g'))
                                    );
                                  } else if (result!.contains('(')) {
                                    String gramPart = result!.substring(
                                      result!.indexOf('(') + 1, 
                                      result!.indexOf('g')
                                    );
                                    targetGrams = double.parse(gramPart);
                                  }
                                  
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: scaleReading! / targetGrams,
                                              backgroundColor: Colors.grey[200],
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                (scaleReading! - targetGrams).abs() < 5
                                                    ? const Color(0xFF4CAF50)
                                                    : Colors.orange,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            '${scaleReading!.toStringAsFixed(1)}g',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        scaleReading! > targetGrams + 5
                                            ? 'Remove ${(scaleReading! - targetGrams).toStringAsFixed(1)}g'
                                            : scaleReading! < targetGrams - 5
                                                ? 'Add ${(targetGrams - scaleReading!).toStringAsFixed(1)}g'
                                                : 'Perfect amount! ✓',
                                        style: TextStyle(
                                          color: (scaleReading! - targetGrams).abs() < 5
                                              ? const Color(0xFF4CAF50)
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              ),
                            ],
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Save Button
                    if (result != null)
                      OutlinedButton.icon(
                        onPressed: _saveConversion,
                        icon: const Icon(Icons.save, color: Color(0xFF4CAF50)),
                        label: const Text('Save Conversion'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Saved conversions
                    if (savedConversions.isNotEmpty) ...[
                      const Text(
                        'SAVED CONVERSIONS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...savedConversions.map((conversion) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            '${conversion['ingredient']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${conversion['quantity']} ${conversion['fromUnit']} = ${conversion['result']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                savedConversions.remove(conversion);
                              });
                            },
                          ),
                          onTap: () {
                            // Load the conversion
                            setState(() {
                              selectedIngredient = conversion['ingredient'];
                              fromUnit = conversion['fromUnit'];
                              toUnit = conversion['toUnit'];
                              quantityController.text = conversion['quantity'];
                              result = conversion['result'];
                            });
                            // Re-calculate to get up-to-date scale reading
                            if (isConnectedToScale) {
                              _convertMeasurement();
                            }
                          },
                        ),
                      )).toList(),
                    ],
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
                    isSelected: isConnectedToScale,
                    onTap: _connectToScale,
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