
class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Map<String, Map<String, int>> bookings;
  DashboardLoaded(this.bookings);
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
