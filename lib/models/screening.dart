import './seat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Screening {
  final String id;
  final DateTime startTime;
  final Map<String, Seat> seats;

  Screening({
    required this.id,
    required this.startTime,
    required this.seats,
  });

  factory Screening.fromMap(Map<String, dynamic> data, String id) {
    final seatsMap = Map<String, dynamic>.from(data['seats'] ?? {});
    final seats = seatsMap.map((key, value) {
      return MapEntry(key, Seat.fromMap(Map<String, dynamic>.from(value), key));
    });
    
    return Screening(
      id: id,
      startTime: (data['startTime'] as Timestamp).toDate(),
      seats: seats,
    );
  }

  int get availableSeats {
    return seats.values.where((seat) => !seat.booked).length;
  }

  int get totalSeats {
    return seats.length;
  }
}