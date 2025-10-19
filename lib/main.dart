import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sproki/data/words_content.dart';
import 'package:sproki/screens/parent_report_upload_screen.dart';
import 'package:sproki/services/plan_store.dart';
import 'package:sproki/services/practice_event_queue.dart';
import 'package:sproki/services/progress_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Screens & routes
import 'package:sproki/routes/app_routes.dart';
import 'package:sproki/screens/main_menu_screen.dart';
import 'package:sproki/screens/onboarding_screen.dart';
import 'package:sproki/screens/select_child_screen.dart';
import 'package:sproki/screens/progress_overview_screen.dart';
import 'package:sproki/screens/category_exercise_screen.dart';
import 'package:sproki/screens/premium_screen.dart';

// Services
import 'package:sproki/services/active_child_service.dart';
import 'package:sproki/services/user_service.dart';

// Hive models
import 'package:sproki/constants/hive_boxes.dart';
import 'package:sproki/models/child_profile.dart';
import 'package:sproki/models/word_attempt.dart';
import 'package:sproki/models/progress_data.dart';
import 'package:sproki/models/category_attempt.dart';

const _envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const _envAnon = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
const _devUrl = '';
const _devAnon = '';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WordsRepo.instance.init();

  // Supabase init (valgfrit)
  final url = _envUrl.isNotEmpty ? _envUrl : _devUrl;
  final anon = _envAnon.isNotEmpty ? _envAnon : _devAnon;
  if (url.isNotEmpty && anon.isNotEmpty) {
    await Supabase.initialize(
      url: url,
      anonKey: anon,
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.error,
      ),
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
  }

  // Hive init
  await Hive.initFlutter();
  Hive
    ..registerAdapter(ChildProfileAdapter())
    ..registerAdapter(WordAttemptAdapter())
    ..registerAdapter(ProgressDataAdapter())
    ..registerAdapter(CategoryAttemptAdapter());

  await Hive.openBox(HiveBoxes.settings);
  await Hive.openBox<ChildProfile>(HiveBoxes.childProfiles);
  await Hive.openBox<WordAttempt>(HiveBoxes.wordAttempts);
  await Hive.openBox<ProgressData>(HiveBoxes.progressData);
  await Hive.openBox<CategoryAttempt>(HiveBoxes.categoryAttempts);

  await ActiveChildService.instance.ensureInitialized();

  // VIGTIGT: PlanStore init for at kunne gemme/aflæse planer
  await PlanStore.init();
  await PracticeEventQueue.ensureBoxesOpened();
  await ProgressService.instance.init();   

  runApp(const SprokiApp());
}

class SprokiApp extends StatelessWidget {
  const SprokiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sproki - Sprogøvelser for Børn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['NotoSans', 'NotoSansSymbols2', 'NotoEmoji'],
      ),
      initialRoute: AppRoutes.mainMenu,
      routes: {
        AppRoutes.mainMenu: (_) => FutureBuilder<bool>(
              future: UserService.isOnboardingCompleted(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return snap.data!
                    ? const MainMenuScreen()
                    : const OnboardingScreen();
              },
            ),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.selectChild: (_) => const SelectChildScreen(),
        AppRoutes.progressOverview: (_) => const ProgressOverviewScreen(),
        AppRoutes.categoryExercise: (_) => const CategoryExerciseScreen(),
        AppRoutes.premium: (_) => const PremiumScreen(),
        AppRoutes.parentReportUpload: (_) => const ParentReportUploadScreen(),
      },
    );
  }
}
