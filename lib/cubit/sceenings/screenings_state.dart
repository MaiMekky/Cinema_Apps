part of 'screenings_cubit.dart';

abstract class ScreeningsState {}

class ScreeningsLoading extends ScreeningsState {}

class ScreeningsLoaded extends ScreeningsState {
  final List<Map<String, dynamic>> screenings;
  ScreeningsLoaded(this.screenings);
}

class ScreeningsError extends ScreeningsState {
  final String error;
  ScreeningsError(this.error);
}
