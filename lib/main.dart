import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/sync_service.dart';
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/app_shell.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database factory for web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Initialize Supabase Cloud Connection if configured
  if (SyncService.isConfigured) {
    try {
      await Supabase.initialize(
        url: SyncService.supabaseUrl,
        publishableKey: SyncService.supabaseAnonKey,
      );
    } catch (_) {
      // Allow seamless offline startup if cloud servers are currently unreachable
    }
  }

  // Allow all orientations

  runApp(const ArabicTeacherApp());
}

class ArabicTeacherApp extends StatelessWidget {
  const ArabicTeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => AppProvider()..loadAll()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'الشاعر في اللغة العربية',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.mode,

            // Arabic RTL locale
            locale: const Locale('ar', 'EG'),
            supportedLocales: const [
              Locale('ar', 'EG'),
              Locale('ar'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // Force RTL for the entire app
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              );
            },

            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (!auth.isInitialized) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return auth.isAuthenticated
                    ? const AppShell()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
