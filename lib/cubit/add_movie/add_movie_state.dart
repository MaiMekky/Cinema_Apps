// lib/vendor/cubits/add_movie/add_movie_state.dart
import '../../models/movie_model.dart';

abstract class AddMovieState {}
class AddMovieInitial extends AddMovieState {}
class AddMovieLoading extends AddMovieState {}
class AddMovieSuccess extends AddMovieState {
  final MovieModel movie;
  AddMovieSuccess(this.movie);
}
class AddMovieFailure extends AddMovieState {
  final String message;
  AddMovieFailure(this.message);
}
