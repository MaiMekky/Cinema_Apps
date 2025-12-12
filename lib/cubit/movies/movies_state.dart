part of 'movies_cubit.dart';

abstract class MoviesState {}

class MoviesLoading extends MoviesState {}

class MoviesLoaded extends MoviesState {
  final List<Map<String, dynamic>> movies;
  MoviesLoaded(this.movies);
}

class MoviesError extends MoviesState {
  final String error;
  MoviesError(this.error);
}
