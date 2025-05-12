import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings.dart';

class ProfileTab extends StatefulWidget {
  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          setState(() {
            userData = doc.data() as Map<String, dynamic>;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          backgroundColor: Colors.blue[700],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          backgroundColor: Colors.blue[700],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('User profile not found'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _auth.signOut();
                  // Navigate to login screen
                },
                child: Text('Sign Out'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              // Navigate to login screen
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header with photo
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: userData!['photoUrl'] != null 
                          ? NetworkImage(userData!['photoUrl']) 
                          : null,
                      child: userData!['photoUrl'] == null 
                          ? Text(
                              userData!['name']?[0] ?? 'S',
                              style: TextStyle(fontSize: 40),
                            ) 
                          : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      userData!['name'] ?? 'Student',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      userData!['email'] ?? '',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Student ID: ${userData!['studentId'] ?? 'Not available'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
              // Academic Info Section
              _buildSectionHeader('Academic Information'),
              _buildInfoCard([
                _buildInfoRow('Program', userData!['program'] ?? 'Not specified'),
                _buildInfoRow('Year Level', userData!['yearLevel']?.toString() ?? 'Not specified'),
              ]),
              
              SizedBox(height: 20),
              
              // Contact Info Section
              _buildSectionHeader('Contact Information'),
              _buildInfoCard([
                _buildInfoRow('Phone', userData!['phone']?.toString() ?? 'Not provided'),
                _buildInfoRow('Address', userData!['address']?.toString() ?? 'Not provided'),
                _buildInfoRow('Emergency Contact', userData!['emergencyContact']?.toString() ?? 'Not provided'),
              ]),
              
              SizedBox(height: 20),
              
              // Settings
              _buildSectionHeader('Settings'),
              Card(
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
  leading: Icon(Icons.settings),
  title: Text('Settings'),
  trailing: Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen()),
    );
  },
),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Support and Help
              _buildSectionHeader('Support'),
              Card(
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.help),
                      title: Text('Help Center'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to help center
                      },
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.report_problem),
                      title: Text('Report an Issue'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to issue reporting
                      },
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.info),
                      title: Text('About'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // Show about dialog
                      },
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
              // Sign out button
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.logout),
                  label: Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  onPressed: () async {
                    await _auth.signOut();
                    // Navigate to login screen
                  },
                ),
              ),
              
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}