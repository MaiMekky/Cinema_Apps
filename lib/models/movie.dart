class Movie {
  final String id;
  final String title;
  final String description;
  final int duration;
  final int seats;
  final String imageBase64;
  final List<String> timeSlots;
  final DateTime createdAt;

  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.seats,
    required this.imageBase64,
    required this.timeSlots,
    required this.createdAt,
  });

  // factory Movie.fromFirestore(Map<String, dynamic> data, String id) {
  //   return Movie(
  //     id: id,
  //     title: data['title'] ?? '',
  //     description: data['description'] ?? '',
  //     duration: data['duration'] ?? 0,
  //     seats: data['seats'] ?? 0,
  //     imageBase64: data['imageBase64'] ?? '',
  //     timeSlots: List<String>.from(data['timeSlots'] ?? []),
  //     createdAt: (data['createdAt'] as Timestamp).toDate(),
  //   );
  // }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'duration': duration,
      'seats': seats,
      'imageBase64': imageBase64,
      'timeSlots': timeSlots,
      'createdAt': createdAt,
    };
  }
}
