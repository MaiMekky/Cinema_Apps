import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '/services/movies_repository.dart';
import '/cubit/movies/movies_cubit.dart';
import '/cubit/add_movie/add_movie_cubit.dart';
import '/cubit/dashboard/dashboard_cubit.dart';
import 'screens/vendor_dashboard_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/booking_details_screen.dart';
import 'firebase_options.dart';

/// 🌍 Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 🔔 Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 🔔 Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final title = message.notification?.title ?? message.data['title'] ?? 'New Booking';
  final body = message.notification?.body ?? message.data['body'] ?? '';

  await FirebaseFirestore.instance.collection('notifications').add({
    'title': title,
    'message': body,
    'data': message.data,
    'bookingId': message.data['bookingId'],
    'createdAt': FieldValue.serverTimestamp(),
    'seen': false,
  });
}

/// 🔧 Setup WhatsApp-style notifications
Future<void> _setupLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      navigatorKey.currentState?.pushNamed('/notifications');
    },
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'vendor_notifications',
    'Vendor Notifications',
    description: 'Booking notifications',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

/// 🔔 Save vendor FCM token
Future<void> saveVendorToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

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

void _handleNavigation(Map<String, dynamic> data) {
  final bookingId = data['bookingId'];
  if (bookingId != null && bookingId.isNotEmpty) {
    navigatorKey.currentState?.pushNamed('/booking-details', arguments: bookingId);
  } else {
    navigatorKey.currentState?.pushNamed('/notifications');
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await _setupLocalNotifications();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await saveVendorToken();

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await FirebaseFirestore.instance
        .collection('appConfig')
        .doc('vendor')
        .set({
      'fcmToken': newToken,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? 'New Booking';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    const androidDetails = AndroidNotificationDetails(
      'vendor_notifications',
      'Vendor Notifications',
      channelDescription: 'Booking notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

 await flutterLocalNotificationsPlugin.show(
  DateTime.now().millisecondsSinceEpoch ~/ 1000,
  title,
  body,
  platformDetails,
  payload: jsonEncode({
    ...message.data,
    'bookingId': message.data['bookingId'] ?? '', // Ensure it's included
  }),
);


    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'message': body,
      'data': message.data,
      'bookingId': message.data['bookingId'],
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
  });

  // ✅ الحل هنا!
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNavigation(message.data);
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNavigation(initialMessage.data);
    });
  }

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
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Vendor Dashboard',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111B2B),
      ),
      home: const VendorDashboardScreen(),
      routes: {
        '/notifications': (_) => const NotificationScreen(),
        '/booking-details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          if (args == null || args.isEmpty) {
            return Scaffold(
              backgroundColor: const Color(0xFF111B2B),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'No booking ID provided',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }
          return BookingDetailsScreen(bookingId: args);
        },
      },
    );
  }
}