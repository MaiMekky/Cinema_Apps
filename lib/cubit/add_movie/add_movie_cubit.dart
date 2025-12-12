import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cinema_apps/services/movies_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/movie_model.dart';
import 'add_movie_state.dart';

class AddMovieCubit extends Cubit<AddMovieState> {
  final MoviesRepository repo;
  AddMovieCubit(this.repo) : super(AddMovieInitial());

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

      String imageBase64 = '';
      if (kIsWeb && webImage != null) {
        imageBase64 = base64Encode(webImage);
      } else if (!kIsWeb && imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      final movie = MovieModel(
        id: '',
        title: title,
        description: description,
        imageBase64: imageBase64,
        duration: duration,
        timeSlots: timeSlots,
        seats: seats,
      );

      // ✅ Save movie properly (only one document)
      final savedMovie = await repo.addMovie(movie);

      emit(AddMovieSuccess(savedMovie));
    } catch (e) {
      emit(AddMovieFailure(e.toString()));
    }
  }
}

