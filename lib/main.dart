import 'package:flutter/material.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'services/app_controller.dart';

void main() {
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
          themeMode:
              controller.settings.highContrast ? ThemeMode.dark : ThemeMode.light,
          onGenerateRoute: (settings) =>
              UniCallRouter.onGenerateRoute(settings, controller),
        );
      },
    );
  }
}
