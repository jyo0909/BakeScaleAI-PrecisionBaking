import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloudbakers/screens/ingredient_converter_screen.dart';
import 'package:cloudbakers/screens/recipe_import_screen.dart';
import 'package:cloudbakers/screens/smart_scale_screen.dart';
import 'package:cloudbakers/widgets/settings_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSettingsPanelOpen = false;
  final PageController _pageController = PageController(viewportFraction: 0.92);
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Start auto-sliding when the screen initializes
    _startAutoSlide();
  }

  @override
  void dispose() {
    _stopAutoSlide();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    // Create a timer that slides the images every 3 seconds
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      
      final List<Map<String, String>> features = [
        {
          'image': 'assets/images/image1.jpg',
          'subtitle': 'Instantly switch between cups, grams, ounces, and more',
          'title': 'Effortless Measurement Conversion',
        },
        {
          'image': 'assets/images/image2.jpg',
          'subtitle': 'Upload a recipe image or paste text to get structured ingredients and steps',
          'title': 'Instant Recipe Upload',
        },
        {
          'image': 'assets/images/image3.jpg',
          'subtitle': 'Connect a smart scale for accurate weight measurements in real time',
          'title': 'Precision made easy with digital smart scale',
        },
      ];
      
      _currentPage = (_currentPage + 1) % features.length;
      
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> features = [
      {
        'image': 'assets/images/image1.jpg',
        'subtitle': 'Instantly switch between cups, grams, ounces, and more',
        'title': 'Effortless Measurement Conversion',
      },
      {
        'image': 'assets/images/image2.jpg',
        'subtitle': 'Upload a recipe image or paste text to get structured ingredients and steps',
        'title': 'Instant Recipe Upload',
      },
      {
        'image': 'assets/images/image3.jpg',
        'subtitle': 'Connect a smart scale for accurate weight measurements in real time',
        'title': 'Precision made easy with digital smart scale',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Good morning, CloudBakers",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSettingsPanelOpen = true;
                          });
                        },
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFF4CAF50),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "What's on your mind",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: features.length,
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: AssetImage(features[index]['image']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  features[index]['subtitle']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  features[index]['title']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Page indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    features.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),

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
                        isSelected: true,
                        onTap: () {},
                      ),
                      _buildNavButton(
                        icon: Icons.calculate,
                        label: 'Convert Measurement',
                        onTap: () {
                          Navigator.push(
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecipeImportScreen(),
                            ),
                          );
                        },
                      ),
                      _buildNavButton(
                        icon: Icons.bluetooth,
                        label: 'Connect Smart Scale',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SmartScaleScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_isSettingsPanelOpen)
            SettingsPanel(
              userName: "CloudBakers",
              onClose: () {
                setState(() {
                  _isSettingsPanelOpen = false;
                });
              },
            ),
        ],
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