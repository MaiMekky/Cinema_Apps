import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../models/movie.dart';
import '../models/seat.dart';
import '../models/slot.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  


  static Future<Movie> getMovie(String movieId) async {
    final doc = await _firestore.collection('movies').doc(movieId).get();
    if (doc.exists) {
      return Movie.fromMap(doc.data()!, doc.id);
    }
    throw Exception('Movie not found');
  }

  static Future<List<Slot>> getSlots(String movieId) async {
    final snapshot = await _firestore
        .collection('movies')
        .doc(movieId)
        .collection('slots')
        .get();
    
    return snapshot.docs
        .map((doc) => Slot.fromMap(doc.data(), doc.id))
        .toList();
  }

  static Future<Map<String, Seat>> getSeats(String movieId, String slotId) async {
    final snapshot = await _firestore
        .collection('movies')
        .doc(movieId)
        .collection('slots')
        .doc(slotId)
        .collection('seats')
        .get();
    
    final seats = <String, Seat>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      seats[doc.id] = Seat(
        id: doc.id,
        booked: data['booked'] ?? false,
      );
    }
    return seats;
  }

  static Stream<Map<String, Seat>> listenToSeats(String movieId, String slotId) {
    return _firestore
        .collection('movies')
        .doc(movieId)
        .collection('slots')
        .doc(slotId)
        .collection('seats')
        .snapshots()
        .map((snapshot) {
          final seats = <String, Seat>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            seats[doc.id] = Seat(
              id: doc.id,
              booked: data['booked'] ?? false,
            );
          }
          return seats;
        });
  }

  static Future<bool> checkSeatsAvailability({
    required String movieId,
    required String slotId,
    required List<String> seatIds,
  }) async {
    try {
      final unavailableSeats = await _checkUnavailableSeats(movieId, slotId, seatIds);
      return unavailableSeats.isEmpty;
    } catch (e) {
      print('Error checking seat availability: $e');
      return false;
    }
  }

  static Future<List<String>> _checkUnavailableSeats(
    String movieId, 
    String slotId, 
    List<String> seatIds
  ) async {
    if (seatIds.isEmpty) return [];
    
    final seatsRef = _firestore
        .collection('movies')
        .doc(movieId)
        .collection('slots')
        .doc(slotId)
        .collection('seats');
    
    final unavailableSeats = <String>[];
    
    for (var i = 0; i < seatIds.length; i += 10) {
      final chunk = seatIds.sublist(
        i, 
        i + 10 > seatIds.length ? seatIds.length : i + 10
      );
      
      try {
        final snapshot = await seatsRef.where(FieldPath.documentId, whereIn: chunk).get();
        
        for (var doc in snapshot.docs) {
          if (doc.data()['booked'] == true) {
            unavailableSeats.add(doc.id);
          }
        }
      } catch (e) {
        print('Error checking seat chunk: $e');
        unavailableSeats.addAll(chunk);
      }
    }
    
    return unavailableSeats;
  }

  static Future<void> bookSeatsWithTransaction({
    required String movieId,
    required String slotId,
    required List<String> seatIds,
  }) async {
    print('📝 Starting booking process...');
    
    if (seatIds.isEmpty) {
      throw Exception('No seats selected');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    print('👤 User: ${user.email}');
    print('🎬 Movie ID: $movieId');
    print('🕐 Slot ID: $slotId');
    print('🪑 Seats: ${seatIds.length}');

    try {
      // ✅ SAVE SEAT COUNT BEFORE TRANSACTION (THIS IS THE FIX!)
      final int seatsCount = seatIds.length;
      print('💾 Saved seat count BEFORE transaction: $seatsCount');

      // ✅ Variables to hold data for notification
      late String movieTitle;
      late String slotLabel;
      late String customerName;
      late String bookingId;
      
      await _firestore.runTransaction((transaction) async {
        // ✅ STEP 1: READ ALL DATA FIRST
        print('📖 Reading all necessary data...');

        // Read seat documents
        final seatDocuments = <DocumentSnapshot>[];
        for (var seatId in seatIds) {
          final seatRef = _firestore
              .collection('movies')
              .doc(movieId)
              .collection('slots')
              .doc(slotId)
              .collection('seats')
              .doc(seatId);
          seatDocuments.add(await transaction.get(seatRef));
        }

        // Read movie document
        final movieRef = _firestore.collection('movies').doc(movieId);
        final movieSnap = await transaction.get(movieRef);

        // Read slot document
        final slotRef = movieRef.collection('slots').doc(slotId);
        final slotSnap = await transaction.get(slotRef);

        // Read user document
        final userRef = _firestore.collection('users').doc(user.uid);
        final userSnap = await transaction.get(userRef);

        print('✅ All data read successfully');

        // ✅ STEP 2: VALIDATE DATA
        print('🔍 Validating data...');

        // Check seat availability
        for (var i = 0; i < seatDocuments.length; i++) {
          final seatDoc = seatDocuments[i];
          if (!seatDoc.exists) {
            throw Exception('Seat ${seatIds[i]} not found');
          }
          if (seatDoc.data() != null) {
            final data = seatDoc.data() as Map<String, dynamic>;
            if (data['booked'] == true) {
              throw Exception('Seat ${seatIds[i]} is already booked');
            }
          }
        }

        // Check movie exists
        if (!movieSnap.exists) {
          throw Exception('Movie not found');
        }

        // Check slot exists
        if (!slotSnap.exists) {
          throw Exception('Slot not found');
        }

        print('✅ All validations passed');

        // ✅ STEP 3: EXTRACT DATA
        print('📊 Extracting data...');

        movieTitle = movieSnap.data()?['title'] ?? 'Unknown movie';
        slotLabel = slotSnap.data()?['label'] ?? 'Unknown slot';
        customerName = userSnap.data()?['fullName'] ?? user.email ?? 'Customer';

        print('✅ Movie: $movieTitle');
        print('✅ Slot: $slotLabel');
        print('✅ Customer: $customerName');

        // ✅ STEP 4: WRITE ALL DATA
        print('✍️ Writing data to database...');

        // Book all seats
        for (var seatId in seatIds) {
          final seatRef = _firestore
              .collection('movies')
              .doc(movieId)
              .collection('slots')
              .doc(slotId)
              .collection('seats')
              .doc(seatId);

          transaction.update(seatRef, {
            'booked': true,
            'bookedAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
          });
        }

        // Create booking document
        final bookingRef = _firestore.collection('bookings').doc();
        bookingId = bookingRef.id;

        transaction.set(bookingRef, {
          'bookingId': bookingRef.id,
          'movieId': movieId,
          'movieTitle': movieTitle,
          'slotId': slotId,
          'slotLabel': slotLabel,
          'seats': seatIds,
          'seatsCount': seatsCount, // ✅ Use the saved count HERE
          'customerId': user.uid,
          'customerEmail': user.email,
          'customerName': customerName,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'confirmed',
        });

        print('✅ Booking document created: ${bookingRef.id}');
      });

      print('🎉 Booking completed successfully!');
      print('📋 Booking ID: $bookingId');
      print('📊 Total Seats Booked: $seatsCount'); // ✅ Log the saved count
      
      // 🔔 SEND NOTIFICATION AFTER BOOKING - USE THE SAVED COUNT
      await _sendVendorNotification(
        bookingId: bookingId,
        movieTitle: movieTitle,
        slotLabel: slotLabel,
        customerName: customerName,
        seatsCount: seatsCount, // ✅ PASS THE SAVED COUNT HERE!
      );
      
    } catch (e) {
      print('❌ Booking error: $e');
      throw Exception('Booking failed: $e');
    }
  }

  // 🔔 Send notification to vendor using FCM V1 API with HARDCODED TOKEN
  static Future<void> _sendVendorNotification({
    required String bookingId,
    required String movieTitle,
    required String slotLabel,
    required String customerName,
    required int seatsCount,
  }) async {
    try {
      print('🔔 Preparing to send notification to VENDOR...');
      print('📋 Booking ID: $bookingId');
      print('🎬 Movie: $movieTitle');
      print('👤 Customer: $customerName');
      print('🪑 Seats: $seatsCount');

      print('✅ Using hardcoded vendor token');

      // Get access token using Service Account
      print('🔑 Getting access token from Google...');
      final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final authClient = await clientViaServiceAccount(credentials, scopes);

      // FCM V1 API URL
      const String fcmUrl = 
          'https://fcm.googleapis.com/v1/projects/cinemaapps-5f65f/messages:send';

      // ✅ Create notification payload for VENDOR with HARDCODED TOKEN
      final payload = {
        'message': {
          'token': VENDOR_FCM_TOKEN,  // ✅ HARDCODED VENDOR TOKEN
          'notification': {
            'title': '🎟️ New Booking Received!',
            'body': '$customerName booked $seatsCount seats for "$movieTitle"',
          },
          'data': {
            'bookingId': bookingId,
            'movieTitle': movieTitle,
            'slotLabel': slotLabel,
            'customerName': customerName,
            'seatsCount': seatsCount.toString(),
            'notificationType': 'new_booking',
          },
          'android': {
            'priority': 'HIGH',
            'notification': {
              'channel_id': 'vendor_notifications',
              'sound': 'default',
            },
          },
          'apns': {
            'headers': {
              'apns-priority': '10',
            },
            'payload': {
              'aps': {
                'alert': {
                  'title': '🎟️ New Booking Received!',
                  'body': '$customerName booked $seatsCount seats for "$movieTitle"',
                },
                'badge': 1,
                'sound': 'default',
              }
            }
          }
        }
      };

      print('📤 Sending notification via FCM V1 API...');
      
      final response = await authClient.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      authClient.close();

      if (response.statusCode == 200) {
        print('✅ Notification sent successfully to VENDOR! 🎉');
        print('📋 Booking ID: $bookingId');
        print('📱 Vendor will receive notification');
        print('-------------------------------------------');
      } else {
        print('❌ Failed to send notification');
        print('Status Code: ${response.statusCode}');
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('❌ Notification error: $e');
      rethrow;
    }
  }
}