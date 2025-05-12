import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sisapp/student/course_detail_screen.dart';

class HomeTab extends StatefulWidget {
  final Function(int)? onTabChange;

  const HomeTab({Key? key, this.onTabChange}) : super(key: key);

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(child: Text('User data not found'));
          }
          
          Map<String, dynamic> userData = 
              userSnapshot.data!.data() as Map<String, dynamic>;
          String userName = userData['name'] ?? 'Student';
          List<dynamic> enrolledCourseIds = userData['enrolledCourses'] ?? [];
          
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  Text(
                    'Upcoming Deadlines',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Upcoming Assignments Section
                  enrolledCourseIds.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No enrolled courses yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                        )
                      : FutureBuilder<List<Map<String, dynamic>>>(
                          future: _getUpcomingAssignments(enrolledCourseIds),
                          builder: (context, assignmentSnapshot) {
                            if (assignmentSnapshot.connectionState == 
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            
                            List<Map<String, dynamic>> assignments = 
                                assignmentSnapshot.data ?? [];
                                
                            if (assignments.isEmpty) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      'No upcoming assignments',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: assignments.length > 3 ? 3 : assignments.length,
                              itemBuilder: (context, index) {
                                final assignment = assignments[index];
                                final dueDate = assignment['dueDate'] as Timestamp;
                                final now = DateTime.now();
                                final difference = dueDate.toDate().difference(now);
                                
                                String timeLeft;
                                Color timeColor;
                                
                                if (difference.inDays > 0) {
                                  timeLeft = '${difference.inDays} days left';
                                  timeColor = difference.inDays < 3 ? Colors.orange : Colors.green;
                                } else if (difference.inHours > 0) {
                                  timeLeft = '${difference.inHours} hours left';
                                  timeColor = Colors.orange;
                                } else if (difference.inMinutes > 0) {
                                  timeLeft = '${difference.inMinutes} minutes left';
                                  timeColor = Colors.red;
                                } else {
                                  timeLeft = 'Due now';
                                  timeColor = Colors.red;
                                }
                                
                                return Card(
                                  elevation: 2,
                                  margin: EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.assignment,
                                      color: Colors.blue,
                                      size: 28,
                                    ),
                                    title: Text(assignment['title']),
                                    subtitle: Text(assignment['courseName']),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatDate(dueDate.toDate()),
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          timeLeft,
                                          style: TextStyle(
                                            color: timeColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      // Navigate to assignment details
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CourseDetailScreen(
                                            courseId: assignment['courseId'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                  
                  SizedBox(height: 24),
                  Text(
                    'Recent Announcements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Recent Announcements Section
                  enrolledCourseIds.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No enrolled courses yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                        )
                      : FutureBuilder<List<Map<String, dynamic>>>(
                          future: _getRecentAnnouncements(enrolledCourseIds),
                          builder: (context, announcementSnapshot) {
                            if (announcementSnapshot.connectionState == 
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            
                            List<Map<String, dynamic>> announcements = 
                                announcementSnapshot.data ?? [];
                                
                            if (announcements.isEmpty) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      'No recent announcements',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: announcements.length > 3 ? 3 : announcements.length,
                              itemBuilder: (context, index) {
                                final announcement = announcements[index];
                                final createdAt = announcement['createdAt'] as Timestamp;
                                
                                return Card(
                                  elevation: 2,
                                  margin: EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.announcement,
                                      color: Colors.blue,
                                      size: 28,
                                    ),
                                    title: Text(
                                      announcement['courseName'],
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          announcement['content'].length > 80
                                              ? '${announcement['content'].substring(0, 80)}...'
                                              : announcement['content'],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Posted: ${_formatDate(createdAt.toDate())}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    onTap: () {
                                      // Navigate to course details
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CourseDetailScreen(
                                            courseId: announcement['courseId'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                  
                  SizedBox(height: 24),
                  Text(
                    'My Courses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Courses Preview Section
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('courses')
                        .where('studentIds', arrayContains: _auth.currentUser?.uid)
                        .limit(3)
                        .snapshots(),
                    builder: (context, courseSnapshot) {
                      if (courseSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      
                      if (!courseSnapshot.hasData || courseSnapshot.data!.docs.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Text(
                                    'No enrolled courses yet',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Navigate to course enrollment
                                    },
                                    child: Text('Find Courses'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: courseSnapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot doc = courseSnapshot.data!.docs[index];
                          Map<String, dynamic> course = doc.data() as Map<String, dynamic>;
                          
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getColorFromHex(course['bannerColor'] ?? '#1565C0'),
                                child: Text(
                                  course['name'][0].toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(course['name']),
                              subtitle: Text(course['teacherName']),
                              trailing: Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CourseDetailScreen(
                                      courseId: doc.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  
                  SizedBox(height: 8),
                  if (enrolledCourseIds.isNotEmpty && enrolledCourseIds.length > 3)
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Use the callback to switch to Courses tab
                          if (widget.onTabChange != null) {
                            widget.onTabChange!(2); // Index of Courses tab
                          }
                        },
                        child: Text('View All Courses'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Future<List<Map<String, dynamic>>> _getUpcomingAssignments(List<dynamic> courseIds) async {
    List<Map<String, dynamic>> allAssignments = [];
    
    for (String courseId in courseIds) {
      try {
        // Get course name first
        DocumentSnapshot courseDoc = await _firestore
            .collection('courses')
            .doc(courseId)
            .get();
            
        if (!courseDoc.exists) continue;
        Map<String, dynamic> courseData = courseDoc.data() as Map<String, dynamic>;
        String courseName = courseData['name'];
        
        // Get assignments for this course
        QuerySnapshot assignmentQuery = await _firestore
            .collection('courses')
            .doc(courseId)
            .collection('assignments')
            .where('dueDate', isGreaterThan: Timestamp.now())
            .orderBy('dueDate')
            .get();
            
        for (var doc in assignmentQuery.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          allAssignments.add({
            ...data,
            'id': doc.id,
            'courseId': courseId,
            'courseName': courseName,
          });
        }
      } catch (e) {
        print('Error fetching assignments for course $courseId: $e');
      }
    }
    
    // Sort by due date (ascending)
    allAssignments.sort((a, b) => 
        (a['dueDate'] as Timestamp).compareTo(b['dueDate'] as Timestamp));
        
    return allAssignments;
  }
  
  Future<List<Map<String, dynamic>>> _getRecentAnnouncements(List<dynamic> courseIds) async {
    List<Map<String, dynamic>> allAnnouncements = [];
    
    for (String courseId in courseIds) {
      try {
        // Get course name first
        DocumentSnapshot courseDoc = await _firestore
            .collection('courses')
            .doc(courseId)
            .get();
            
        if (!courseDoc.exists) continue;
        Map<String, dynamic> courseData = courseDoc.data() as Map<String, dynamic>;
        String courseName = courseData['name'];
        
        // Get announcements for this course
        QuerySnapshot announcementQuery = await _firestore
            .collection('courses')
            .doc(courseId)
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .limit(3)
            .get();
            
        for (var doc in announcementQuery.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          allAnnouncements.add({
            ...data,
            'id': doc.id,
            'courseId': courseId,
            'courseName': courseName,
          });
        }
      } catch (e) {
        print('Error fetching announcements for course $courseId: $e');
      }
    }
    
    // Sort by creation date (descending)
    allAnnouncements.sort((a, b) => 
        (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));
        
    return allAnnouncements;
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}