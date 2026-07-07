import 'package:flutter/material.dart';
import 'petlover_home.dart';

void main() {
  runApp(const PetLoverApp());
}

class PetLoverApp extends StatelessWidget {
  const PetLoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetLover - Dog Walking & Vacation Sitting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const PetLoverHomePage(),
    );
  }
}
