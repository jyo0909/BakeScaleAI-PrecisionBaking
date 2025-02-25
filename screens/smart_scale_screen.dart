import 'package:flutter/material.dart';
import 'package:my_recipe_app/screens/ingredient_converter_screen.dart';
import 'package:my_recipe_app/screens/recipe_import_screen.dart';
import 'dart:math' as math;

class SmartScaleScreen extends StatefulWidget {
  const SmartScaleScreen({Key? key}) : super(key: key);

  @override
  State<SmartScaleScreen> createState() => _SmartScaleScreenState();
}

class _SmartScaleScreenState extends State<SmartScaleScreen> with SingleTickerProviderStateMixin {
  bool isConnected = false;
  double currentWeight = 0.0;
  double targetWeight = 100.0;
  String ingredientType = 'Powder';
  late AnimationController _animationController;
  final List<Map<String, dynamic>> measurementHistory = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color getWeightColor() {
    if (currentWeight == targetWeight) return const Color(0xFF4CAF50);
    if (currentWeight > targetWeight) return Colors.red;
    return Colors.grey.shade400;
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
              'Smart Scale Connection',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Real-time weight tracking',
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Connection Panel
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: isConnected ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isConnected ? 'Connected' : 'Disconnected',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  isConnected = !isConnected;
                                });
                              },
                              icon: Icon(isConnected ? Icons.link_off : Icons.link),
                              label: Text(isConnected ? 'Disconnect' : 'Connect'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Weight Display
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(200, 200),
                              painter: WeightDialPainter(
                                progress: currentWeight / targetWeight,
                                color: getWeightColor(),
                                animation: _animationController.value,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${currentWeight.toStringAsFixed(1)}g',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: getWeightColor(),
                          ),
                        ),
                        Text(
                          'Target: ${targetWeight.toStringAsFixed(1)}g',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ingredient Detection
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ingredient Type',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildIngredientType('Powder', Icons.grain),
                            _buildIngredientType('Liquid', Icons.water_drop),
                            _buildIngredientType('Crystal', Icons.diamond),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Implement save log functionality
                              setState(() {
                                measurementHistory.add({
                                  'weight': currentWeight,
                                  'type': ingredientType,
                                  'timestamp': DateTime.now(),
                                });
                              });
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Save Log'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Show history dialog
                              showDialog(
                                context: context,
                                builder: (context) => _buildHistoryDialog(),
                              );
                            },
                            icon: const Icon(Icons.history),
                            label: const Text('View History'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4CAF50),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                  onTap: () {
                    Navigator.pushReplacement(
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
                  isSelected: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientType(String type, IconData icon) {
    final isSelected = type == ingredientType;
    return GestureDetector(
      onTap: () {
        setState(() {
          ingredientType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryDialog() {
    return AlertDialog(
      title: const Text('Measurement History'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: measurementHistory.length,
          itemBuilder: (context, index) {
            final measurement = measurementHistory[index];
            return ListTile(
              title: Text('${measurement['weight']}g ${measurement['type']}'),
              subtitle: Text(
                measurement['timestamp'].toString(),
              ),
              leading: const Icon(Icons.history),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class WeightDialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double animation;

  WeightDialPainter({
    required this.progress,
    required this.color,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // Add subtle animation effect
    final progressWithAnimation = progress * (1 + 0.05 * math.sin(animation * 2 * math.pi));
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progressWithAnimation,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(WeightDialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.animation != animation;
  }
}