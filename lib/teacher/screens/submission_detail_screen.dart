// submission_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SubmissionDetailScreen extends StatefulWidget {
  final String submissionId;
  final Map<String, dynamic> submission;

  SubmissionDetailScreen({required this.submissionId, required this.submission});

  @override
  _SubmissionDetailScreenState createState() => _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends State<SubmissionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final submission = widget.submission;
    final submittedAt = (submission['submittedAt'] as Timestamp?)?.toDate();

    return Scaffold(
      appBar: AppBar(
        title: Text('Submission Details'),
        actions: [
          if (!submission['graded'])
            IconButton(
              icon: Icon(Icons.grade),
              onPressed: () => _gradeSubmission(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assignment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(submission['assignmentTitle'] ?? 'Unknown Assignment'),
                    SizedBox(height: 16),
                    Text('Student', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(submission['studentName'] ?? 'Unknown Student'),
                    SizedBox(height: 16),
                    Text('Submitted At', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(submittedAt != null 
                      ? "${submittedAt.day}/${submittedAt.month}/${submittedAt.year} ${submittedAt.hour}:${submittedAt.minute.toString().padLeft(2, '0')}"
                      : 'Unknown'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            if (submission['content'] != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Submission Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Text(submission['content']),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            if (submission['fileUrl'] != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Attached File', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      InkWell(
                        onTap: () => _downloadFile(submission['fileUrl']),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.file_download, color: Colors.blue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  submission['fileName'] ?? 'Download File',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            if (submission['graded'] == true) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Grade', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getGradeColor(submission['grade']),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${submission['grade']}/100',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (submission['feedback'] != null && submission['feedback'].isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text('Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text(submission['feedback']),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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

  void _downloadFile(String fileUrl) async {
  final Uri url = Uri.parse(fileUrl);
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  }
}

  void _gradeSubmission() {
    final gradeController = TextEditingController();
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    .doc(widget.submissionId)
                    .update({
                  'grade': grade,
                  'feedback': feedbackController.text,
                  'graded': true,
                  'gradedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                setState(() {
                  widget.submission['grade'] = grade;
                  widget.submission['feedback'] = feedbackController.text;
                  widget.submission['graded'] = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Grade saved successfully!')),
                );
              }
            },
            child: Text('Save Grade'),
          ),
        ],
      ),
    );
  }
}