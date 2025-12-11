// lib/vendor/cubits/movies/movies_state.dart
import '../../models/movie_model.dart';

abstract class MoviesState {}

class MoviesInitial extends MoviesState {}

class MoviesLoading extends MoviesState {}

class MoviesLoaded extends MoviesState {
  final List<MovieModel> movies;
  MoviesLoaded(this.movies);
}

class MoviesError extends MoviesState {
  final String message;
  MoviesError(this.message);
}
