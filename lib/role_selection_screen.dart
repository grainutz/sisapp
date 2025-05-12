import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Role')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to SIS App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                icon: Icon(Icons.school),
                label: Text('Student'),
                onPressed: () => Navigator.pushNamed(context, '/login-student'),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                icon: Icon(Icons.person),
                label: Text('Teacher'),
                onPressed: () => Navigator.pushNamed(context, '/login-teacher'),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                icon: Icon(Icons.admin_panel_settings),
                label: Text('Admin'),
                onPressed: () => Navigator.pushNamed(context, '/login-admin'),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
