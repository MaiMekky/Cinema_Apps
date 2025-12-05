import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    // Create account in Authentication
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = cred.user!.uid;

    // Create user document inside Firestore
    await _db.collection("users").doc(uid).set({
      "uid": uid,
      "fullName": name,
      "email": email,
      "createdAt": DateTime.now(),
    });
  }
}
