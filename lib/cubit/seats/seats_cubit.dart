import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/app_repository.dart';

part 'seats_state.dart';

class SeatsCubit extends Cubit<SeatsState> {
  final AppRepository repo;
  StreamSubscription? _sub;

  SeatsCubit(this.repo) : super(SeatsLoading());

  void listenSeats(String movieId, String screeningId) {
    emit(SeatsLoading());
    _sub = repo.listenToSeats(movieId, screeningId).listen((seats) {
      emit(SeatsLoaded(seats));
    });
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
