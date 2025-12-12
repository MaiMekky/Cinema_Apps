
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/movies_repository.dart';
import '../../models/movie_model.dart';
import 'dashboard_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final MoviesRepository _repo;
  StreamSubscription<List<MovieModel>>? _moviesSub;
  final Map<String, StreamSubscription<int>> _slotSubs = {};
  final Map<String, Map<String,int>> _bookings = {}; 

  DashboardCubit(this._repo) : super(DashboardInitial());

  void start() {
    emit(DashboardLoading());
    _moviesSub?.cancel();
    _moviesSub = _repo.watchAllMovies().listen((movies) {
      _syncSlotListeners(movies);
    }, onError: (e) {
      emit(DashboardError(e.toString()));
    });
  }

  Future<void> _syncSlotListeners(List<MovieModel> movies) async {
    final movieIds = movies.map((m) => m.id).toSet();

   
    final toRemove = _bookings.keys.where((id) => !movieIds.contains(id)).toList();
    for (final mid in toRemove) {
      _bookings.remove(mid);
      final keys = _slotSubs.keys.where((k) => k.startsWith('$mid/')).toList();
      for (final k in keys) {
        await _slotSubs[k]?.cancel();
        _slotSubs.remove(k);
      }
    }

    for (final movie in movies) {
      final movieRef = FirebaseFirestore.instance.collection('movies').doc(movie.id);
      final slotsSnap = await movieRef.collection('slots').get();
      _bookings.putIfAbsent(movie.id, () => {});

      for (final slotDoc in slotsSnap.docs) {
        final slotKey = '${movie.id}/${slotDoc.id}';
        if (_slotSubs.containsKey(slotKey)) continue;

        final sub = _repo.watchBookedCount(movie.id, slotDoc.id).listen((count) {
          _bookings[movie.id]![slotDoc.id] = count;
          emit(DashboardLoaded(Map.from(_bookings)));
        });

        _slotSubs[slotKey] = sub;
      }
    }

    emit(DashboardLoaded(Map.from(_bookings)));
  }

  @override
  Future<void> close() {
    _moviesSub?.cancel();
    for (final s in _slotSubs.values) s.cancel();
    return super.close();
  }
}
