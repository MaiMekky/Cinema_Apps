class Seat {
  final String id;
  final bool booked;
  final String? userId;

  Seat({required this.id, required this.booked, this.userId});

  factory Seat.fromMap(Map<String, dynamic> data, String id) {
    return Seat(
      id: id,
      booked: data['booked'] ?? false,
      userId: data['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'booked': booked, 'userId': userId};
  }
}
