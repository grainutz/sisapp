// grading_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'submission_detail_screen.dart';

class GradingScreen extends StatefulWidget {
  @override
  _GradingScreenState createState() => _GradingScreenState();
}

class _GradingScreenState extends State<GradingScreen> with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grading'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Graded', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingGrades(),
          _buildGradedSubmissions(),
        ],
      ),
    );
  }

  Widget _buildPendingGrades() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('submissions')
          .where('teacherId', isEqualTo: user?.uid)
          .where('graded', isEqualTo: false)
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final submissions = snapshot.data?.docs ?? [];

        if (submissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('All caught up!', style: TextStyle(fontSize: 18, color: Colors.grey)),
                Text('No pending submissions to grade', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final submission = submissions[index].data() as Map<String, dynamic>;
            final submittedAt = (submission['submittedAt'] as Timestamp?)?.toDate();
            
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.pending, color: Colors.white),
                ),
                title: Text(submission['assignmentTitle'] ?? 'Unknown Assignment'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student: ${submission['studentName'] ?? 'Unknown'}'),
                    Text(
                      'Submitted: ${submittedAt != null ? "${submittedAt.day}/${submittedAt.month}/${submittedAt.year}" : "Unknown"}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => _quickGrade(submissions[index].id, submission),
                  child: Text('Grade'),
                ),
                onTap: () => _viewSubmissionDetails(submissions[index].id, submission),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGradedSubmissions() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('submissions')
          .where('teacherId', isEqualTo: user?.uid)
          .where('graded', isEqualTo: true)
          .orderBy('gradedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final submissions = snapshot.data?.docs ?? [];

        if (submissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grade, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No graded submissions yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final submission = submissions[index].data() as Map<String, dynamic>;
            final gradedAt = (submission['gradedAt'] as Timestamp?)?.toDate();
            final grade = submission['grade'];
            
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getGradeColor(grade),
                  child: Text(
                    grade.toString(),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(submission['assignmentTitle'] ?? 'Unknown Assignment'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student: ${submission['studentName'] ?? 'Unknown'}'),
                    Text(
                      'Graded: ${gradedAt != null ? "${gradedAt.day}/${gradedAt.month}/${gradedAt.year}" : "Unknown"}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(child: Text('Edit Grade'), value: 'edit'),
                    PopupMenuItem(child: Text('View Details'), value: 'view'),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _quickGrade(submissions[index].id, submission);
                    } else if (value == 'view') {
                      _viewSubmissionDetails(submissions[index].id, submission);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getGradeColor(int? grade) {
    if (grade == null) return Colors.grey;
    if (grade >= 90) return Colors.green;
    if (grade >= 80) return Colors.lightGreen;
    if (grade >= 70) return Colors.orange;
    if (grade >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  void _quickGrade(String submissionId, Map<String, dynamic> submission) {
    final gradeController = TextEditingController(
      text: submission['grade']?.toString() ?? '',
    );
    final feedbackController = TextEditingController(
      text: submission['feedback'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade Submission'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Student: ${submission['studentName'] ?? 'Unknown'}'),
              Text('Assignment: ${submission['assignmentTitle'] ?? 'Unknown'}'),
              SizedBox(height: 16),
              TextField(
                controller: gradeController,
                decoration: InputDecoration(
                  labelText: 'Grade (0-100)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                decoration: InputDecoration(
                  labelText: 'Feedback (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
              final grade = int.tryParse(gradeController.text);
              if (grade != null && grade >= 0 && grade <= 100) {
                await FirebaseFirestore.instance
                    .collection('submissions')
                    .doc(submissionId)
                    .update({
                  'grade': grade,
                  'feedback': feedbackController.text,
                  'graded': true,
                  'gradedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Grade saved successfully!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a valid grade (0-100)')),
                );
              }
            },
            child: Text('Save Grade'),
          ),
        ],
      ),
    );
  }

  void _viewSubmissionDetails(String submissionId, Map<String, dynamic> submission) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmissionDetailScreen(
          submissionId: submissionId,
          submission: submission,
        ),
      ),
    );
  }
}