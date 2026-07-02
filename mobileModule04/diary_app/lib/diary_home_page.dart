import 'package:flutter/material.dart';

class DiaryHomePage extends StatelessWidget {
  const DiaryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Diary"),
      ),
      body: const Center(
        child: Text(
          "Welcome to your diary 📖",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}