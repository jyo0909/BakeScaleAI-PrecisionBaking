import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloudbakers/services/gemini_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloudbakers/screens/ingredient_converter_screen.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloudbakers/services/baking_api.dart'; // Adjust the import path if needed

// Enhanced model to hold ingredient details, plus skipConversion.
class Ingredient {
  final double quantity;
  final String unit;
  final String name;
  final bool skipConversion; // whether to skip conversion API call

  Ingredient({
    required this.quantity,
    required this.unit,
    required this.name,
    this.skipConversion = false,
  });

  @override
  String toString() {
    if (unit.isNotEmpty) {
      return '$quantity $unit $name';
    }
    return '$quantity $name';
  }
}

class RecipeImportScreen extends StatefulWidget {
  const RecipeImportScreen({Key? key}) : super(key: key);

  @override
  State<RecipeImportScreen> createState() => _RecipeImportScreenState();
}

class _RecipeImportScreenState extends State<RecipeImportScreen>
    with SingleTickerProviderStateMixin {
  bool _isTextMode = true;
  final TextEditingController _recipeTextController = TextEditingController();
  late TabController _tabController;

  // Holds the extracted ingredients as a list of Ingredient objects.
  List<Ingredient> _extractedIngredients = [];
  // New field to store instructions from the recipe.
  List<String> _instructions = [];

  // New field to store the recipe heading (name)
  String? _recipeName;

  // Image upload variables
  File? _selectedImage; // used for mobile
  Uint8List? _selectedImageBytes; // used for web
  double? _imageAspectRatio;
  final ImagePicker _picker = ImagePicker();
  bool _isImageProcessing = false;

  // State variables for conversions and substitutions
  String _selectedCountry = "US";
  bool _isConverting = false;
  List<Map<String, dynamic>> _conversionResults = [];
  // Instead of saving just conversion results, we now store a log with recipe name.
  List<Map<String, dynamic>> _savedConversions = [];
  String? _selectedSubstitutionIngredient;
  String? _substitutionResult;
  bool _isSubstituting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isTextMode = _tabController.index == 0;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recipeTextController.dispose();
    super.dispose();
  }

  /// For text mode, simulate extraction with Gemini API including instructions.
  void _processRecipe() async {
    final dishName = _recipeTextController.text.trim();

    if (dishName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipe name!')),
      );
      return;
    }

    setState(() {
      _isConverting = true;
      _recipeName = dishName;
      _extractedIngredients.clear();
      _instructions.clear();
      _conversionResults.clear();
      _substitutionResult = null;
      _selectedSubstitutionIngredient = null;
    });

    try {
      final recipeData = await GeminiApi.getRecipe(dishName);
      // Expecting a JSON object with keys "ingredients" and "instructions"
      final ingredientsJson = recipeData['ingredients'] as List<dynamic>;
      final instructionsJson = recipeData['instructions'] as List<dynamic>;

      final ingredients = ingredientsJson.map<Ingredient>((ing) {
        return Ingredient(
          quantity: (ing['quantity'] as num).toDouble(),
          unit: ing['unit'],
          name: ing['name'],
          skipConversion: ing['skipConversion'] ?? false,
        );
      }).toList();

      final instructions = instructionsJson.map((step) => step.toString()).toList();

      setState(() {
        _recipeName = dishName;
        _extractedIngredients = ingredients;
        _instructions = instructions;
      });
    } catch (e) {
      print("Error fetching recipe: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't fetch recipe for $dishName")),
      );
    } finally {
      setState(() {
        _isConverting = false;
      });
    }
  }

  /// Pick an image from the gallery.
  Future<void> _selectImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          // For web, read bytes directly.
          final bytes = await image.readAsBytes();
          ui.decodeImageFromList(bytes, (img) {
            setState(() {
              _selectedImageBytes = bytes;
              _imageAspectRatio = img.width / img.height;
              _selectedImage = null;
              // Clear previous extraction results, recipe name, and instructions.
              _extractedIngredients.clear();
              _instructions.clear();
              _conversionResults.clear();
              _substitutionResult = null;
              _selectedSubstitutionIngredient = null;
              _recipeName = null;
            });
          });
        } else {
          // For mobile platforms, use File.
          final file = File(image.path);
          final bytes = await file.readAsBytes();
          ui.decodeImageFromList(bytes, (img) {
            setState(() {
              _selectedImage = file;
              _imageAspectRatio = img.width / img.height;
              _selectedImageBytes = null;
              // Clear previous extraction results, recipe name, and instructions.
              _extractedIngredients.clear();
              _instructions.clear();
              _conversionResults.clear();
              _substitutionResult = null;
              _selectedSubstitutionIngredient = null;
              _recipeName = null;
            });
          });
        }
      }
    } catch (e) {
      print("Error selecting image: $e");
    }
  }

  /// Load service account credentials and get an access token.
  Future<String> _getAccessToken() async {
    final jsonString =
        await rootBundle.loadString('assets/vision_credentials.json');
    final credentials = ServiceAccountCredentials.fromJson(jsonString);
    const scopes = ['https://www.googleapis.com/auth/cloud-platform'];
    final client = await clientViaServiceAccount(credentials, scopes);
    return client.credentials.accessToken.data;
  }

  /// Use Google Cloud Vision API to extract text from the selected image.
  /// This method now also extracts the recipe heading from the first nonempty line.
  Future<void> _extractIngredientsFromImage() async {
    Uint8List bytes;
    if (kIsWeb) {
      if (_selectedImageBytes == null) return;
      bytes = _selectedImageBytes!;
    } else {
      if (_selectedImage == null) return;
      bytes = await _selectedImage!.readAsBytes();
    }

    setState(() {
      _isImageProcessing = true;
    });

    try {
      final base64Image = base64Encode(bytes);

      final requestPayload = jsonEncode({
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'DOCUMENT_TEXT_DETECTION'}
            ],
          }
        ]
      });

      final accessToken = await _getAccessToken();

      final response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: requestPayload,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String fullText = '';

        if (responseData['responses'] != null &&
            responseData['responses'].length > 0) {
          if (responseData['responses'][0]['fullTextAnnotation'] != null) {
            fullText = responseData['responses'][0]['fullTextAnnotation']
                    ['text'] ??
                '';
          } else if (responseData['responses'][0]['textAnnotations'] != null &&
              responseData['responses'][0]['textAnnotations'].length > 0) {
            fullText = responseData['responses'][0]['textAnnotations'][0]
                    ['description'] ??
                '';
          }
        }

        // Split the full text into lines.
        List<String> allLines = fullText
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

        // Assume the first line is the recipe name (heading).
        if (allLines.isNotEmpty) {
          _recipeName = allLines.first;
          // Use the remaining lines for ingredient extraction.
          allLines = allLines.sublist(1);
        }

        final ingredientsText = allLines.join('\n');
        List<Ingredient> ingredients = _parseIngredients(ingredientsText);

        setState(() {
          _extractedIngredients = ingredients;
          _conversionResults = [];
          _substitutionResult = null;
          _selectedSubstitutionIngredient = null;
          // Note: When extracting from image, instructions are not generated.
          _instructions = [];
        });
      } else {
        print('Google Cloud Vision API error: ${response.body}');
      }
    } catch (e) {
      print('Error extracting ingredients: $e');
    } finally {
      setState(() {
        _isImageProcessing = false;
      });
    }
  }

  /// A dictionary to unify different short forms (including "t" => "tsp").
  final Map<String, String> _unitSynonyms = {
    'c': 'cups',
    'cup': 'cups',
    'cups': 'cups',
    'tbsp': 'tbsp',
    'tbs': 'tbsp',
    'tablespoon': 'tbsp',
    'tablespoons': 'tbsp',
    'T': 'tbsp',
    'ts': 'tsp',
    'tsp': 'tsp',
    'teaspoon': 'tsp',
    'teaspoons': 'tsp',
    't': 'tsp',
  };

  /// Units that mean the quantity is already precise.
  final Set<String> _skipConversionUnits = {
    'g',
    'grams',
    'ml',
    'egg',
    'eggs',
    'pinch',
  };

  /// Keywords indicating the line is likely directions rather than ingredients.
  final List<String> _skipKeywords = [
    'bake',
    'oven',
    'preheat',
    'minutes',
    'mix',
    'stir',
    'whisk',
    'cook',
    'heat',
    'simmer',
    'rest',
    'refrigerate',
    'cool',
    'pour',
    'combine',
    'line',
    'fold',
    'serve',
    'beat',
  ];

  /// Parse text to extract ingredients as Ingredient objects, skipping lines that look like directions.
  ///
  /// Handles examples such as:
  /// - "150g plain flour" → quantity=150, unit="g", name="plain flour", skipConversion=true
  /// - "A pinch of salt" → quantity=1, unit="pinch", name="salt", skipConversion=true
  /// - "1 large egg" → quantity=1, unit="egg(s)", name="large", skipConversion=true
  /// - "200ml of milk" → quantity=200, unit="ml", name="milk", skipConversion=true
  /// - "1/2 oil" → quantity=0.5, unit="cups", name="oil", skipConversion=false (ambiguous unit)
  /// - "1 t baking powder" → quantity=1, unit="tsp", name="baking powder", skipConversion=false
  List<Ingredient> _parseIngredients(String text) {
    List<Ingredient> ingredients = [];
    List<String> lines = text.split('\n');

    // Regexes and special checks.
    final pinchRegex = RegExp(r'^(?:a\s+pinch\s+of\s+)(.*)$', caseSensitive: false);
    final gramsRegex = RegExp(r'^(\d+(?:\.\d+)?)\s*(g|grams)\s+(.*)$', caseSensitive: false);
    final mlRegex = RegExp(r'^(\d+(?:\.\d+)?)\s*(ml)\s+(.*)$', caseSensitive: false);
    final eggRegex = RegExp(r'^(\d+)\s+(.*egg.*)$', caseSensitive: false);

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      final lowerLine = line.toLowerCase();
      if (_skipKeywords.any((kw) => lowerLine.contains(kw))) continue;

      // Check for "A pinch of X"
      final pinchMatch = pinchRegex.firstMatch(lowerLine);
      if (pinchMatch != null) {
        final name = pinchMatch.group(1)?.trim() ?? '';
        ingredients.add(
          Ingredient(
            quantity: 1,
            unit: 'pinch',
            name: name,
            skipConversion: true,
          ),
        );
        continue;
      }

      // Check for grams and ml lines
      final gramsMatch = gramsRegex.firstMatch(lowerLine);
      if (gramsMatch != null) {
        final qtyStr = gramsMatch.group(1) ?? '';
        final unitStr = gramsMatch.group(2) ?? '';
        final nameStr = gramsMatch.group(3)?.trim() ?? '';
        final qty = double.tryParse(qtyStr) ?? 0;
        ingredients.add(
          Ingredient(
            quantity: qty,
            unit: unitStr.toLowerCase(),
            name: nameStr,
            skipConversion: true,
          ),
        );
        continue;
      }
      final mlMatch = mlRegex.firstMatch(lowerLine);
      if (mlMatch != null) {
        final qtyStr = mlMatch.group(1) ?? '';
        final unitStr = mlMatch.group(2) ?? '';
        final nameStr = mlMatch.group(3)?.trim() ?? '';
        final qty = double.tryParse(qtyStr) ?? 0;
        ingredients.add(
          Ingredient(
            quantity: qty,
            unit: unitStr.toLowerCase(),
            name: nameStr,
            skipConversion: true,
          ),
        );
        continue;
      }

      // Check for eggs lines.
      final eggMatch = eggRegex.firstMatch(line);
      if (eggMatch != null) {
        final qtyStr = eggMatch.group(1) ?? '1';
        final nameStr = eggMatch.group(2)?.trim() ?? 'egg';
        final qty = double.tryParse(qtyStr) ?? 1;
        String finalUnit = nameStr.toLowerCase().contains('egg') ? 'eggs' : 'egg';
        String finalName = nameStr.replaceAll(RegExp(r'\beggs?\b', caseSensitive: false), '').trim();
        ingredients.add(
          Ingredient(
            quantity: qty,
            unit: finalUnit,
            name: finalName,
            skipConversion: true,
          ),
        );
        continue;
      }

      // Otherwise, use a simpler token-based approach.
      final tokens = line.split(RegExp(r'\s+'));
      if (tokens.isEmpty) continue;
      double? quantity = _parseFractionOrNumber(tokens[0]);
      if (quantity == null) continue;

      String possibleUnit = tokens.length >= 2 ? tokens[1].toLowerCase() : '';
      String restName = tokens.length >= 2 ? tokens.sublist(1).join(' ').trim() : '';

      String finalUnit = '';
      if (tokens.length == 1) {
        finalUnit = 'cups';
        restName = '';
      } else {
        if (_unitSynonyms.containsKey(possibleUnit)) {
          finalUnit = _unitSynonyms[possibleUnit]!;
          restName = tokens.length > 2 ? tokens.sublist(2).join(' ').trim() : '';
        } else {
          finalUnit = 'cups';
          restName = tokens.sublist(1).join(' ').trim();
        }
      }

      bool skip = _skipConversionUnits.contains(finalUnit);
      ingredients.add(
        Ingredient(
          quantity: quantity,
          unit: finalUnit,
          name: restName,
          skipConversion: skip,
        ),
      );
    }
    return ingredients;
  }

  /// Attempt to parse a fraction or decimal from a token.
  double? _parseFractionOrNumber(String token) {
    if (token.contains('/')) {
      var parts = token.split('/');
      if (parts.length == 2) {
        double? numVal = double.tryParse(parts[0]);
        double? denVal = double.tryParse(parts[1]);
        if (numVal != null && denVal != null && denVal != 0) {
          return numVal / denVal;
        }
      }
    }
    return double.tryParse(token);
  }

  /// Convert each extracted ingredient via the BakingApi, skipping those flagged as precise.
  Future<void> _getConversions() async {
    if (_extractedIngredients.isEmpty) return;
    setState(() {
      _isConverting = true;
      _conversionResults = [];
    });

    List<Map<String, dynamic>> results = [];
    for (var ingredient in _extractedIngredients) {
      if (ingredient.skipConversion) continue;
      try {
        var result = await BakingApi.convertIngredient(
          ingredient: ingredient.name,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          country: _selectedCountry,
        );
        results.add({
          "ingredient": ingredient,
          "conversion": result,
        });
      } catch (e) {
        results.add({
          "ingredient": ingredient,
          "conversion": {"error": e.toString()},
        });
      }
    }

    setState(() {
      _conversionResults = results;
      _isConverting = false;
    });
  }

  /// Save the current conversion results along with the recipe name and instructions.
  void _saveRecipe() {
    setState(() {
      _savedConversions.add({
        "recipeName": _recipeName,
        "conversions": _conversionResults,
        "instructions": _instructions,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Recipe conversions saved!")),
    );
  }

  /// Display saved conversions (with recipe name and instructions) in an AlertDialog.
  void _viewSaved() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Saved Recipe Conversions"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _savedConversions.length,
              itemBuilder: (context, index) {
                var log = _savedConversions[index];
                String recipeName = log["recipeName"] ?? "Unnamed Recipe";
                List conversions = log["conversions"] ?? [];
                List instructions = log["instructions"] ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipeName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ...conversions.map((item) {
                      Ingredient ing = item["ingredient"];
                      Map<String, dynamic> conv =
                          item["conversion"] as Map<String, dynamic>;
                      return _buildConversionContainer(ing, conv, isFromSaved: true);
                    }).toList(),
                    if (instructions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Instructions:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...instructions.map((step) => Text("• $step")).toList(),
                    ],
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        );
      },
    );
  }

  /// Call the substitution API for the selected ingredient and format the result.
  Future<void> _getSubstitution(String ingredientName) async {
    setState(() {
      _isSubstituting = true;
      _substitutionResult = null;
    });
    try {
      final response = await BakingApi.getSubstitutes(ingredient: ingredientName);
      final ingName = response['ingredient'] ?? ingredientName;
      final subsList = response['substitutes'] ?? [];
      if (subsList is List) {
        final joined = subsList.join(', ');
        _substitutionResult = "Possible substitutes for $ingName: $joined";
      } else {
        _substitutionResult = "No substitutes found for $ingName";
      }
    } catch (e) {
      _substitutionResult = "Error: $e";
    } finally {
      setState(() {
        _isSubstituting = false;
      });
    }
  }

  /// A single conversion container, styled like in IngredientConverterScreen.
  Widget _buildConversionContainer(
    Ingredient ing,
    Map<String, dynamic> conversion, {
    bool isFromSaved = false,
  }) {
    String resultText = conversion.toString();
    if (conversion.containsKey('grams')) {
      final gramsVal = conversion['grams'];
      resultText = gramsVal != null ? '$gramsVal grams' : conversion.toString();
    }
    final topLine = '${ing.quantity} ${ing.unit} = $resultText';
    if (conversion.containsKey('error')) {
      resultText = conversion['error'].toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          // Top row with the ingredient name and an icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // For the ingredient name, let's wrap in an Expanded to avoid overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ing.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topLine,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
            isFromSaved
                ? 'Source: (Saved Conversion)'
                : 'Source: BakeScaleAIs Most Intelligent Model',
            style: TextStyle(
              color: isFromSaved ? Colors.grey[600] : const Color(0xFF4CAF50),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a section to display a preview of the selected image.
  Widget _buildImagePreview() {
    if (kIsWeb && _selectedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final containerWidth = constraints.maxWidth;
            final dynamicHeight = _imageAspectRatio != null
                ? containerWidth / _imageAspectRatio!
                : 200.0;
            final previewHeight = min(dynamicHeight, 300.0);
            return SizedBox(
              width: containerWidth,
              height: previewHeight,
              child: Image.memory(_selectedImageBytes!, fit: BoxFit.contain),
            );
          },
        ),
      );
    } else if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final containerWidth = constraints.maxWidth;
            final dynamicHeight = _imageAspectRatio != null
                ? containerWidth / _imageAspectRatio!
                : 200.0;
            final previewHeight = min(dynamicHeight, 300.0);
            return SizedBox(
              width: containerWidth,
              height: previewHeight,
              child: Image.file(_selectedImage!, fit: BoxFit.contain),
            );
          },
        ),
      );
    } else {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to upload image',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Build the main container with extracted ingredients and conversion results.
  Widget _buildExtractedIngredientsSection() {
    // Dynamically adjust fonts for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    // Smaller font if screen < 400; else bigger
    final double recipeNameFontSize = screenWidth < 400 ? 14 : 20;
    final double substitutionFontSize = screenWidth < 400 ? 14 : 16;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header showing recipe name if available, or "Extracted Ingredients"
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Wrap the name in Expanded + ellipsis so it doesn't overflow
                Expanded(
                  child: _recipeName != null
                      ? Text(
                          _recipeName!.toUpperCase(),
                          style: TextStyle(
                            fontSize: recipeNameFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : const Text(
                          'Extracted Ingredients',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                  onPressed: () {
                    // Optionally allow editing of the recipe name.
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _extractedIngredients.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  _extractedIngredients[index].toString(),
                  overflow: TextOverflow.visible,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _extractedIngredients.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isTextMode
                            ? _processRecipe
                            : _extractIngredientsFromImage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Re-extract',
                          style: TextStyle(color: Color(0xFF4CAF50)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _getConversions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isConverting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Get Conversions'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saveRecipe,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Recipe',
                          style: TextStyle(color: Color(0xFF4CAF50)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _viewSaved,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View Saved',
                          style: TextStyle(color: Color(0xFF4CAF50)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_conversionResults.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conversion Results:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _conversionResults.length,
                    itemBuilder: (context, index) {
                      var item = _conversionResults[index];
                      Ingredient ing = item["ingredient"];
                      Map<String, dynamic> conv =
                          item["conversion"] as Map<String, dynamic>;
                      return _buildConversionContainer(ing, conv);
                    },
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1),
          // Ingredient Substitution
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingredient Substitution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  hint: Text(
                    "If you want an ingredient substitution, select the ingredient:",
                    style: TextStyle(
                      fontSize: 8,
                    ),
                  ),
                  value: _selectedSubstitutionIngredient,
                  isExpanded: true,
                  items: _extractedIngredients.map((ing) {
                    return DropdownMenuItem<String>(
                      value: ing.name,
                      child: Text(
                        ing.name,
                        style: TextStyle(fontSize: substitutionFontSize),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedSubstitutionIngredient = newValue;
                    });
                    if (newValue != null) {
                      _getSubstitution(newValue);
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (_isSubstituting)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                if (_substitutionResult != null && !_isSubstituting)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
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
                            Expanded(
                              child: Text(
                                (_selectedSubstitutionIngredient ?? 'SUBSTITUTION')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: const Color(0xFFE8F5E9),
                              radius: 24,
                              child: Icon(
                                Icons.swap_horiz,
                                color: const Color(0xFF4CAF50),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _substitutionResult ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Source: BakeScaleAIs Most Intelligent Model',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a section to display instructions from the recipe.
  Widget _buildInstructionsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = screenWidth < 400 ? 14 : 20;
    final double stepFontSize = screenWidth < 400 ? 12 : 16;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _instructions.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${index + 1}. ${_instructions[index]}',
                  style: TextStyle(fontSize: stepFontSize),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Text input tab.
  Widget _buildTextInputTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _recipeTextController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'What are you planning to bake today?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _processRecipe,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Get Recipe'),
          ),
          if (_extractedIngredients.isNotEmpty && _isTextMode) ...[
            const SizedBox(height: 24),
            _buildExtractedIngredientsSection(),
          ],
          if (_instructions.isNotEmpty && _isTextMode) ...[
            const SizedBox(height: 24),
            _buildInstructionsSection(),
          ],
        ],
      ),
    );
  }

  /// Image upload tab.
  Widget _buildImageUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _selectImage,
            child: _buildImagePreview(),
          ),
          const SizedBox(height: 16),
          if ((_selectedImage == null && _selectedImageBytes == null))
            ElevatedButton(
              onPressed: _selectImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Select Image'),
            ),
          if ((_selectedImage != null || _selectedImageBytes != null) &&
              !_isImageProcessing &&
              _extractedIngredients.isEmpty)
            ElevatedButton(
              onPressed: _extractIngredientsFromImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Extract Ingredients'),
            ),
          if (_isImageProcessing) ...[
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Analyzing your recipe image...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ],
          if (_extractedIngredients.isNotEmpty && !_isTextMode) ...[
            const SizedBox(height: 24),
            _buildExtractedIngredientsSection(),
          ],
          if (_instructions.isNotEmpty && !_isTextMode) ...[
            const SizedBox(height: 24),
            _buildInstructionsSection(),
          ],
        ],
      ),
    );
  }

  /// Build a custom navigation button. (For bottom nav)
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
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
                fontSize: 8.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import & Extract Recipe',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'AI Recipe Extraction',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _selectedCountry,
              underline: Container(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCountry = newValue!;
                });
              },
              items: ["US", "UK", "Metric", "Japan"]
                  .map((country) => DropdownMenuItem<String>(
                        value: country,
                        child: Text(country),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4CAF50),
              labelColor: const Color(0xFF4CAF50),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontSize: 12),
              tabs: const [
                Tab(
                  icon: Icon(Icons.paste),
                  text: 'Paste Recipe Text',
                ),
                Tab(
                  icon: Icon(Icons.image),
                  text: 'Upload Recipe Image',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextInputTab(),
                _buildImageUploadTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
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
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IngredientConverterScreen(),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildNavButton(
                  icon: Icons.upload_file,
                  label: 'Import Recipe',
                  isSelected: true,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: _buildNavButton(
                  icon: Icons.bluetooth,
                  label: 'BakeScale',
                  onTap: () {
                    // Implement smart scale connection if needed.
                  },
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
      ),
    );
  }
}
