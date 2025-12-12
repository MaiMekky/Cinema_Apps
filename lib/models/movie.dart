import 'package:cloud_firestore/cloud_firestore.dart';

class Movie {
  final String id;
  final String title;
  final String description;
  final String imageBase64;
  final int duration;
  final int seats;
  final List<String> timeSlots;
  final DateTime createdAt;

  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.imageBase64,
    required this.duration,
    required this.seats,
    required this.timeSlots,
    required this.createdAt,
  });

  factory Movie.fromMap(Map<String, dynamic> data, String id) {
    return Movie(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageBase64: data['imageBase64'] ?? '',
      duration: data['duration'] ?? 0,
      seats: data['seats'] ?? 0,
      timeSlots: List<String>.from(data['timeSlots'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
