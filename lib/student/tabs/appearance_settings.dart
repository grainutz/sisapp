import 'package:flutter/material.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Appearance')),
      body: Center(child: Text('Customize the app appearance.')),
    );
  }
}
