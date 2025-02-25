import 'package:flutter/material.dart';
import 'home_screen.dart';  // Import the home screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recipe App',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomeScreen(),  // Set HomeScreen as the main page
    );
  }
}
