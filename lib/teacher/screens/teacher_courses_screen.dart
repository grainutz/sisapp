// teacher_courses_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherCoursesScreen extends StatefulWidget {
  @override
  _TeacherCoursesScreenState createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Courses'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('assignedTeacher.uid', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data?.docs ?? [];

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No courses assigned yet', 
                    style: TextStyle(fontSize: 18, color: Colors.grey)
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Contact your administrator to get courses assigned',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final courseDoc = courses[index];
              final course = courseDoc.data() as Map<String, dynamic>;
              
              return _buildCourseCard(courseDoc.id, course);
            },
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(String courseId, Map<String, dynamic> course) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: InkWell(
        onTap: () => _navigateToCourseManagement(courseId, course),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
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
                          course['courseName'] ?? 'Untitled Course',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Code: ${course['courseCode'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              
              if (course['description'] != null && course['description'].isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  course['description'],
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip('Credits: ${course['credits'] ?? 'N/A'}', Colors.blue),
                  SizedBox(width: 8),
                  _buildInfoChip('Active', Colors.green),
                ],
              ),
              
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.touch_app, size: 16, color: Colors.purple),
                  SizedBox(width: 4),
                  Text(
                    'Tap to manage course',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  void _navigateToCourseManagement(String courseId, Map<String, dynamic> course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseManagementScreen(
          courseId: courseId,
          courseData: course,
        ),
      ),
    );
  }
}

// New Course Management Screen - This is where all the course management happens
class CourseManagementScreen extends StatelessWidget {
  final String courseId;
  final Map<String, dynamic> courseData;

  const CourseManagementScreen({
    Key? key,
    required this.courseId,
    required this.courseData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(courseData['courseName'] ?? 'Course Management'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseData['courseName'] ?? 'Course Name',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Code: ${courseData['courseCode'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (courseData['description'] != null) ...[
                      SizedBox(height: 8),
                      Text(courseData['description']),
                    ],
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            Text(
              'Course Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // Management Options Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildManagementCard(
                    context,
                    'Students',
                    Icons.people,
                    Colors.blue,
                    'View and manage enrolled students',
                    () => _navigateToStudents(context),
                  ),
                  _buildManagementCard(
                    context,
                    'Assignments',
                    Icons.assignment,
                    Colors.green,
                    'Create and manage assignments',
                    () => _navigateToAssignments(context),
                  ),
                  _buildManagementCard(
                    context,
                    'Announcements',
                    Icons.announcement,
                    Colors.orange,
                    'Post course announcements',
                    () => _navigateToAnnouncements(context),
                  ),
                  _buildManagementCard(
                    context,
                    'Grades',
                    Icons.grade,
                    Colors.purple,
                    'View and manage student grades',
                    () => _navigateToGrades(context),
                  ),
                  _buildManagementCard(
                    context,
                    'Attendance',
                    Icons.check_circle,
                    Colors.teal,
                    'Track student attendance',
                    () => _navigateToAttendance(context),
                  ),
                  _buildManagementCard(
                    context,
                    'Materials',
                    Icons.folder,
                    Colors.brown,
                    'Upload course materials',
                    () => _navigateToMaterials(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToStudents(BuildContext context) {
    // Navigate to students screen with subcollection: courses/{courseId}/students
    Navigator.pushNamed(context, '/course-students', arguments: {
      'courseId': courseId,
      'courseName': courseData['courseName'],
    });
  }

  void _navigateToAssignments(BuildContext context) {
    // Navigate to assignments screen with subcollection: courses/{courseId}/assignments
    Navigator.pushNamed(context, '/course-assignments', arguments: {
      'courseId': courseId,
      'courseName': courseData['courseName'],
    });
  }

  void _navigateToAnnouncements(BuildContext context) {
    // Navigate to announcements screen with subcollection: courses/{courseId}/announcements
    Navigator.pushNamed(context, '/course-announcements', arguments: {
      'courseId': courseId,
      'courseName': courseData['courseName'],
    });
  }

  void _navigateToGrades(BuildContext context) {
    // Navigate to grades screen
    Navigator.pushNamed(context, '/course-grades', arguments: {
      'courseId': courseId,
      'courseName': courseData['courseName'],
    });
  }

  void _navigateToAttendance(BuildContext context) {
    // Navigate to attendance screen with subcollection: courses/{courseId}/attendance
    Navigator.pushNamed(context, '/course-attendance', arguments: {
      'courseId': courseId,
      'courseName': courseData['courseName'],
    });
  }

  void _navigateToMaterials(BuildContext context) {
    // Navigate to materials screen with subcollection: courses/{courseId}/materials
    Navigator.pushNamed(context, '/course-materials', arguments: {
      'courseId': courseId,
      'courseName': courseData['courseName'],
    });
  }
}