import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/movie_model.dart';
import '../../services/movies_repository.dart';
import 'edit_movie_state.dart';

class EditMovieCubit extends Cubit<EditMovieState> {
  final MoviesRepository _repo;

  EditMovieCubit(this._repo) : super(EditMovieInitial());

  Future<void> updateMovie({
    required String movieId,
    required MovieModel oldMovie, // 🔥 Pass the existing movie
    String? title,
    String? description,
    File? imageFile,
    Uint8List? webImage,
    int? duration,
    List<String>? timeSlots,
  }) async {
    try {
      emit(EditMovieLoading());

      // =============== IMAGE HANDLING (same as AddMovie) ===============
      String? imageBase64 = oldMovie.imageBase64;

      if (imageFile != null || webImage != null) {
        if (kIsWeb && webImage != null) {
          imageBase64 = base64Encode(webImage);
        } else if (!kIsWeb && imageFile != null) {
          final bytes = await imageFile.readAsBytes();
          imageBase64 = base64Encode(bytes);
        }
      }

      // =============== BUILD UPDATED MOVIE MODEL ===============
      final updatedMovie = oldMovie.copyWith(
        title: title ?? oldMovie.title,
        description: description ?? oldMovie.description,
        duration: duration ?? oldMovie.duration,
        timeSlots: timeSlots ?? oldMovie.timeSlots,
        imageBase64: imageBase64,
      );

      // =============== SAVE TO FIRESTORE ===============
      await _repo.updateMovieModel(movieId, updatedMovie);

      emit(EditMovieSuccess(updatedMovie));
    } catch (e) {
      emit(EditMovieFailure(e.toString()));
    }
  }
}
