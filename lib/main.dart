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
            return HomeScreen();
          }
          return const RegisterScreen();
        }),
      themeMode: ThemeMode.light, // This would be controlled by settings
      //initialRoute: '/register',
      routes: {
        //'/': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(), 
        '/students': (context) => StudentListScreen(),
        '/add': (context) => AddStudentScreen(),
        '/details': (context) => StudentDetailScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}