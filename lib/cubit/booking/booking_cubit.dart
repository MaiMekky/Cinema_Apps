import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/app_repository.dart';

part 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final AppRepository repo;

  BookingCubit(this.repo) : super(BookingInitial());

  Future<void> book({
    required String movieId,
    required String screeningId,
    required List<String> seats,
    required String userId,
  }) async {
    emit(BookingLoading());

    try {
      await repo.bookSeats(
        movieId: movieId,
        screeningId: screeningId,
        seatIds: seats,
        userId: userId,
      );
      emit(BookingSuccess());
    } catch (e) {
      emit(BookingFailure(e.toString()));
    }
  }
}
