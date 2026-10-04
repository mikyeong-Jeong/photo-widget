import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import 'theme.dart';

class PhotoWidgetApp extends StatelessWidget {
  const PhotoWidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Widget',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const HomeScreen(),
    );
  }
}
