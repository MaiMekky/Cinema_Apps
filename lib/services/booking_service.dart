import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie.dart';
import '../models/seat.dart';
import '../models/screening.dart';

class BookingService {
  // static Future<Movie> getMovie(String movieId) async {
  //   return Movie(
  //     id: '1',
  //     title: 'The Dark Universe',
  //     description:
  //         'An epic space adventure following a crew of explorers as they venture into the unknown depths of space, encountering mysterious alien civilizations.',
  //     posterUrl: 'https://picsum.photos/600/400',
  //     duration: 120,
  //   );
  // }

  static Future<List<Screening>> getScreenings(String movieId) async {
    return [
      Screening(
        id: '1',
        startTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
        seats: _generateSeats(),
      ),
      Screening(
        id: '2',
        startTime: DateTime.now().add(const Duration(days: 1, hours: 14)),
        seats: _generateSeats(),
      ),
      Screening(
        id: '3',
        startTime: DateTime.now().add(const Duration(days: 1, hours: 18)),
        seats: _generateSeats(),
      ),
      Screening(
        id: '4',
        startTime: DateTime.now().add(const Duration(days: 1, hours: 21)),
        seats: _generateSeats(),
      ),
    ];
  }

  static Map<String, Seat> _generateSeats() {
    final seats = <String, Seat>{};
    final random = Random();

    const rowsAG = ['A', 'B', 'C', 'D'];
    for (var row in rowsAG) {
      for (var i = 1; i <= 9; i++) {
        final seatId = '$row$i';
        final isPremium = row == 'G';
        final bookingProbability = isPremium ? 0.35 : 0.2;
        final isBooked = random.nextDouble() < bookingProbability;

        seats[seatId] = Seat(
          id: seatId,
          booked: isBooked,
          userId: isBooked ? 'u${random.nextInt(1000)}' : null,
        );
      }
    }

    const rowH = 'H';
    for (var i = 1; i <= 11; i++) {
      final seatId = '$rowH$i';
      final isBooked = random.nextDouble() < 0.35;

      seats[seatId] = Seat(
        id: seatId,
        booked: isBooked,
        userId: isBooked ? 'u${random.nextInt(1000)}' : null,
      );
    }

    print(seats.length);
    return seats;
  }

  static Future<void> bookSeats({
    required String movieId,
    required String screeningId,
    required List<String> seatIds,
    required String userId,
  }) async {
    await FirebaseFirestore.instance
        .collection('movies')
        .doc(movieId)
        .collection('screenings')
        .doc(screeningId)
        .update({
          for (var seatId in seatIds) 'seats.$seatId.booked': true,
          for (var seatId in seatIds) 'seats.$seatId.userId': userId,
        });
  }
}
