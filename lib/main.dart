import 'package:flutter/material.dart';
import 'package:image_picker_tutorial/home_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Image Picker Demo', home: HomePage());
  }
}
