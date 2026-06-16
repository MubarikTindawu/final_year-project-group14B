import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/crop_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/navigation_provider.dart';
import 'views/splash_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation for a consistent mobile experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style the Android system status bar to match the app's green theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CropProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const FarmManagerApp(),
    ),
  );
}

class FarmManagerApp extends StatelessWidget {
  const FarmManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm Manager — Ghana Best Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Smooth page transitions throughout the app
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return _fadeRoute(const LoginScreen());
          case '/main':
            return _fadeRoute(const MainNavigation());
          default:
            return null;
        }
      },
      home: const SplashScreen(),
    );
  }

  /// Smooth fade transition between top-level routes
  PageRoute _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }
}