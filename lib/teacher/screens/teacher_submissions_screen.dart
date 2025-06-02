// submissions_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SubmissionsScreen extends StatefulWidget {
  @override
  _SubmissionsScreenState createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Submissions'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('submissions')
            .where('teacherId', isEqualTo: user?.uid)
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
                  Icon(Icons.folder_shared, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No submissions yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: submission['graded'] == true ? Colors.green : Colors.orange,
                    child: Icon(
                      submission['graded'] == true ? Icons.check : Icons.pending,
                      color: Colors.white,
                    ),
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
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (submission['content'] != null) ...[
                            Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text(submission['content']),
                            SizedBox(height: 16),
                          ],
                          if (submission['fileUrl'] != null) ...[
                            Text('Attachment:', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            InkWell(
                              onTap: () => _downloadFile(submission['fileUrl']),
                              child: Row(
                                children: [
                                  Icon(Icons.file_download, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    submission['fileName'] ?? 'Download File',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _gradeSubmission(submissions[index].id, submission),
                                icon: Icon(Icons.grade),
                                label: Text('Grade'),
                              ),
                              if (submission['graded'] == true)
                                ElevatedButton.icon(
                                  onPressed: () => _viewGrade(submission),
                                  icon: Icon(Icons.visibility),
                                  label: Text('View Grade'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _downloadFile(String fileUrl) async {
    if (await canLaunch(fileUrl)) {
      await launch(fileUrl);
    }
  }

  void _gradeSubmission(String submissionId, Map<String, dynamic> submission) {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeController,
              decoration: InputDecoration(labelText: 'Grade (0-100)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: InputDecoration(labelText: 'Feedback'),
              maxLines: 3,
            ),
          ],
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
              }
            },
            child: Text('Save Grade'),
          ),
        ],
      ),
    );
  }

  void _viewGrade(Map<String, dynamic> submission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grade: ${submission['grade']}/100'),
            SizedBox(height: 16),
            if (submission['feedback'] != null && submission['feedback'].isNotEmpty) ...[
              Text('Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(submission['feedback']),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}