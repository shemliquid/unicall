import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'services/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase may be intentionally unconfigured during early setup.
    // The app can still run for UI testing and will show errors when trying to call.
  }
  runApp(const UniCallApp());
}

class UniCallApp extends StatefulWidget {
  const UniCallApp({super.key});

  @override
  State<UniCallApp> createState() => _UniCallAppState();
}

class _UniCallAppState extends State<UniCallApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController();
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'UniCall',
          debugShowCheckedModeBanner: false,
          theme: UniCallTheme.light(controller.settings),
          darkTheme: UniCallTheme.dark(controller.settings),
          themeMode: controller.settings.highContrast
              ? ThemeMode.dark
              : ThemeMode.light,
          onGenerateRoute: (settings) =>
              UniCallRouter.onGenerateRoute(settings, controller),
        );
      },
    );
  }
}
