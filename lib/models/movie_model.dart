import 'package:cloud_firestore/cloud_firestore.dart';

class MovieModel {
  final String id;
  final String title;
  final String description;
  final String imageBase64; // <-- Base64 string
  final int duration;
  final List<String> timeSlots;
  final int seats;
  final Timestamp? createdAt;
  

  MovieModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageBase64,
    required this.duration,
    required this.timeSlots,
    this.seats = 47,
    this.createdAt,
  });

  factory MovieModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MovieModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageBase64: data['imageBase64'] ?? '',
      duration: (data['duration'] ?? 120) is int
          ? (data['duration'] ?? 120) as int
          : int.parse((data['duration'] ?? '120').toString()),
      timeSlots: List<String>.from(data['timeSlots'] ?? []),
      seats: (data['seats'] ?? 47) is int
          ? (data['seats'] ?? 47) as int
          : int.parse((data['seats'] ?? '47').toString()),
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'imageBase64': imageBase64, // <-- store Base64 here
        'duration': duration,
        'timeSlots': timeSlots,
        'seats': seats,
        'createdAt': FieldValue.serverTimestamp(),
      };

  MovieModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageBase64,
    int? duration,
    List<String>? timeSlots,
    int? seats,
    Timestamp? createdAt,
  }) {
    return MovieModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageBase64: imageBase64 ?? this.imageBase64,
      duration: duration ?? this.duration,
      timeSlots: timeSlots ?? this.timeSlots,
      seats: seats ?? this.seats,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
}
