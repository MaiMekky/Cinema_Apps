part of 'seats_cubit.dart';

abstract class SeatsState {}

class SeatsLoading extends SeatsState {}

class SeatsLoaded extends SeatsState {
  final Map<String, dynamic> seats;
  SeatsLoaded(this.seats);
}

class SeatsError extends SeatsState {
  final String error;
  SeatsError(this.error);
}
