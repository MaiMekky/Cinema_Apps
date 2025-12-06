import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static Future<String> getUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return "User";

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    return doc.data()?['name'] ?? "User";
  }
}
