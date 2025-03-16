import 'package:flutter/material.dart';
import 'package:cloudbakers/screens/ingredient_converter_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RecipeImportScreen extends StatefulWidget {
  const RecipeImportScreen({Key? key}) : super(key: key);

  @override
  State<RecipeImportScreen> createState() => _RecipeImportScreenState();
}

class _RecipeImportScreenState extends State<RecipeImportScreen> with SingleTickerProviderStateMixin {
  bool _isTextMode = true;
  final TextEditingController _recipeTextController = TextEditingController();
  List<String> _extractedIngredients = [];
  late TabController _tabController;
  
  // Image upload variables
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isImageProcessing = false;

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

  void _processRecipe() {
    // Simulate AI extraction for text mode
    setState(() {
      _extractedIngredients = [
        "2 cups all-purpose flour",
        "1 tsp baking powder",
        "1/2 cup sugar",
        // Add more mock ingredients as needed
      ];
    });
  }

  // Function to select an image from gallery
  Future<void> _selectImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          // Clear previous results when new image is selected
          _extractedIngredients = [];
        });
      }
    } catch (e) {
      print("Error selecting image: $e");
    }
  }

  // Function to process selected image and extract ingredients
  void _extractIngredientsFromImage() {
    if (_selectedImage == null) return;
    
    setState(() {
      _isImageProcessing = true;
    });
    
    // Simulate AI extraction delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isImageProcessing = false;
        // Mock extracted ingredients from image
        _extractedIngredients = [
          "3 eggs",
          "2 cups whole milk",
          "1 tbsp vanilla extract",
          "2 1/2 cups cake flour",
          "1 cup granulated sugar",
        ];
      });
    });
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'AI-powered recipe extraction',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
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
                // Text Input Tab
                _buildTextInputTab(),
                // Image Upload Tab
                _buildImageUploadTab(),
              ],
            ),
          ),
          // Bottom Navigation Bar
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
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IngredientConverterScreen(),
                      ),
                    );
                  },
                ),
                _buildNavButton(
                  icon: Icons.upload_file,
                  label: 'Import Recipe',
                  isSelected: true,
                  onTap: () {},
                ),
                _buildNavButton(
                  icon: Icons.bluetooth,
                  label: 'Connect Smart Scale',
                  onTap: () {
                    // Implement smart scale connection
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                hintText: 'What do you want to bake today..',
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ingredients you will need are...'),
          ),
          if (_extractedIngredients.isNotEmpty && _isTextMode) ...[
            const SizedBox(height: 24),
            _buildExtractedIngredientsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildImageUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image preview or upload area
          GestureDetector(
            onTap: _selectImage,
            child: Container(
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
              child: _selectedImage == null
                  ? Column(
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
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          // If no image is selected, show Select Image button
          if (_selectedImage == null)
            ElevatedButton(
              onPressed: _selectImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Select Image'),
            ),
          
          // If image is selected, show Extract Ingredients button
          if (_selectedImage != null && !_isImageProcessing && _extractedIngredients.isEmpty)
            ElevatedButton(
              onPressed: _extractIngredientsFromImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Extract Ingredients'),
            ),
          
          // Show loading indicator when processing
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
          
          // Show extracted ingredients when available
          if (_extractedIngredients.isNotEmpty && !_isTextMode) ...[
            const SizedBox(height: 24),
            _buildExtractedIngredientsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildExtractedIngredientsSection() {
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Extracted Ingredients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                  onPressed: () {
                    // Implement edit functionality
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
                title: Text(_extractedIngredients[index]),
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTextMode ? _processRecipe : _extractIngredientsFromImage,
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
                    onPressed: () {
                      // Implement save functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Recipe'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}