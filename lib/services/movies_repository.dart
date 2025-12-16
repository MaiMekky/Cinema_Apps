// lib/vendor/services/movies_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/movie_model.dart';

class MoviesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  MoviesRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference get _movies => _firestore.collection('movies');

  // Real-time list of movies
  Stream<List<MovieModel>> watchAllMovies() {
    return _movies.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => MovieModel.fromDoc(d)).toList(),
        );
  }

  Future<MovieModel> getMovieById(String movieId) async {
    final doc = await _movies.doc(movieId).get();
    if (!doc.exists) {
      throw Exception("Movie not found");
    }
    return MovieModel.fromDoc(doc);
  }

  Future<void> updateMovieModel(String id, MovieModel movie) async {
    await FirebaseFirestore.instance
        .collection("movies")
        .doc(id)
        .update(movie.toMap());
  }

  Future<MovieModel> addMovie(MovieModel movie) async {
    try {
      final moviesRef = _firestore.collection('movies');

      // 1️⃣ Save movie document (without ID)
      final docRef = await moviesRef.add(movie.toMap());

      // 2️⃣ Update movie with ID
      final savedMovie = movie.copyWith(id: docRef.id);

      // 3️⃣ Create slots
      final slotsRef = docRef.collection('slots');

      for (int i = 0; i < savedMovie.timeSlots.length; i++) {
        final slotId = "slot_${i + 1}";
        final slotLabel = savedMovie.timeSlots[i];

        final slotDoc = slotsRef.doc(slotId);

        await slotDoc.set({
          "label": slotLabel,
          "createdAt": FieldValue.serverTimestamp(),
        });

        // 4️⃣ Create seats subcollection
        final seatsRef = slotDoc.collection("seats");

        for (int seat = 1; seat <= savedMovie.seats; seat++) {
          await seatsRef.doc(seat.toString()).set({
            "booked": false,
          });
        }
      }

      return savedMovie;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _initSlotsAndSeats(String movieId, List<String> slots, int seats) async {
    final batch = _firestore.batch();
    final movieRef = _movies.doc(movieId);

    for (int i = 0; i < slots.length; i++) {
      final slotDocRef = movieRef.collection('slots').doc('slot_${i + 1}');
      batch.set(slotDocRef, {'label': slots[i], 'createdAt': FieldValue.serverTimestamp()});

      for (int s = 1; s <= seats; s++) {
        final seatDocRef = slotDocRef.collection('seats').doc('$s');
        batch.set(seatDocRef, {'booked': false});
      }
    }
    await batch.commit();
  }

  // ✅ FIXED: Improved delete performance using batch operations
  Future<void> deleteMovie(String movieId) async {
    final batch = _firestore.batch();
    final movieRef = _movies.doc(movieId);

    // Get all slots
    final slotsSnap = await movieRef.collection('slots').get();

    // Add all deletions to batch (movie, slots, and seats)
    // Delete movie document
    batch.delete(movieRef);

    // Delete slots and their seats
    for (final slotDoc in slotsSnap.docs) {
      final seatsSnap = await slotDoc.reference.collection('seats').get();
      
      // Delete all seats for this slot
      for (final seatDoc in seatsSnap.docs) {
        batch.delete(seatDoc.reference);
      }
      
      // Delete slot document
      batch.delete(slotDoc.reference);
    }

    // Execute batch (much faster than sequential deletes)
    await batch.commit();
  }

  // Update movie (image optional)
  Future<void> updateMovie({
    required String movieId,
    String? title,
    String? description,
    File? imageFile,
    int? duration,
    List<String>? timeSlots,
  }) async {
    final movieRef = _movies.doc(movieId);
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (duration != null) updates['duration'] = duration;
    if (timeSlots != null) updates['timeSlots'] = timeSlots;

    if (imageFile != null) {
      final id = const Uuid().v4();
      final ref = _storage.ref('movies/$movieId/$id.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      updates['imageUrl'] = url;
    }

    if (updates.isNotEmpty) await movieRef.update(updates);
    // If timeSlots changed you may want to add new slots and seats or remove old ones.
  }

  // Watch number of booked seats for a particular slot
  Stream<int> watchBookedCount(String movieId, String slotDocId) {
    final seatsRef = _movies.doc(movieId).collection('slots').doc(slotDocId).collection('seats');
    return seatsRef.snapshots().map((snap) {
      int count = 0;
      for (final d in snap.docs) {
        final booked = d.data()['booked'];
        if (booked == true) count++;
      }
      return count;
    });
  }

  // Watch seat statuses list for a slot (ordered by numeric doc id)
  Stream<List<bool>> watchSeats(String movieId, String slotDocId, int seats) {
    final seatsRef = _movies.doc(movieId).collection('slots').doc(slotDocId).collection('seats').orderBy(FieldPath.documentId);
    return seatsRef.snapshots().map((snap) {
      final list = List<bool>.filled(seats, false);
      for (final doc in snap.docs) {
        final id = doc.id;
        final idx = int.tryParse(id);
        if (idx != null && idx >= 1 && idx <= seats) {
          list[idx - 1] = (doc.data()['booked'] ?? false) == true;
        }
      }
      return list;
    });
  }
}
