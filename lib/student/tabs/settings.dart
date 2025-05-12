import 'package:flutter/material.dart';
import 'appearance_settings.dart';
import 'notifications_settings.dart';
import 'privacy_settings.dart';
import 'edit_profile.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.blue[700],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notification Settings'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationSettingsScreen()),
              );
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Privacy Settings'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PrivacySettingsScreen()),
              );
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Profile'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfileScreen()),
              );
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('Appearance'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AppearanceSettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
