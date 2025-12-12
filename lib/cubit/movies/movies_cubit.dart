
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/movies_repository.dart';
import '../../models/movie_model.dart';
import 'movies_state.dart';

class MoviesCubit extends Cubit<MoviesState> {
  final MoviesRepository _repo;
  StreamSubscription<List<MovieModel>>? _sub;

  MoviesCubit(this._repo) : super(MoviesInitial());

  void watchAll() {
    emit(MoviesLoading());
    _sub?.cancel();
    _sub = _repo.watchAllMovies().listen(
      (movies) => emit(MoviesLoaded(movies)),
      onError: (e) => emit(MoviesError(e.toString())),
    );
  }

  Future<void> deleteMovie(String id) async {
    try {
      await _repo.deleteMovie(id);
    } catch (e) {
      emit(MoviesError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
