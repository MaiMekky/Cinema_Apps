import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

import '/services/movies_repository.dart';
import '/cubit/movies/movies_cubit.dart';
import '/cubit/add_movie/add_movie_cubit.dart';
import '/cubit/dashboard/dashboard_cubit.dart';
import 'screens/vendor_dashboard_screen.dart';
import 'firebase_options.dart';

/// 🔔 Save vendor FCM token to Firestore
Future<void> saveVendorToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    debugPrint('📲 Vendor FCM token: $token');

    await FirebaseFirestore.instance
        .collection('appConfig')
        .doc('vendor')
        .set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('❌ Failed to save vendor token: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔑 Ask notification permission
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // ✅ Save vendor FCM token
  await saveVendorToken();

  // 🔄 Handle token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await FirebaseFirestore.instance
        .collection('appConfig')
        .doc('vendor')
        .set({
      'fcmToken': newToken,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });

  final repo = MoviesRepository();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MoviesCubit(repo)..watchAll()),
        BlocProvider(create: (_) => AddMovieCubit(repo)),
        BlocProvider(create: (_) => DashboardCubit(repo)..start()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vendor Dashboard',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111B2B),
      ),
      home: const VendorDashboardScreen(),
    );
  }
}
