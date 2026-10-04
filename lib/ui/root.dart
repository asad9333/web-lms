import 'package:flutter/material.dart';
import '../core/session.dart';
import 'admin_screens.dart';
import 'auth_screens.dart';
import 'student_screens.dart';
import 'teacher_screens.dart';

/// Decides which screen to show based on the saved login session.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final u = Session.user;
    if (u == null) return const LoginScreen();
    if (u.mustChangePassword) return const ChangePasswordScreen();
    if (u.isAdmin) return const AdminDashboardScreen();
    if (u.isTeacher) return const TeacherDashboardScreen();
    return const StudentDashboardScreen();
  }
}
