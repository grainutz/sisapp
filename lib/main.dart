// main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import '/home_screen.dart';
import '/student_list_screen.dart';
import '/add_student_screen.dart';
import '/student_detail_screen.dart';
import '/settings_screen.dart';
import '/Login/login_screen.dart';
import '/Login/register_screen.dart';
import 'package:sisapp/teacher/screens/teacher_home_screen.dart';
import 'Login/teacher_register_screen.dart';
import 'Login/teacher_login_screen.dart';
import 'role_selection_screen.dart';
import '../teacher/screens/teacher_courses_screen.dart';
import '/teacher/screens/teacher_assignment_screen.dart';
import '/teacher/screens/teacher_announcement_screen.dart';
import '/teacher/screens/teacher_submissions_screen.dart';
import '/teacher/screens/grading_screen.dart';
import 'teacher/screens/courses_students_screen.dart';
import 'teacher/screens/course_assignments_screen.dart';
import 'Login/admin_login_screen.dart';
import 'admin/admin_dashboard.dart';
import 'admin/admin_course_management_screen.dart';
import 'admin/admin_registration_screen.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  // firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(StudentInfoApp());
}

class StudentInfoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Information System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 1,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          elevation: 1,
          backgroundColor: Colors.grey.shade900,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey.shade800,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(), 
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(
              child: CircularProgressIndicator()
            );
          }
          if(snapshot.data != null){
            //return HomeScreen();
          }
          return RoleSelectionScreen(); //RegisterScreen();
        }),
      themeMode: ThemeMode.light, // This would be controlled by settings
      //initialRoute: '/register',
      routes: {
        //'/': (context) => RoleSelectionScreen(),
        '/login-student': (context) => LoginStudentScreen(),
        '/login-teacher': (context) => LoginTeacherScreen(),
        '/login-admin': (context) => AdminLoginScreen(),
        '/register': (context) => RegisterStudentScreen(),
        '/register-teacher': (context) => const RegisterTeacherScreen(), 
        '/students': (context) => StudentListScreen(),
        '/add': (context) => AddStudentScreen(),
        '/details': (context) => StudentDetailScreen(),
        '/settings': (context) => SettingsScreen(),
        '/teacherHome': (context) => TeacherHomeScreen(),
        '/teacher-courses': (context) => TeacherCoursesScreen(),
        '/teacher-assignments': (context) => TeacherAssignmentsScreen(),
        '/announcements': (context) => AnnouncementsScreen(),
        '/submissions': (context) => SubmissionsScreen(),
        '/grading': (context) => GradingScreen(),
        '/admin-dashboard': (context) => AdminHomeScreen(),
        '/admin-courses': (context) => AdminCourseManagementScreen(),
        '/admin-registrations': (context) => AdminRegistrationScreen(),
      },
      onGenerateRoute: (settings) {
    if (settings.name == '/course-students') {
      final args = settings.arguments as Map<String, dynamic>;

      return MaterialPageRoute(
        builder: (context) => CourseStudentsScreen(
          courseId: args['courseId'],
          courseName: args['courseName'],
        ),
      );
    }

    if (settings.name == '/course-assignments') {
      final args = settings.arguments as Map<String, dynamic>;

      return MaterialPageRoute(
        builder: (context) => CourseAssignmentsScreen(
          courseId: args['courseId'],
          courseName: args['courseName'],
        ),
      );
    }

    // Optional fallback for unknown routes
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: const Center(child: Text('404 - Page Not Found')),
      ),
    );
  },
    );
  }
}