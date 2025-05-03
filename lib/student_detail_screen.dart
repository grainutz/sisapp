// screens/student_detail_screen.dart
import 'package:flutter/material.dart';

class StudentDetailScreen extends StatefulWidget {
  @override
  _StudentDetailScreenState createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get student data from the arguments
    final student = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {
      'id': '001',
      'name': 'John Smith',
      'grade': '10th',
      'major': 'Science',
      'gpa': 3.8,
      'avatar': 'JS',
      'email': 'john.smith@example.com',
      'phone': '(555) 123-4567',
      'address': '123 Main St, Anytown, USA',
      'enrollmentDate': 'September 1, 2023',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit screen (not implemented yet)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit functionality coming soon!'),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Student'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'INFO'),
            Tab(text: 'GRADES'),
            Tab(text: 'ATTENDANCE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // INFO TAB
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student header info
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue,
                        child: Text(
                          student['avatar'],
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        student['name'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${student['id']}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text('${student['grade']} Grade'),
                        backgroundColor: Colors.blue.shade100,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Student details
                const Text(
                  'Academic Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _buildInfoRow('Major', student['major']),
                _buildInfoRow('GPA', student['gpa'].toString()),
                _buildInfoRow('Enrollment Date', student['enrollmentDate'] ?? 'September 1, 2023'),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _buildInfoRow('Email', student['email'] ?? 'john.smith@example.com', 
                  icon: Icons.email),
                _buildInfoRow('Phone', student['phone'] ?? '(555) 123-4567', 
                  icon: Icons.phone),
                _buildInfoRow('Address', student['address'] ?? '123 Main St, Anytown, USA', 
                  icon: Icons.home),
                
                const SizedBox(height: 24),
                
                // Emergency contact (placeholder)
                const Text(
                  'Emergency Contact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _buildInfoRow('Name', 'Sarah Smith', icon: Icons.person),
                _buildInfoRow('Relationship', 'Parent', icon: Icons.family_restroom),
                _buildInfoRow('Phone', '(555) 987-6543', icon: Icons.phone),
              ],
            ),
          ),
          
          // GRADES TAB
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Semester',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildGradeItem('Mathematics', 'A', 95),
                      _buildGradeItem('Science', 'A-', 92),
                      _buildGradeItem('History', 'B+', 88),
                      _buildGradeItem('English', 'A', 96),
                      _buildGradeItem('Physical Education', 'A', 98),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Previous Semester',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildGradeItem('Mathematics', 'B+', 89),
                      _buildGradeItem('Science', 'A', 94),
                      _buildGradeItem('History', 'A-', 91),
                      _buildGradeItem('English', 'B', 85),
                      _buildGradeItem('Physical Education', 'A', 97),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // ATTENDANCE TAB
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Attendance summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAttendanceStats('Present', '92%', Colors.green),
                          _buildAttendanceStats('Absent', '5%', Colors.red),
                          _buildAttendanceStats('Late', '3%', Colors.amber),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Attendance log
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance Log',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAttendanceLog('April 22, 2025', 'Present', Colors.green),
                      _buildAttendanceLog('April 21, 2025', 'Present', Colors.green),
                      _buildAttendanceLog('April 20, 2025', 'Late', Colors.amber),
                      _buildAttendanceLog('April 19, 2025', 'Present', Colors.green),
                      _buildAttendanceLog('April 18, 2025', 'Absent', Colors.red),
                      _buildAttendanceLog('April 17, 2025', 'Present', Colors.green),
                      _buildAttendanceLog('April 16, 2025', 'Present', Colors.green),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeItem(String subject, String grade, int percentage) {
    Color gradeColor;
    switch (grade[0]) {
      case 'A':
        gradeColor = Colors.green;
        break;
      case 'B':
        gradeColor = Colors.blue;
        break;
      case 'C':
        gradeColor = Colors.amber;
        break;
      default:
        gradeColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              subject,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          CircleAvatar(
            radius: 12,
            backgroundColor: gradeColor,
            child: Text(
              grade[0],
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            grade,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: gradeColor,
            ),
          ),
          const SizedBox(width: 8),
          Text('($percentage%)'),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats(String label, String percentage, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            percentage,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _buildAttendanceLog(String date, String status, Color color) {
    IconData icon;
    switch (status) {
      case 'Present':
        icon = Icons.check_circle;
        break;
      case 'Absent':
        icon = Icons.cancel;
        break;
      case 'Late':
        icon = Icons.access_time;
        break;
      default:
        icon = Icons.help;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(date),
          ),
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text(
          'Are you sure you want to delete this student? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student deleted successfully!'),
                ),
              );
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}