import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloudbakers/screens/ingredient_converter_screen.dart';
import 'package:cloudbakers/screens/recipe_import_screen.dart';
import 'package:cloudbakers/screens/smart_scale_screen.dart';
import 'package:cloudbakers/widgets/settings_panel.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  
  const HomeScreen({Key? key, required this.username}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  bool _isSettingsPanelOpen = false;
  final PageController _pageController = PageController(viewportFraction: 0.92);
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  bool _isNavigating = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    // Delay starting the auto-slide to ensure widget is fully initialized
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_isNavigating) {
        _startAutoSlide();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure we're not in a navigation transition
    _isNavigating = false;
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoSlide();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopAutoSlide();
    } else if (state == AppLifecycleState.resumed) {
      // Add a small delay before restarting auto slide
      if (!_isNavigating && mounted && !_isDisposed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_isNavigating && !_isDisposed) {
            _startAutoSlide();
          }
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    if (_isDisposed) return;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: widget.username)
          .get();
      
      if (snapshot.docs.isNotEmpty && mounted && !_isDisposed) {
        setState(() {
          _userData = snapshot.docs.first.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _logout() async {
    if (_isDisposed) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('userId');
    
    if (mounted && !_isDisposed) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _startAutoSlide() {
    // Don't start a new timer if one is already running or widget is disposed
    if (_autoSlideTimer != null || _isDisposed || !mounted) return;
    
    // Create a timer that slides the images every 3 seconds
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || _isNavigating || _isDisposed) {
        _stopAutoSlide();
        return;
      }

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

      if (mounted && _pageController.hasClients && !_isDisposed) {
        try {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } catch (e) {
          // Handle any animation errors
          _stopAutoSlide();
        }
      }
    });
  }

  void _stopAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
    
    // Cancel any ongoing animations safely
    if (_pageController.hasClients && mounted && !_isDisposed) {
      try {
        if (_pageController.position.isScrollingNotifier.value) {
          _pageController.position.jumpTo(_pageController.position.pixels);
        }
      } catch (e) {
        // Safely ignore errors if controller is in an invalid state
      }
    }
  }

  void _navigateToScreen(Widget screen) {
    if (_isNavigating || _isDisposed || !mounted) return;
    
    // First stop any animations and set state
    _stopAutoSlide();
    
    setState(() {
      _isNavigating = true;
    });
    
    // Important: Use pushReplacement for SmartScaleScreen to avoid stacking issues
    if (screen is SmartScaleScreen) {
      // Use a very short delay to ensure UI updates before navigation
      Future.delayed(const Duration(milliseconds: 10), () {
        if (!mounted || _isDisposed) return;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => screen),
        );
      });
    } else {
      // For other screens, use regular push with the return handler
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => screen),
      ).then((_) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isNavigating = false;
          });
          
          // Add delay before restarting auto slide
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && !_isNavigating && !_isDisposed) {
              _startAutoSlide();
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Skip build if disposed
    if (_isDisposed) return const SizedBox.shrink();
    
    // Determine the device width to adjust text sizes for mobile
    final double screenWidth = MediaQuery.of(context).size.width;
    final double greetingFontSize = screenWidth < 400 ? 30 : 40;
    final double subheadingFontSize = screenWidth < 400 ? 20 : 30;

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

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Center aligned header with greeting text and avatar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          "Good morning, ${widget.username}",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: greetingFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 50,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            if (!_isNavigating && !_isDisposed && mounted) {
                              setState(() {
                                _isSettingsPanelOpen = true;
                              });
                            }
                          },
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFF4CAF50),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Center aligned subheading with Montserrat bold
                Center(
                  child: Container(
                    width: screenWidth * 0.9, // Constrain width for proper wrapping
                    child: Text(
                      "What's on your mind?",
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: GoogleFonts.montserrat(
                        fontSize: subheadingFontSize,
                        fontWeight: FontWeight.bold,
                      ),
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
                        // Only update if not already navigating or disposing
                        if (mounted && !_isNavigating && !_isDisposed) {
                          setState(() {
                            _currentPage = page;
                          });
                        }
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: AssetImage(features[index]['image']!),
                              fit: BoxFit.cover,
                              onError: (_, __) => const Icon(Icons.image_not_supported), // Fallback if image not found
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

                // Bottom Navigation Bar with working navigation
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
                    children: [
                      Expanded(
                        child: _buildNavButton(
                          icon: Icons.home,
                          label: 'Home',
                          isSelected: true,
                          onTap: () {},
                        ),
                      ),
                      Expanded(
                        child: _buildNavButton(
                          icon: Icons.calculate,
                          label: 'Convert Measurement',
                          onTap: () {
                            if (!_isNavigating && !_isDisposed) {
                              _navigateToScreen(const IngredientConverterScreen());
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: _buildNavButton(
                          icon: Icons.upload_file,
                          label: 'Import Recipe',
                          onTap: () {
                            if (!_isNavigating && !_isDisposed) {
                              _navigateToScreen(const RecipeImportScreen());
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: _buildNavButton(
                          icon: Icons.bluetooth,
                          label: 'BakeScale',
                          onTap: () {
                            if (!_isNavigating && !_isDisposed) {
                              _navigateToScreen(const SmartScaleScreen());
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Settings panel with logout functionality
          if (_isSettingsPanelOpen && !_isDisposed)
            _buildSettingsPanel(),
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
    // Check if disposed before building
    if (_isDisposed) return const SizedBox.shrink();
    
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
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updated method to connect logout functionality
  Widget _buildSettingsPanel() {
    // Check if disposed before building
    if (_isDisposed) return const SizedBox.shrink();
    
    return SettingsPanel(
      onClose: () {
        if (mounted && !_isDisposed) {
          setState(() {
            _isSettingsPanelOpen = false;
          });
        }
      },
      userName: widget.username,
      profileImageUrl: _userData != null && _userData!.containsKey('profileImageUrl') 
          ? _userData!['profileImageUrl'] 
          : null,
      onLogout: _logout,
    );
  }
}