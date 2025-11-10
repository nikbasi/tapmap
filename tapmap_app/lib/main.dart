import 'package:flutter/material.dart';
import 'widgets/fountain_map.dart';

void main() {
  runApp(const TapMapApp());
}

class TapMapApp extends StatelessWidget {
  const TapMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapMap',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TapMapHomePage(),
    );
  }
}

class TapMapHomePage extends StatelessWidget {
  const TapMapHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('TapMap - Find Fountains'),
      ),
      body: const FountainMap(),
    );
  }
}
