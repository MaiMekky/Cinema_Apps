import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cinema_apps/services/movies_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/movie_model.dart';
import 'add_movie_state.dart';

class AddMovieCubit extends Cubit<AddMovieState> {
  AddMovieCubit(MoviesRepository repo) : super(AddMovieInitial());

  Future<void> addMovie({
    required String title,
    required String description,
    File? imageFile,
    Uint8List? webImage,
    required int duration,
    required List<String> timeSlots,
    int seats = 47,
  }) async {
    if (imageFile == null && webImage == null) {
      emit(AddMovieFailure("Please upload a movie image"));
      return;
    }

    try {
      emit(AddMovieLoading());

      // 1️⃣ Convert image to Base64
      String imageBase64 = '';
      if (kIsWeb && webImage != null) {
        imageBase64 = base64Encode(webImage);
      } else if (!kIsWeb && imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      // 2️⃣ Create MovieModel
      final movie = MovieModel(
        id: '', // Firestore will generate ID
        title: title,
        description: description,
        imageBase64: imageBase64,
        duration: duration,
        timeSlots: timeSlots,
        seats: seats,
      );

      // 3️⃣ Save to Firestore
      final docRef =
          await FirebaseFirestore.instance.collection('movies').add(movie.toMap());
      final savedMovie = movie.copyWith(id: docRef.id);

      emit(AddMovieSuccess(savedMovie));
    } catch (e) {
      emit(AddMovieFailure(e.toString()));
    }
  }
}
