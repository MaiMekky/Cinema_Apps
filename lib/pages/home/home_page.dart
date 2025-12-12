// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/movie.dart';
import '../../utils/app_colors.dart';
import 'movie_card.dart';
import '../auth/login_page.dart';
import '../booking/booking_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Movie> movies = [];
  List<Movie> filtered = [];
  String userName = "User";

  @override
  void initState() {
    super.initState();
    loadMovies();
    loadUserName();
  }

  Future<void> loadMovies() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('movies')
        .orderBy('createdAt', descending: true)
        .get();

    final loaded = snapshot.docs.map((doc) {
      final data = doc.data();

      return Movie(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        duration: data['duration'] ?? 0,
        seats: data['seats'] ?? 0,
        imageBase64: data['imageBase64'] ?? '',
        timeSlots: List<String>.from(data['timeSlots'] ?? []),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }).toList();

    setState(() {
      movies = loaded;
      filtered = loaded;
    });
  }

  Future<void> loadUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final data =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    setState(() {
      userName = data.data()?['fullName'] ?? "User";
    });
  }

  void search(String value) {
    setState(() {
      filtered = movies
          .where((m) => m.title.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // HEADER BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.movie, color: Colors.red, size: 28),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "CineBook",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Welcome, $userName",
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: () async {
                      try {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        print("Logout error: $e");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Logout failed: $e")),
                          );
                        }
                      }
                    },
                    child: const Icon(
                      Icons.logout,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // SEARCH BAR
              TextField(
                onChanged: search,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.card,
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  hintText: 'Search for movies...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Latest Movies",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          "No movies found",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: MovieCard(
                              movie: filtered[index],
                              onBook: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookingPage(movieId: filtered[index].id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
