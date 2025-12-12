// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'app.dart';


// -----------------------------
//  Background message handler
// -----------------------------
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    final data = message.data;
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': message.notification?.title ?? data['title'] ?? 'Notification',
      'message': message.notification?.body ?? data['body'] ?? '',
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
  } catch (e) {}
}


// -----------------------------
// Local notifications setup
// -----------------------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _setupLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final payload = response.payload;
      print("Notification tapped: $payload");
    },
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'vendor_notifications',
    'Vendor Notifications',
    description: 'Channel for vendor booking notifications',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}


// -----------------------------
//  Save vendor FCM token
// -----------------------------
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
    print('Failed to save token: $e');
  }
}


// -----------------------------
//  MAIN
// -----------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _setupLocalNotifications();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    sound: true,
    badge: true,
  );

  print('Notification permission: ${settings.authorizationStatus}');

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


  // Foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title'] ?? 'Notification';
    final body =
        message.notification?.body ?? message.data['body'] ?? '';

    final androidDetails = AndroidNotificationDetails(
      'vendor_notifications',
      'Vendor Notifications',
      channelDescription: 'Channel for vendor booking notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    final platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: jsonEncode(message.data),
    );

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'message': body,
      'data': message.data,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
  });


  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("Opened from background: ${message.data}");
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print("Opened from terminated: ${initialMessage.data}");
  }

  runApp(const CineBookApp());
}
