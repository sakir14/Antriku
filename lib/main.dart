import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/customer/screens/customer_dashboard.dart';
import 'features/merchant/screens/merchant_dashboard.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/business_provider.dart';
import 'providers/customer_dashboard_provider.dart';
import 'providers/merchant_dashboard_provider.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint(
    'Notifikasi Masuk (Latar Belakang): ${message.notification?.title}',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  _listenForegroundNotifications();

  runApp(const AntriKuApp());
}

void _listenForegroundNotifications() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final title =
        notification?.title ?? message.data['title']?.toString() ?? 'AntriKu';
    final body =
        notification?.body ??
        message.data['body']?.toString() ??
        'Ada notifikasi baru.';

    debugPrint('FCM FOREGROUND: $title - $body');

    rootScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1F2937),
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(body, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('FCM DIBUKA: ${message.messageId}');
  });
}

class AntriKuApp extends StatelessWidget {
  const AntriKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => CustomerDashboardProvider()),
        ChangeNotifierProvider(create: (_) => MerchantDashboardProvider()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'AntriKu',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              textTheme: GoogleFonts.poppinsTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkLoginStatus();
      }
    });
  }

  Future<void> _checkLoginStatus() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loadSession(syncFcm: true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (!authProvider.hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
      return;
    }

    if (authProvider.isAuthenticated) {
      if (authProvider.isMerchant) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MerchantDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerDashboard()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0061FF), Color(0xFF60EFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon.png', width: 120),
            const SizedBox(height: 20),
            const Text(
              'AntriKu',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Antre Tanpa Ribet',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
