// course_assignments_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseAssignmentsScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const CourseAssignmentsScreen({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<CourseAssignmentsScreen> createState() => _CourseAssignmentsScreenState();
}

class _CourseAssignmentsScreenState extends State<CourseAssignmentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assignments - ${widget.courseName}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAssignmentDialog(),
        backgroundColor: Colors.green,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('courses')
            .doc(widget.courseId)
            .collection('assignments')
            .orderBy('dueDate', descending: false)
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
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No assignments created yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateAssignmentDialog(),
                    icon: Icon(Icons.add),
                    label: Text('Create Assignment'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignmentDoc = assignments[index];
              final assignment = assignmentDoc.data() as Map<String, dynamic>;
              
              return _buildAssignmentCard(assignmentDoc.id, assignment);
            },
          );
        },
      ),
    );
  }

  Widget _buildAssignmentCard(String assignmentId, Map<String, dynamic> assignment) {
    final dueDate = assignment['dueDate'] as Timestamp?;
    final isOverdue = dueDate != null && dueDate.toDate().isBefore(DateTime.now());
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assignment['title'] ?? 'Untitled Assignment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditAssignmentDialog(assignmentId, assignment);
                        break;
                      case 'submissions':
                        _viewSubmissions(assignmentId, assignment);
                        break;
                      case 'delete':
                        _showDeleteAssignmentDialog(assignmentId, assignment);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'submissions', child: Text('View Submissions')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            
            if (assignment['description'] != null) ...[
              SizedBox(height: 8),
              Text(
                assignment['description'],
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  'Points: ${assignment['maxPoints'] ?? 'N/A'}',
                  Colors.blue,
                ),
                SizedBox(width: 8),
                _buildInfoChip(
                  isOverdue ? 'OVERDUE' : 'Active',
                  isOverdue ? Colors.red : Colors.green,
                ),
              ],
            ),
            
            if (dueDate != null) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: isOverdue ? Colors.red : Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Due: ${_formatDateTime(dueDate)}',
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
            
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewSubmissions(assignmentId, assignment),
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text('View Submissions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditAssignmentDialog(assignmentId, assignment),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  String _formatDateTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateAssignmentDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(Duration(days: 7));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Assignment'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Assignment Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max Points',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text('Due Date'),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at ${selectedDate.hour}:${selectedDate.minute.toString().padLeft(2, '0')}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createAssignment(
              titleController.text,
              descriptionController.text,
              pointsController.text,
              selectedDate,
            ),
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditAssignmentDialog(String assignmentId, Map<String, dynamic> assignment) {
    final titleController = TextEditingController(text: assignment['title']);
    final descriptionController = TextEditingController(text: assignment['description']);
    final pointsController = TextEditingController(text: assignment['maxPoints']?.toString());
    DateTime selectedDate = (assignment['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Assignment'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Assignment Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max Points',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text('Due Date'),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at ${selectedDate.hour}:${selectedDate.minute.toString().padLeft(2, '0')}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateAssignment(
              assignmentId,
              titleController.text,
              descriptionController.text,
              pointsController.text,
              selectedDate,
            ),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAssignmentDialog(String assignmentId, Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Assignment'),
        content: Text('Are you sure you want to delete "${assignment['title']}"? This will also delete all submissions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteAssignment(assignmentId),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createAssignment(String title, String description, String points, DateTime dueDate) async {
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment title is required')),
      );
      return;
    }

    try {
      await _firestore
          .collection('courses')
          .doc(widget.courseId)
          .collection('assignments')
          .add({
        'title': title,
        'description': description,
        'maxPoints': int.tryParse(points) ?? 100,
        'dueDate': Timestamp.fromDate(dueDate),
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating assignment: $e')),
      );
    }
  }

  Future<void> _updateAssignment(String assignmentId, String title, String description, String points, DateTime dueDate) async {
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment title is required')),
      );
      return;
    }

    try {
      await _firestore
          .collection('courses')
          .doc(widget.courseId)
          .collection('assignments')
          .doc(assignmentId)
          .update({
        'title': title,
        'description': description,
        'maxPoints': int.tryParse(points) ?? 100,
        'dueDate': Timestamp.fromDate(dueDate),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating assignment: $e')),
      );
    }
  }

  Future<void> _deleteAssignment(String assignmentId) async {
    try {
      await _firestore
          .collection('courses')
          .doc(widget.courseId)
          .collection('assignments')
          .doc(assignmentId)
          .delete();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting assignment: $e')),
      );
    }
  }

  void _viewSubmissions(String assignmentId, Map<String, dynamic> assignment) {
    Navigator.pushNamed(context, '/assignment-submissions', arguments: {
      'courseId': widget.courseId,
      'assignmentId': assignmentId,
      'assignmentTitle': assignment['title'],
    });
  }
}