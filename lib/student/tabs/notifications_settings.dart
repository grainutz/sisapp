import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notification Settings')),
      body: Center(child: Text('Configure your notifications here.')),
    );
  }
}
