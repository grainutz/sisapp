// admin_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stats variables
  int pendingRequests = 0;
  int totalStudents = 0;
  int totalTeachers = 0;
  int totalCourses = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Get pending requests count
      QuerySnapshot pendingSnapshot = await _firestore
          .collection('registration_requests')
          .where('status', isEqualTo: 'pending')
          .get();
      
      // Get approved students count
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('status', isEqualTo: 'approved')
          .get();
      
      // Get approved teachers count
      QuerySnapshot teachersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .where('status', isEqualTo: 'approved')
          .get();
      
      // Get courses count
      QuerySnapshot coursesSnapshot = await _firestore
          .collection('courses')
          .get();

      if (mounted) {
        setState(() {
          pendingRequests = pendingSnapshot.docs.length;
          totalStudents = studentsSnapshot.docs.length;
          totalTeachers = teachersSnapshot.docs.length;
          totalCourses = coursesSnapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/admin-profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome, ${user?.displayName ?? 'Admin'}!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Pending Requests', 
                      pendingRequests.toString(), 
                      Icons.pending_actions, 
                      Colors.orange,
                      onTap: () => Navigator.pushNamed(context, '/admin-registrations'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Students', 
                      totalStudents.toString(), 
                      Icons.school, 
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Teachers', 
                      totalTeachers.toString(), 
                      Icons.people, 
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Courses', 
                      totalCourses.toString(), 
                      Icons.book, 
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Admin Menu Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    icon: Icons.pending_actions,
                    label: 'Registration Requests',
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/admin-registrations'),
                    badge: pendingRequests > 0 ? pendingRequests.toString() : null,
                  ),
                  _buildMenuCard(
                    icon: Icons.book,
                    label: 'Manage Courses',
                    color: Colors.purple,
                    onTap: () => Navigator.pushNamed(context, '/admin-courses'),
                  ),
                  _buildMenuCard(
                    icon: Icons.people,
                    label: 'User Management',
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/admin-users'),
                  ),
                  _buildMenuCard(
                    icon: Icons.assignment,
                    label: 'Course Assignments',
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/admin-course-assignments'),
                  ),
                  _buildMenuCard(
                    icon: Icons.analytics,
                    label: 'Reports',
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, '/admin-reports'),
                  ),
                  _buildMenuCard(
                    icon: Icons.settings,
                    label: 'System Settings',
                    color: Colors.grey,
                    onTap: () => Navigator.pushNamed(context, '/admin-settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: color),
                  const SizedBox(height: 10),
                  Text(
                    label, 
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}