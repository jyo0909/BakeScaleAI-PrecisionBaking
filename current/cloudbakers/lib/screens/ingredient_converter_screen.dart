import 'package:flutter/material.dart';
import 'package:cloudbakers/services/baking_api.dart'; // Updated import for baking_api.dart

class IngredientConverterScreen extends StatefulWidget {
  const IngredientConverterScreen({Key? key}) : super(key: key);

  @override
  State<IngredientConverterScreen> createState() =>
      _IngredientConverterScreenState();
}

class _IngredientConverterScreenState extends State<IngredientConverterScreen> {
  // Controllers to capture typed input.
  final TextEditingController ingredientController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  String? selectedIngredient;
  String? selectedCountry;
  String? fromUnit;
  String? toUnit;
  String? result; // Conversion result text.
  bool isConnectedToScale = false;
  double? scaleReading;
  bool _isLoading = false; // For showing progress indicator.
  String? substituteResult; // Holds the substitute suggestion.

  // List for saved conversions.
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

  // List for countries.
  final List<String> countries = ['USA', 'Metric', 'UK', 'Japan'];

  final List<String> units = [
    'cups',
    'tbsp',
    'tsp',
    'grams',
    'ml',
    'oz',
    'lb',
  ];

  // Conversion factors relative to grams/ml.
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

  // Call conversion API and update conversion result.
  void _convertMeasurement() async {
    // Always update selected values from controllers.
    setState(() {
      selectedIngredient = ingredientController.text;
      selectedCountry = countryController.text;
    });

    if (selectedIngredient == null ||
        selectedIngredient!.isEmpty ||
        fromUnit == null ||
        toUnit == null ||
        selectedCountry == null ||
        selectedCountry!.isEmpty ||
        quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select ingredient, country, units and enter quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      double quantity = double.parse(quantityController.text);
      print("Calling API with: ingredient=$selectedIngredient, quantity=$quantity, unit=$fromUnit, country=$selectedCountry");

      final response = await BakingApi.convertIngredient(
        ingredient: selectedIngredient!,
        quantity: quantity,
        unit: fromUnit!,
        country: selectedCountry!,
      );
      print("Conversion API response: $response");

      // Use 'grams' key from response.
      double grams = response['grams'] is double
          ? response['grams']
          : double.parse(response['grams'].toString());

      // Convert grams to the target unit if needed.
      if (toUnit == 'grams' || toUnit == 'ml') {
        result = '${grams.toStringAsFixed(1)}${toUnit == 'grams' ? 'g' : 'ml'}';
      } else if (conversionFactors.containsKey(selectedIngredient) &&
          conversionFactors[selectedIngredient]!.containsKey(toUnit)) {
        double factor = conversionFactors[selectedIngredient]![toUnit]!;
        double convertedValue = grams / factor;
        result = '${convertedValue.toStringAsFixed(2)} $toUnit (${grams.toStringAsFixed(1)}g)';
      } else {
        result = '${grams.toStringAsFixed(1)} g';
      }

      // If smart scale is connected, simulate a reading.
      if (isConnectedToScale) {
        scaleReading = grams * (0.9 + (0.2 * (DateTime.now().millisecond / 1000)));
      }
      setState(() {});
    } catch (e) {
      print("Error during conversion: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Call substitute API and update substituteResult.
  void _suggestSubstitute() async {
    setState(() {
      selectedIngredient = ingredientController.text;
    });
    if (selectedIngredient == null || selectedIngredient!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an ingredient to get a substitute'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      print("Calling substitute API with: ingredient=$selectedIngredient");
      final response = await BakingApi.getSubstitutes(ingredient: selectedIngredient!);
      print("Substitute API response: $response");
      String substitute = "";
      if (response.containsKey('substitutes') && response['substitutes'] is List) {
        substitute = (response['substitutes'] as List).join(', ');
      } else {
        substitute = "No substitute found";
      }
      setState(() {
        substituteResult = substitute;
      });
    } catch (e) {
      print("Error fetching substitute: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching substitute: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save conversion (and substitute if available) to savedConversions.
  void _saveConversion() {
    if (selectedIngredient != null && result != null) {
      setState(() {
        savedConversions.add({
          'ingredient': selectedIngredient,
          'country': selectedCountry,
          'quantity': quantityController.text,
          'fromUnit': fromUnit,
          'toUnit': toUnit,
          'result': result,
          'substitute': substituteResult,
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

  // Toggle smart scale connection.
  void _connectToScale() {
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

  // Show saved conversion details in a popup.
  void _showSavedConversion(Map<String, dynamic> conversion) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            conversion['ingredient'] ?? 'Saved Conversion',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Quantity: ${conversion['quantity']} ${conversion['fromUnit']}\n"
            "Converted: ${conversion['result']}\n"
            "Country: ${conversion['country']}\n"
            "${conversion['substitute'] != null ? "Substitutes: ${conversion['substitute']}" : ""}",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // Wrap the title in a FittedBox to scale down on smaller screens.
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: const Text(
            'AI Ingredient Converter',
            style: TextStyle(
              fontSize: 16.0, // Slightly decreased font size
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
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
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator()),
                    // Smart Scale connection indicator.
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
                            const Icon(Icons.bluetooth_connected,
                                color: Color(0xFF4CAF50)),
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
                    // Ingredient Selection.
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return ingredients.where((String ingredient) {
                          return ingredient.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        setState(() {
                          selectedIngredient = selection;
                          ingredientController.text = selection;
                          // Clear previous results when a new ingredient is chosen.
                          result = null;
                          substituteResult = null;
                        });
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: ingredientController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Enter Ingredient',
                            hintText: 'Type to search or add new ingredient',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (ingredientController.text.isNotEmpty &&
                                    !ingredients.contains(ingredientController.text)) {
                                  setState(() {
                                    ingredients.add(ingredientController.text);
                                    selectedIngredient = ingredientController.text;
                                    result = null;
                                    substituteResult = null;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added ${ingredientController.text} to ingredients'),
                                      backgroundColor: const Color(0xFF4CAF50),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              result = null;
                              substituteResult = null;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Country Selection.
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return countries.where((String country) {
                          return country.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        setState(() {
                          selectedCountry = selection;
                          countryController.text = selection;
                        });
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: countryController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Enter Country',
                            hintText: 'Type to search or add new country',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.public),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (countryController.text.isNotEmpty &&
                                    !countries.contains(countryController.text)) {
                                  setState(() {
                                    countries.add(countryController.text);
                                    selectedCountry = countryController.text;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added ${countryController.text} to countries'),
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
                    // Unit Conversion Row.
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: fromUnit,
                            decoration: InputDecoration(
                              labelText: 'From',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
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
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: () {
                            setState(() {
                              final temp = fromUnit;
                              fromUnit = toUnit;
                              toUnit = temp;
                              if (selectedIngredient != null &&
                                  fromUnit != null &&
                                  toUnit != null &&
                                  quantityController.text.isNotEmpty) {
                                _convertMeasurement();
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: toUnit,
                            decoration: InputDecoration(
                              labelText: 'To',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
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
                    // Quantity Input.
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Convert Button.
                    ElevatedButton(
                      onPressed: _convertMeasurement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Convert', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 16),
                    // Suggest Substitute Button.
                    ElevatedButton(
                      onPressed: _suggestSubstitute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Suggest substitute', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 24),
                    // Result Display (appended with substitute if available).
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
                                          color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${quantityController.text} $fromUnit = $result',
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  radius: 24,
                                  child: Icon(Icons.kitchen,
                                      color: const Color(0xFF4CAF50), size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              conversionFactors.containsKey(selectedIngredient)
                                  ? 'Source: Database'
                                  : 'Source: BakeScaleAIs Most Intelligent Model',
                              style: TextStyle(
                                color: conversionFactors.containsKey(selectedIngredient)
                                    ? Colors.grey[600]
                                    : const Color(0xFF4CAF50),
                                fontSize: 12,
                              ),
                            ),
                            if (substituteResult != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "Substitutes: $substituteResult",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Save Button.
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
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Saved conversions list.
                    if (savedConversions.isNotEmpty) ...[
                      const Text(
                        'SAVED CONVERSIONS',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ...savedConversions.map((conversion) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(
                                '${conversion['ingredient']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  '${conversion['quantity']} ${conversion['fromUnit']} = ${conversion['result']}' +
                                      (conversion['country'] != null
                                          ? ' (${conversion['country']})'
                                          : '')),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    savedConversions.remove(conversion);
                                  });
                                },
                              ),
                              onTap: () {
                                _showSavedConversion(conversion);
                              },
                            ),
                          )).toList(),
                    ],
                  ],
                ),
              ),
            ),
            // Bottom Navigation Bar optimized with Expanded widgets.
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildNavButton(
                      icon: Icons.home,
                      label: 'Home',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildNavButton(
                      icon: Icons.calculate,
                      label: 'Convert Measurement',
                      isSelected: true,
                      onTap: () {},
                    ),
                  ),
                  Expanded(
                    child: _buildNavButton(
                      icon: Icons.upload_file,
                      label: 'Import Recipe',
                      onTap: () {},
                    ),
                  ),
                  Expanded(
                    child: _buildNavButton(
                      icon: Icons.bluetooth,
                      label: 'Connect Smart Scale',
                      isSelected: isConnectedToScale,
                      onTap: _connectToScale,
                    ),
                  ),

                      // >>> NEW BUTTON FOR VOICE ASSISTANT <<<
                      Expanded(
                        child: _buildNavButton(
                          icon: Icons.mic,
                          label: 'BakeBot',
                          onTap: () {
                            Navigator.pushNamed(context, '/voice-assistant');
                          },
                        ),
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
          Icon(icon, color: isSelected ? const Color(0xFF4CAF50) : Colors.grey),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,
              style: TextStyle(
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
                  fontSize: 8.1),
            ),
          ),
        ],
      ),
    );
  }
}
