import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/app_repository.dart';

part 'movies_state.dart';

class MoviesCubit extends Cubit<MoviesState> {
  final AppRepository repo;
  StreamSubscription? _sub;

  MoviesCubit(this.repo) : super(MoviesLoading()) {
    listenToMovies();  
  }

  void listenToMovies() {
    _sub = repo.getMoviesStream().listen((movies) {
      emit(MoviesLoaded(movies));
    });
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
