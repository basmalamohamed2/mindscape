import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/core/notifications/notification_service.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/features/auth/auth_gate.dart';
import 'package:mindspace/features/canvas/screens/canvas_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await NotificationService.instance.init();
  NotificationService.instance.onTaskNotificationTap =
      _openTaskFromNotification;

  runApp(const ProviderScope(child: MindScapeApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.instance.checkLaunchNotification();
  });
}

void _openTaskFromNotification(String mapId, String nodeId) {
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => CanvasScreen(mapId: mapId, initialNodeId: nodeId),
    ),
  );
}

class MindScapeApp extends StatelessWidget {
  const MindScapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const AuthGate(),
    );
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.spark,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ink,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.thread),
      ),
    );
  }
}
