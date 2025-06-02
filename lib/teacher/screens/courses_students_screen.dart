// course_students_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseStudentsScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const CourseStudentsScreen({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<CourseStudentsScreen> createState() => _CourseStudentsScreenState();
}

class _CourseStudentsScreenState extends State<CourseStudentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students - ${widget.courseName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () => _showAddStudentDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('courses')
            .doc(widget.courseId)
            .collection('students')
            .orderBy('studentName')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data?.docs ?? [];

          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No students enrolled yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddStudentDialog(),
                    icon: Icon(Icons.person_add),
                    label: Text('Add Student'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final studentDoc = students[index];
              final student = studentDoc.data() as Map<String, dynamic>;
              
              return _buildStudentCard(studentDoc.id, student);
            },
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(String studentId, Map<String, dynamic> student) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            student['studentName']?.substring(0, 1).toUpperCase() ?? 'S',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(student['studentName'] ?? 'Unknown Student'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student['studentEmail'] ?? 'No email'),
            SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(student['status'] ?? 'active'),
                SizedBox(width: 8),
                Text(
                  'Enrolled: ${_formatDate(student['enrolledAt'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view_grades':
                _viewStudentGrades(studentId, student);
                break;
              case 'change_status':
                _showChangeStatusDialog(studentId, student);
                break;
              case 'remove':
                _showRemoveStudentDialog(studentId, student);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'view_grades', child: Text('View Grades')),
            PopupMenuItem(value: 'change_status', child: Text('Change Status')),
            PopupMenuItem(value: 'remove', child: Text('Remove Student')),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'dropped':
        color = Colors.red;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Unknown';
  }

  void _showAddStudentDialog() async {
  final studentsQuery = await _firestore
      .collection('users')
      .where('role', isEqualTo: 'student')
      .get();

  List<QueryDocumentSnapshot> studentDocs = studentsQuery.docs;
  String? selectedStudentId;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Add Student to Course'),
        content: DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Select Student',
            border: OutlineInputBorder(),
            
          ),
          items: studentDocs.map((doc) {
            final user = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: Text('${user['name']} (${user['email']})'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedStudentId = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: selectedStudentId == null
                ? null
                : () async {
                    final selectedDoc = studentDocs.firstWhere(
                        (doc) => doc.id == selectedStudentId);
                    final user = selectedDoc.data() as Map<String, dynamic>;

                    await _firestore
                        .collection('courses')
                        .doc(widget.courseId)
                        .collection('students')
                        .doc(selectedStudentId) // use UID as doc ID
                        .set({
                      'studentId': selectedStudentId,
                      'studentName': user['name'],
                      'studentEmail': user['email'],
                      'status': 'active',
                      'enrolledAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Student added successfully')),
                    );
                  },
            child: Text('Add Student'),
          ),
        ],
      ),
    ),
  );
}


  void _showChangeStatusDialog(String studentId, Map<String, dynamic> student) {
    String selectedStatus = student['status'] ?? 'active';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Status - ${student['studentName']}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: Text('Active'),
                value: 'active',
                groupValue: selectedStatus,
                onChanged: (value) => setState(() => selectedStatus = value!),
              ),
              RadioListTile(
                title: Text('Dropped'),
                value: 'dropped',
                groupValue: selectedStatus,
                onChanged: (value) => setState(() => selectedStatus = value!),
              ),
              RadioListTile(
                title: Text('Completed'),
                value: 'completed',
                groupValue: selectedStatus,
                onChanged: (value) => setState(() => selectedStatus = value!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateStudentStatus(studentId, selectedStatus),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showRemoveStudentDialog(String studentId, Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Student'),
        content: Text('Are you sure you want to remove ${student['studentName']} from this course?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _removeStudent(studentId),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addStudent(String name, String email) async {
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      await _firestore
          .collection('courses')
          .doc(widget.courseId)
          .collection('students')
          .add({
        'studentName': name,
        'studentEmail': email,
        'status': 'active',
        'enrolledAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding student: $e')),
      );
    }
  }

  Future<void> _updateStudentStatus(String studentId, String status) async {
    try {
      await _firestore
          .collection('courses')
          .doc(widget.courseId)
          .collection('students')
          .doc(studentId)
          .update({'status': status});

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student status updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _removeStudent(String studentId) async {
    try {
      await _firestore
          .collection('courses')
          .doc(widget.courseId)
          .collection('students')
          .doc(studentId)
          .delete();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing student: $e')),
      );
    }
  }

  void _viewStudentGrades(String studentId, Map<String, dynamic> student) {
    // Navigate to student grades screen
    Navigator.pushNamed(context, '/student-grades', arguments: {
      'courseId': widget.courseId,
      'studentId': studentId,
      'studentName': student['studentName'],
    });
  }
}