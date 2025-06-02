import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../couse_card.dart';

class CoursesTab extends StatefulWidget {
  @override
  _CoursesTabState createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> enrolledCourses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEnrolledCourses();
  }

  Future<void> fetchEnrolledCourses() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final allCourses = await _firestore.collection('courses').get();
    List<Map<String, dynamic>> tempCourses = [];

    for (var courseDoc in allCourses.docs) {
      final studentDoc = await _firestore
          .collection('courses')
          .doc(courseDoc.id)
          .collection('students')
          .doc(userId)
          .get();

      if (studentDoc.exists) {
        Map<String, dynamic> courseData = courseDoc.data();

        tempCourses.add({
          'courseId': courseDoc.id,
          'courseName': courseData['courseName'] ?? 'Unnamed Course',
          'teacherName': courseData['assignedTeacher']?['name'] ?? 'Unknown Teacher',
        });
      }
    }

    setState(() {
      enrolledCourses = tempCourses;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Courses'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Implement search
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : enrolledCourses.isEmpty
              ? Center(child: Text('No enrolled courses found'))
              : ListView.builder(
                  itemCount: enrolledCourses.length,
                  itemBuilder: (context, index) {
                    final course = enrolledCourses[index];
                    return CourseCard(
                      courseId: course['courseId'],
                      courseName: course['courseName'],
                      teacherName: course['teacherName'],
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Join course
        },
      ),
    );
  }

}
