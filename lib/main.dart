import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/router.dart';
import 'data/services/notification_service.dart';
import 'data/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent user preferences
  await SettingsService.instance.init();

  // Initialize local notifications with payload routing
  await NotificationService.instance.init(
    onSelectNotification: (payload) {
      if (payload != null && payload.isNotEmpty) {
        appRouter.push('/food-details/$payload');
      }
    },
  );

  runApp(
    const ProviderScope(
      child: GreenShelfApp(),
    ),
  );
}
