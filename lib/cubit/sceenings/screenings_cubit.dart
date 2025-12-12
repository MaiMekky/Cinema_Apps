import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/app_repository.dart';

part 'screenings_state.dart';

class ScreeningsCubit extends Cubit<ScreeningsState> {
  final AppRepository repo;

  ScreeningsCubit(this.repo) : super(ScreeningsLoading());

  Future<void> loadScreenings(String movieId) async {
    emit(ScreeningsLoading());
    try {
      final data = await repo.getScreenings(movieId);
      emit(ScreeningsLoaded(data));
    } catch (e) {
      emit(ScreeningsError(e.toString()));
    }
  }
}
