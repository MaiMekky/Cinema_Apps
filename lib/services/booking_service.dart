import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie.dart';
import '../models/seat.dart';
import '../models/slot.dart';

class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get movie details
  static Future<Movie> getMovie(String movieId) async {
    final doc = await _firestore.collection('movies').doc(movieId).get();
    if (doc.exists) {
      return Movie.fromMap(doc.data()!, doc.id);
    }
    throw Exception('Movie not found');
  }

  // Get slots for a movie
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

  // Get seats for a specific slot
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

  // Real-time stream for seats
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
    
    // Process in chunks of 10 (Firestore 'whereIn' limit)
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
    
    await _firestore.runTransaction((transaction) async {
      // Get ALL seat documents individually within transaction
      final seatStatus = <String, bool>{};
      
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
        
        final isBooked = seatDoc.data()?['booked'] == true;
        seatStatus[seatId] = isBooked;
        
        if (isBooked) {
          throw Exception('Seat $seatId is already booked');
        }
      }
      
      // Update all selected seats
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
        });
      }
    });
  }

}