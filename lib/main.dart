import 'package:flutter/material.dart';
import 'core/db.dart';
import 'core/session.dart';
import 'ui/common.dart';
import 'ui/root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDb.instance; // creates the local database (and default admin) once
  await Session.restore();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course LMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kSlate)
            .copyWith(primary: kSlate, onPrimary: Colors.white),
        scaffoldBackgroundColor: kBg,
      ),
      home: const RootGate(),
    );
  }
}
