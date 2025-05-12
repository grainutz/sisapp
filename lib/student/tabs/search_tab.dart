import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sisapp/student/course_detail_screen.dart';

class SearchTab extends StatefulWidget {
  @override
  _SearchTabState createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _searchQuery = '';
  bool _isSearching = false;
  String _selectedFilter = 'All';
  List<String> _filters = ['All', 'Courses', 'Announcements', 'Assignments', 'People'];
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              style: TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            )
          : Text('Search'),
        backgroundColor: Colors.blue[700],
        actions: [
          _isSearching
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: _clearSearch,
              )
            : IconButton(
                icon: Icon(Icons.search),
                onPressed: _startSearch,
              ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) => 
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      selectedColor: Colors.blue[100],
                      checkmarkColor: Colors.blue[800],
                    ),
                  )
                ).toList(),
              ),
            ),
          ),
          
          // Recent searches
          if (!_isSearching && _searchQuery.isEmpty)
            _buildRecentSearchesSection(),
            
          // Search results
          if (_searchQuery.isNotEmpty)
            Expanded(
              child: _buildSearchResults(),
            ),
            
          // Empty state
          if (_isSearching && _searchQuery.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 80, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'Start typing to search',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchesSection() {
    List<String> recentSearches = [
    ]; // This would typically come from local storage
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Clear recent searches
                  },
                  child: Text('Clear'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: recentSearches.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.history),
                  title: Text(recentSearches[index]),
                  trailing: Icon(Icons.north_west, size: 16),
                  onTap: () {
                    setState(() {
                      _searchController.text = recentSearches[index];
                      _searchQuery = recentSearches[index];
                      _isSearching = true;
                    });
                  },
                );
              },
            ),
          ),
          
          // Popular searches or categories section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Popular Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryCard('Courses', Icons.book, Colors.blue),
                _buildCategoryCard('Assignments', Icons.assignment, Colors.orange),
                _buildCategoryCard('Announcements', Icons.campaign, Colors.green),
                _buildCategoryCard('People', Icons.people, Colors.purple),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = title;
            _startSearch();
          });
        },
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    // Determine which collection to search based on filter
    String collection = 'courses'; // Default
    if (_selectedFilter == 'Announcements') {
      return _buildAnnouncementsSearch();
    } else if (_selectedFilter == 'Assignments') {
      return _buildAssignmentsSearch();
    } else if (_selectedFilter == 'People') {
      return _buildPeopleSearch();
    } else if (_selectedFilter == 'Courses' || _selectedFilter == 'All') {
      return _buildCoursesSearch();
    }
    
    // Fallback
    return Center(child: Text('No results found'));
  }
  
  Widget _buildCoursesSearch() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('courses')
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          .where('name', isLessThan: _searchQuery + 'z')
          .limit(10)
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
            
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getColorFromHex(course['bannerColor'] ?? '#1565C0'),
                  child: Text(course['name'][0], style: TextStyle(color: Colors.white)),
                ),
                title: Text(course['name']),
                subtitle: Text(course['teacherName']),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(courseId: doc.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildAnnouncementsSearch() {
    // We need to search across all courses
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('courses')
          .where('studentIds', arrayContains: _auth.currentUser?.uid)
          .get(),
      builder: (context, coursesSnapshot) {
        if (coursesSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!coursesSnapshot.hasData || coursesSnapshot.data!.docs.isEmpty) {
          return Center(child: Text('No announcements found'));
        }
        
        List<Widget> announcementWidgets = [];
        int coursesProcessed = 0;
        int totalCourses = coursesSnapshot.data!.docs.length;
        
        return StatefulBuilder(
          builder: (context, setState) {
            for (var courseDoc in coursesSnapshot.data!.docs) {
              String courseId = courseDoc.id;
              Map<String, dynamic> courseData = courseDoc.data() as Map<String, dynamic>;
              
              announcementWidgets.add(
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('courses')
                      .doc(courseId)
                      .collection('announcements')
                      .where('content', isGreaterThanOrEqualTo: _searchQuery)
                      .where('content', isLessThan: _searchQuery + 'z')
                      .snapshots(),
                  builder: (context, snapshot) {
                    // Increment counter for each processed course
                    coursesProcessed++;
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      if (coursesProcessed == totalCourses) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return SizedBox.shrink();
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return SizedBox.shrink();
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            courseData['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        ...snapshot.data!.docs.map((announcementDoc) {
                          Map<String, dynamic> announcement = announcementDoc.data() as Map<String, dynamic>;
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              title: Text(
                                announcement['content'].toString().length > 50
                                    ? announcement['content'].toString().substring(0, 50) + '...'
                                    : announcement['content'].toString(),
                              ),
                              subtitle: Text(
                                'By ${announcement['authorName']} • ${_formatDate(announcement['createdAt'].toDate())}'
                              ),
                              trailing: Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CourseDetailScreen(courseId: courseId),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              );
            }
            
            if (coursesProcessed == totalCourses && announcementWidgets.isEmpty) {
              return Center(child: Text('No announcements found matching "$_searchQuery"'));
            }
            
            return ListView(
              children: announcementWidgets,
            );
          },
        );
      },
    );
  }
  
  Widget _buildAssignmentsSearch() {
    // Similar to announcements search, but for assignments
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('courses')
          .where('studentIds', arrayContains: _auth.currentUser?.uid)
          .get(),
      builder: (context, coursesSnapshot) {
        if (coursesSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!coursesSnapshot.hasData || coursesSnapshot.data!.docs.isEmpty) {
          return Center(child: Text('No assignments found'));
        }
        
        List<Widget> assignmentWidgets = [];
        int coursesProcessed = 0;
        int totalCourses = coursesSnapshot.data!.docs.length;
        
        return StatefulBuilder(
          builder: (context, setState) {
            for (var courseDoc in coursesSnapshot.data!.docs) {
              String courseId = courseDoc.id;
              Map<String, dynamic> courseData = courseDoc.data() as Map<String, dynamic>;
              
              assignmentWidgets.add(
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('courses')
                      .doc(courseId)
                      .collection('assignments')
                      .where('title', isGreaterThanOrEqualTo: _searchQuery)
                      .where('title', isLessThan: _searchQuery + 'z')
                      .snapshots(),
                  builder: (context, snapshot) {
                    coursesProcessed++;
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      if (coursesProcessed == totalCourses) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return SizedBox.shrink();
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return SizedBox.shrink();
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            courseData['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        ...snapshot.data!.docs.map((assignmentDoc) {
                          Map<String, dynamic> assignment = assignmentDoc.data() as Map<String, dynamic>;
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: Icon(Icons.assignment, color: Colors.orange),
                              title: Text(assignment['title']),
                              subtitle: Text('Due: ${_formatDate(assignment['dueDate'].toDate())}'),
                              trailing: Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CourseDetailScreen(courseId: courseId),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              );
            }
            
            if (coursesProcessed == totalCourses && assignmentWidgets.isEmpty) {
              return Center(child: Text('No assignments found matching "$_searchQuery"'));
            }
            
            return ListView(
              children: assignmentWidgets,
            );
          },
        );
      },
    );
  }
  
  Widget _buildPeopleSearch() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          .where('name', isLessThan: _searchQuery + 'z')
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No people found'));
        }
        
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            Map<String, dynamic> person = doc.data() as Map<String, dynamic>;
            
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  backgroundImage: person['photoUrl'] != null 
                    ? NetworkImage(person['photoUrl']) 
                    : null,
                  child: person['photoUrl'] == null 
                    ? Text(person['name'][0], style: TextStyle(color: Colors.white)) 
                    : null,
                ),
                title: Text(person['name']),
                subtitle: Text(person['role'] ?? 'Student'),
                trailing: IconButton(
                  icon: Icon(Icons.message),
                  onPressed: () {
                    // Navigate to messaging
                  },
                ),
                onTap: () {
                  // View profile
                },
              ),
            );
          },
        );
      },
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