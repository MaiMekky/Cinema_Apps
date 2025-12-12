import 'package:cloud_firestore/cloud_firestore.dart';

class Slot {
  final String id;
  final String label;
  final DateTime createdAt;

  Slot({
    required this.id,
    required this.label,
    required this.createdAt,
  });

  factory Slot.fromMap(Map<String, dynamic> data, String id) {
    return Slot(
      id: id,
      label: data['label'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
