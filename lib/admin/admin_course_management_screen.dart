// admin_course_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCourseManagementScreen extends StatefulWidget {
  const AdminCourseManagementScreen({super.key});

  @override
  State<AdminCourseManagementScreen> createState() => _AdminCourseManagementScreenState();
}

class _AdminCourseManagementScreenState extends State<AdminCourseManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Management'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCourseDialog(),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('courses').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data?.docs ?? [];

          if (courses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No courses created yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final data = course.data() as Map<String, dynamic>;
              
              return _buildCourseCard(course.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(String courseId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['courseName'] ?? 'Untitled Course',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${data['courseCode'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditCourseDialog(courseId, data);
                        break;
                      case 'assign':
                        _showAssignTeacherDialog(courseId, data);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(courseId, data['courseName']);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Course')),
                    const PopupMenuItem(value: 'assign', child: Text('Assign Teacher')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete Course')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (data['description'] != null && data['description'].isNotEmpty) ...[
              Text(
                data['description'],
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
            ],
            
            Row(
              children: [
                _buildInfoChip('Credits: ${data['credits'] ?? 'N/A'}', Colors.blue),
                const SizedBox(width: 8),
                if (data['assignedTeacher'] != null)
                  _buildInfoChip('Teacher: ${data['assignedTeacher']['name']}', Colors.green)
                else
                  _buildInfoChip('No Teacher Assigned', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showAddCourseDialog() {
    final courseNameController = TextEditingController();
    final courseCodeController = TextEditingController();
    final descriptionController = TextEditingController();
    final creditsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: courseCodeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: creditsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Credits',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _addCourse(
              courseNameController.text,
              courseCodeController.text,
              creditsController.text,
              descriptionController.text,
            ),
            child: const Text('Add Course'),
          ),
        ],
      ),
    );
  }

  void _showEditCourseDialog(String courseId, Map<String, dynamic> data) {
    final courseNameController = TextEditingController(text: data['courseName']);
    final courseCodeController = TextEditingController(text: data['courseCode']);
    final descriptionController = TextEditingController(text: data['description'] ?? '');
    final creditsController = TextEditingController(text: data['credits']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: courseCodeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: creditsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Credits',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateCourse(
              courseId,
              courseNameController.text,
              courseCodeController.text,
              creditsController.text,
              descriptionController.text,
            ),
            child: const Text('Update Course'),
          ),
        ],
      ),
    );
  }

  void _showAssignTeacherDialog(String courseId, Map<String, dynamic> courseData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Teacher to ${courseData['courseName']}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .where('role', isEqualTo: 'teacher')
                .where('status', isEqualTo: 'approved')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final teachers = snapshot.data?.docs ?? [];

              if (teachers.isEmpty) {
                return const Center(child: Text('No approved teachers available'));
              }

              return ListView.builder(
                itemCount: teachers.length,
                itemBuilder: (context, index) {
                  final teacher = teachers[index];
                  final teacherData = teacher.data() as Map<String, dynamic>;
                  
                  return ListTile(
                    title: Text(teacherData['name'] ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teacherData['email'] ?? ''),
                        if (teacherData['department'] != null)
                          Text('Dept: ${teacherData['department']}'),
                      ],
                    ),
                    onTap: () => _assignTeacher(courseId, teacher.id, teacherData),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCourse(String name, String code, String credits, String description) async {
    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course name and code are required')),
      );
      return;
    }

    try {
      await _firestore.collection('courses').add({
        'courseName': name,
        'courseCode': code,
        'credits': int.tryParse(credits) ?? 0,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding course: $e')),
      );
    }
  }

  Future<void> _updateCourse(String courseId, String name, String code, String credits, String description) async {
    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course name and code are required')),
      );
      return;
    }

    try {
      await _firestore.collection('courses').doc(courseId).update({
        'courseName': name,
        'courseCode': code,
        'credits': int.tryParse(credits) ?? 0,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating course: $e')),
      );
    }
  }

  Future<void> _assignTeacher(String courseId, String teacherId, Map<String, dynamic> teacherData) async {
    try {
      await _firestore.collection('courses').doc(courseId).update({
        'assignedTeacher': {
          'uid': teacherId,
          'name': teacherData['name'],
          'email': teacherData['email'],
        },
        'assignedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher assigned successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning teacher: $e')),
      );
    }
  }

  void _showDeleteConfirmation(String courseId, String courseName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "$courseName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteCourse(courseId),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourse(String courseId) async {
    try {
      await _firestore.collection('courses').doc(courseId).delete();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting course: $e')),
      );
    }
  }
}