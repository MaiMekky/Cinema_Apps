import 'package:cloud_firestore/cloud_firestore.dart';

class AppRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // -------------------------
  // MOVIES
  // -------------------------
  Stream<List<Map<String, dynamic>>> getMoviesStream() {
    return firestore.collection("movies").snapshots().map((snap) {
      return snap.docs.map((doc) {
        return {
          "id": doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  // -------------------------
  // SCREENINGS (movie-specific)
  // -------------------------
 Future<List<Map<String, dynamic>>> getScreenings(String movieId) async {
    final snap = await firestore
        .collection("movies")
        .doc(movieId)
        .collection("slots") 
        .get();

    return snap.docs
        .map((doc) => {"id": doc.id, ...doc.data()})
        .toList();
  }


  // -------------------------
  // SEATS (real-time)
  // -------------------------
  Stream<Map<String, dynamic>> listenToSeats(String movieId, String slotId) {
    return firestore
        .collection("movies")
        .doc(movieId)
        .collection("slots")
        .doc(slotId)  
        .collection("seats")
        .snapshots()
        .map((snap) => {
          "seats": snap.docs.map((doc) => {
            "id": doc.id,
            "booked": doc.data()["booked"] ?? false,
          }).toList(),
        });
  }

  // -------------------------
  // BOOK SEATS (transaction)
  // -------------------------
  Future<void> bookSeats({
    required String movieId,
    required String screeningId,
    required List<String> seatIds,
    required String userId,
  }) async {
    final docRef = firestore
        .collection("movies")
        .doc(movieId)
        .collection("screenings")
        .doc(screeningId);

    await firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);

      final seats = Map<String, dynamic>.from(snapshot["seats"]);

      // check availability
      for (var seat in seatIds) {
        if (seats[seat]["booked"] == true) {
          throw Exception("Seat $seat already booked");
        }
      }

      // book seats
      for (var seat in seatIds) {
        seats[seat]["booked"] = true;
        seats[seat]["userId"] = userId;
      }

      tx.update(docRef, {"seats": seats});
    });
  }
}
