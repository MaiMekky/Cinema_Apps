import 'package:cinema_apps/screens/booking_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';
import 'movie_form_screen.dart';
import '../utils/app_colors.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final List<Movie> movies = [
    Movie(
      id: const Uuid().v4(),
      title: "The Dark Universe",
      description: "An epic space adventure...",
      imageUrl: "https://picsum.photos/200/300?1",
      duration: 120,
      timeSlots: ["10:00 AM", "1:00 PM", "4:00 PM", "7:00 PM"],
    ),
    Movie(
      id: const Uuid().v4(),
      title: "City Lights",
      description: "A heartwarming drama...",
      imageUrl: "https://picsum.photos/200/300?2",
      duration: 105,
      timeSlots: ["11:00 AM", "2:30 PM", "5:00 PM"],
    ),
  ];

  void openAddForm() async {
    final result = await Navigator.push(
      context,
     MaterialPageRoute(builder: (_) => MovieFormScreen()),
    );

    if (result is Movie) {
      setState(() => movies.add(result));
    }
  }

  void openEditForm(Movie movie) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieFormScreen(movie: movie),   // IMPORTANT
      ),
    );

    if (result is Movie) {
      setState(() {
        final index = movies.indexWhere((m) => m.id == movie.id);
        movies[index] = result;
      });
    }
  }

  void deleteMovie(String id) {
    setState(() => movies.removeWhere((m) => m.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.movie, color: AppColors.primary, size: 30),
            const SizedBox(width: 12),
            const Text("Vendor Dashboard"),
            const SizedBox(width: 8),
            Text(
              "(${movies.length} movies)",
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: openAddForm,
              icon: const Icon(Icons.add),
              label: const Text("Add"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: movies.map((movie) {
          return MovieCard(
            movie: movie,
            onView: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingOverviewScreen(movie: movie),
              ),
            );
          },
            onEdit: () => openEditForm(movie),
            onDelete: () => deleteMovie(movie.id),
          );
        }).toList(),
      ),
    );
  }
}