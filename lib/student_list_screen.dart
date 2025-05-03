// screens/student_list_screen.dart
import 'package:flutter/material.dart';

class StudentListScreen extends StatefulWidget {
  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final List<Map<String, dynamic>> _students = [
    {
      'id': '001',
      'name': 'John Smith',
      'grade': '10th',
      'major': 'Science',
      'gpa': 3.8,
      'avatar': 'JS',
    },
    {
      'id': '002',
      'name': 'Maria Garcia',
      'grade': '11th',
      'major': 'Mathematics',
      'gpa': 4.0,
      'avatar': 'MG',
    },
    {
      'id': '003',
      'name': 'David Lee',
      'grade': '9th',
      'major': 'History',
      'gpa': 3.5,
      'avatar': 'DL',
    },
    {
      'id': '004',
      'name': 'Sarah Johnson',
      'grade': '12th',
      'major': 'English',
      'gpa': 3.9,
      'avatar': 'SJ',
    },
    {
      'id': '005',
      'name': 'Michael Brown',
      'grade': '10th',
      'major': 'Computer Science',
      'gpa': 3.7,
      'avatar': 'MB',
    },
    {
      'id': '006',
      'name': 'Emily Wilson',
      'grade': '11th',
      'major': 'Art',
      'gpa': 3.6,
      'avatar': 'EW',
    },
    {
      'id': '007',
      'name': 'Daniel Martinez',
      'grade': '9th',
      'major': 'Physical Education',
      'gpa': 3.4,
      'avatar': 'DM',
    },
  ];

  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) {
      return _students;
    }
    return _students.where((student) {
      return student['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildFilterSheet(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Student list
          Expanded(
            child: _filteredStudents.isEmpty
                ? const Center(child: Text('No students found'))
                : ListView.builder(
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              student['avatar'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(student['name']),
                          subtitle: Text(
                              '${student['grade']} • ${student['major']} • GPA: ${student['gpa']}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/details',
                                arguments: student);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add'),
        child: const Icon(Icons.add),
        tooltip: 'Add Student',
      ),
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Filter Students',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Grade'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['9th', '10th', '11th', '12th']
                .map((grade) => FilterChip(
                      label: Text(grade),
                      selected: false,
                      onSelected: (selected) {
                        // Implement filter functionality
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text('Major'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              'Science',
              'Mathematics',
              'History',
              'English',
              'Computer Science'
            ]
                .map((major) => FilterChip(
                      label: Text(major),
                      selected: false,
                      onSelected: (selected) {
                        // Implement filter functionality
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('APPLY'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}