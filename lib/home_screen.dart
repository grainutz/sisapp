// screens/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeTab(),
    SearchTab(),
    CoursesTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Different Tabs (Simple for now)

class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.school, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Welcome to the Student Portal!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Center(
        child: Text(
          'Search for courses, announcements, or information.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class CoursesTab extends StatefulWidget {
  @override
  _CoursesTabState createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab>{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
              // Implement search functionality
            },
          ),
        ],
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('courses')
            .where('studentIds', arrayContains: _auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No courses found'));
          }
          
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              Map<String, dynamic> course = doc.data() as Map<String, dynamic>;
              
              return CourseCard(
                courseId: doc.id,
                courseName: course['name'],
                teacherName: course['teacherName'],
                bannerColor: _getColorFromHex(course['bannerColor'] ?? '#1565C0'),
                bannerUrl: course['bannerUrl'],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Join a new course
        },
      ),
    );
  }
  
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}

class CourseCard extends StatelessWidget{
  final String courseId;
  final String courseName;
  final String teacherName;
  final Color bannerColor;
  final String? bannerUrl;

  const CourseCard({
    required this.courseId,
    required this.courseName,
    required this.teacherName,
    required this.bannerColor,
    this.bannerUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(courseId: courseId),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: bannerUrl == null ? bannerColor : null,
                image: bannerUrl != null
                    ? DecorationImage(
                        image: NetworkImage(bannerUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    courseName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacherName,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.folder_outlined),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.people_outline),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({required this.courseId});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? courseData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
  }

  Future<void> _loadCourseDetails() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('courses')
          .doc(widget.courseId)
          .get();
      
      if (doc.exists) {
        setState(() {
          courseData = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading course details: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (courseData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Course Not Found')),
        body: Center(child: Text('The requested course was not found')),
      );
    }

    final Color bannerColor = _getColorFromHex(courseData!['bannerColor'] ?? '#1565C0');

    return Scaffold(
      appBar: AppBar(
        title: Text(courseData!['name']),
        backgroundColor: bannerColor,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              color: bannerColor,
              child: TabBar(
                tabs: [
                  Tab(text: 'Stream'),
                  Tab(text: 'Classwork'),
                  Tab(text: 'People'),
                ],
                indicatorColor: Colors.white,
                labelColor: Colors.white,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildStreamTab(),
                  _buildClassworkTab(),
                  _buildPeopleTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Add new announcement or assignment
        },
        backgroundColor: bannerColor,
      ),
    );
  }

  Widget _buildStreamTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('courses')
          .doc(widget.courseId)
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No announcements yet'));
        }
        
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            Map<String, dynamic> announcement = doc.data() as Map<String, dynamic>;
            
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(announcement['authorName'][0]),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement['authorName'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatDate(announcement['createdAt'].toDate()),
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(announcement['content']),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClassworkTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('courses')
          .doc(widget.courseId)
          .collection('assignments')
          .orderBy('dueDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No assignments yet'));
        }
        
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            Map<String, dynamic> assignment = doc.data() as Map<String, dynamic>;
            
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: Icon(Icons.assignment),
                title: Text(assignment['title']),
                subtitle: Text('Due: ${_formatDate(assignment['dueDate'].toDate())}'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to assignment details
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPeopleTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Teachers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: CircleAvatar(
            child: Text(courseData!['teacherName'][0]),
          ),
          title: Text(courseData!['teacherName']),
        ),
        Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Students',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: FutureBuilder<QuerySnapshot>(
            future: _firestore.collection('users').where('id', whereIn: courseData!['studentIds']).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No students enrolled'));
              }
              
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot doc = snapshot.data!.docs[index];
                  Map<String, dynamic> student = doc.data() as Map<String, dynamic>;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(student['name'][0]),
                    ),
                    title: Text(student['name']),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
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

class ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Text(
          'Manage your student profile here.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
