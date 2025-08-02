import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sproki/models/progress_data.dart';
import 'models/child_profile.dart';
import 'models/word_attempt.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(ChildProfileAdapter());
  Hive.registerAdapter(WordAttemptAdapter());
  Hive.registerAdapter(ProgressDataAdapter());

  await Hive.openBox<ChildProfile>('children');
  await Hive.openBox<WordAttempt>('attempts');
  await Hive.openBox<ProgressData>('progress');
  await Hive.openBox('settings');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sproki',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Comic Sans MS', // Børnevenlig font
      ),
      home: const HomeScreen(),
    );
  }
}
