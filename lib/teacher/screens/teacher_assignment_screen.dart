// teacher_assignments_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  @override
  _TeacherAssignmentsScreenState createState() => _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assignments'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddAssignmentDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .where('teacherId', isEqualTo: user?.uid)
            .orderBy('dueDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final assignments = snapshot.data?.docs ?? [];

          if (assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No assignments yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddAssignmentDialog(),
                    child: Text('Create Assignment'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index].data() as Map<String, dynamic>;
              final dueDate = (assignment['dueDate'] as Timestamp?)?.toDate();
              
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.assignment, color: Colors.white),
                  ),
                  title: Text(assignment['title'] ?? 'Untitled Assignment'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(assignment['description'] ?? 'No description'),
                      SizedBox(height: 4),
                      Text(
                        'Due: ${dueDate != null ? "${dueDate.day}/${dueDate.month}/${dueDate.year}" : "No due date"}',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(child: Text('View Submissions'), value: 'submissions'),
                      PopupMenuItem(child: Text('Edit'), value: 'edit'),
                      PopupMenuItem(child: Text('Delete'), value: 'delete'),
                    ],
                    onSelected: (value) {
                      if (value == 'submissions') {
                        Navigator.pushNamed(
                          context,
                          '/assignment-submissions',
                          arguments: {'assignmentId': assignments[index].id},
                        );
                      } else if (value == 'edit') {
                        _showEditAssignmentDialog(assignments[index].id, assignment);
                      } else if (value == 'delete') {
                        _deleteAssignment(assignments[index].id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddAssignmentDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Create Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Assignment Title'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('Due Date: '),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: Text(selectedDate != null 
                        ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                        : "Select Date"),
                    ),
                  ],
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
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('assignments').add({
                    'title': titleController.text,
                    'description': descController.text,
                    'dueDate': selectedDate != null ? Timestamp.fromDate(selectedDate!) : null,
                    'teacherId': user?.uid,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAssignmentDialog(String assignmentId, Map<String, dynamic> assignment) {
    final titleController = TextEditingController(text: assignment['title']);
    final descController = TextEditingController(text: assignment['description']);
    DateTime? selectedDate = (assignment['dueDate'] as Timestamp?)?.toDate();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Assignment Title'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('Due Date: '),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: Text(selectedDate != null 
                        ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                        : "Select Date"),
                    ),
                  ],
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
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('assignments')
                      .doc(assignmentId)
                      .update({
                    'title': titleController.text,
                    'description': descController.text,
                    'dueDate': selectedDate != null ? Timestamp.fromDate(selectedDate!) : null,
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAssignment(String assignmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Assignment'),
        content: Text('Are you sure you want to delete this assignment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('assignments')
                  .doc(assignmentId)
                  .delete();
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}