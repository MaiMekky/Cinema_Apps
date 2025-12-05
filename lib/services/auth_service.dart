import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    // create user
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User user = result.user!;

    // save data in Firestore
    await _firestore.collection("users").doc(user.uid).set({
      "uid": user.uid,
      "name": name,
      "email": email,
      "createdAt": DateTime.now(),
    });

    return user;
  }
}
