import 'package:flutter/material.dart';
import '../course_service.dart';

class TeacherCoursesScreen extends StatefulWidget {
  @override
  _TeacherCoursesScreenState createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  final _courseService = CourseService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  void _addCourse() async {
    await _courseService.createCourse(
      name: _titleController.text,
      description: _descController.text,
    );
    _titleController.clear();
    _descController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Courses')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _courseService.getCoursesByTeacher(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');
          if (!snapshot.hasData) return CircularProgressIndicator();

          final courses = snapshot.data!;
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return ListTile(
                title: Text(course['title']),
                subtitle: Text(course['description']),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () =>
                      _courseService.deleteCourse(course['id']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: _descController, decoration: InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () {
            _addCourse();
            Navigator.pop(context);
          }, child: Text('Create'))
        ],
      ),
    );
  }
}
