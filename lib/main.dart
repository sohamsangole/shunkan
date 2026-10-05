import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_scaffold.dart';
import 'screens/onboarding_screen.dart';
import 'services/kanji_repository.dart';
import 'services/kanji_selector.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service dependencies
  final storageService = await StorageService.create();
  final kanjiRepository = await KanjiRepository.create();
  final selectorService = KanjiSelectorService(repository: kanjiRepository);
  final notificationService =
      NotificationService(selectorService: selectorService);

  final appState = AppState(
    storageService: storageService,
    kanjiRepository: kanjiRepository,
    selectorService: selectorService,
    notificationService: notificationService,
  );

  await appState.initialize();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const KanjiApp(),
    ),
  );
}

class KanjiApp extends StatelessWidget {
  const KanjiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shunkan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
          surface: Color(0xFF0A0A0A),
        ),
      ),
      home: const RootGate(),
    );
  }
}

/// RootGate determines whether to present Onboarding or 3-tab MainScaffold
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (!appState.isOnboardingCompleted || appState.currentLevel == null) {
      return const OnboardingScreen();
    }

    return const MainScaffold();
  }
}
