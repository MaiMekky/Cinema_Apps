// lib/vendor/cubits/edit_movie/edit_movie_state.dart
import '../../models/movie_model.dart';

abstract class EditMovieState {}
class EditMovieInitial extends EditMovieState {}
class EditMovieLoading extends EditMovieState {}
class EditMovieSuccess extends EditMovieState {
  final MovieModel movie;
  EditMovieSuccess(this.movie);
}
class EditMovieFailure extends EditMovieState {
  final String message;
  EditMovieFailure(this.message);
}
