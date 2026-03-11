import 'package:flutter/material.dart';

import '../features/call/in_call_screen.dart';
import '../features/call/incoming_call_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../services/app_controller.dart';

final class UniCallRoutes {
  static const home = '/';
  static const incoming = '/incoming';
  static const inCall = '/call';
  static const settings = '/settings';
}

final class UniCallRouter {
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    AppController controller,
  ) {
    switch (settings.name) {
      case UniCallRoutes.home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HomeScreen(controller: controller),
        );
      case UniCallRoutes.incoming:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IncomingCallScreen(controller: controller),
        );
      case UniCallRoutes.inCall:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => InCallScreen(controller: controller),
        );
      case UniCallRoutes.settings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SettingsScreen(controller: controller),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not found')),
            body: Center(child: Text('Unknown route: ${settings.name}')),
          ),
        );
    }
  }
}
