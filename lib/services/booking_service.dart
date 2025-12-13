import 'package:cloud_firestore/cloud_firestore.dart';
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
  if (seatIds.isEmpty) {
    throw Exception('No seats selected');
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not logged in');
  }

  await _firestore.runTransaction((transaction) async {
    // 1️⃣ Check seats availability
    for (var seatId in seatIds) {
      final seatRef = _firestore
          .collection('movies')
          .doc(movieId)
          .collection('slots')
          .doc(slotId)
          .collection('seats')
          .doc(seatId);

      final seatDoc = await transaction.get(seatRef);

      if (!seatDoc.exists) {
        throw Exception('Seat $seatId not found');
      }

      if (seatDoc.data()?['booked'] == true) {
        throw Exception('Seat $seatId is already booked');
      }
    }

    // 2️⃣ Book seats
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

    // 3️⃣ Fetch movie
    final movieRef = _firestore.collection('movies').doc(movieId);
    final movieSnap = await transaction.get(movieRef);

    final movieTitle = movieSnap.data()?['title'] ?? 'Unknown movie';

    // 4️⃣ Fetch slot
    final slotRef = movieRef.collection('slots').doc(slotId);
    final slotSnap = await transaction.get(slotRef);

    final slotLabel = slotSnap.data()?['label'] ?? '';

    // 5️⃣ Fetch user name
    final userRef = _firestore.collection('users').doc(user.uid);
    final userSnap = await transaction.get(userRef);

    final customerName = userSnap.data()?['fullName'] ?? 'Customer';

    // 6️⃣ Create booking document (🔥 THIS TRIGGERS FCM)
    final bookingRef = _firestore.collection('bookings').doc();

    transaction.set(bookingRef, {
      'movieId': movieId,
      'movieTitle': movieTitle,
      'slotId': slotId,
      'slotLabel': slotLabel,
      'seats': seatIds,
      'seatsCount': seatIds.length,
      'customerId': user.uid,
      'customerName': customerName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  });
}


}