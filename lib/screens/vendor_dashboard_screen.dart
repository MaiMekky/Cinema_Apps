import 'package:cinema_apps/screens/add_movie_screen.dart';
import 'package:cinema_apps/screens/booking_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';
import 'movie_form_screen.dart';
import '../utils/app_colors.dart';
import 'notification_screen.dart';

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
      description: "An epic space adventure following a crew of explorers as they venture into the...",
      imageUrl: "https://picsum.photos/200/300?1",
      duration: 120,
      timeSlots: ["10:00 AM", "1:00 PM", "4:00 PM", "7:00 PM"],
    ),
    Movie(
      id: const Uuid().v4(),
      title: "City Lights",
      description: "A heartwarming drama about finding connection in the big city. Follow the...",
      imageUrl: "https://picsum.photos/200/300?2",
      duration: 105,
      timeSlots: ["11:00 AM", "2:30 PM", "5:00 PM"],
    ),
  ];

  void openAddForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddMovieScreen()),
    );

    if (result is Movie) {
      setState(() => movies.add(result));
    }
  }

  void openEditForm(Movie movie) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieFormScreen(movie: movie),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.background,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: 16,
              ),
              child: Row(
                children: [
                  // Left side - Icon and text
                  Container(
                    width: isSmallScreen ? 48 : 56,
                    height: isSmallScreen ? 48 : 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.movie,
                      color: Colors.white,
                      size: isSmallScreen ? 24 : 28,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Vendor Dashboard",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: isSmallScreen ? 16 : 20,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${movies.length} movies",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right side - Notification icon + Add button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notification icon
                      IconButton(
                        icon: Icon(
                          Icons.notifications_none,
                          size: isSmallScreen ? 22 : 26,
                        ),
                        color: AppColors.textPrimary,
                        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      // Add button
                      ElevatedButton.icon(
                        onPressed: openAddForm,
                        icon: Icon(
                          Icons.add,
                          size: isSmallScreen ? 16 : 20,
                          color: Colors.white,
                        ),
                        label: Text(
                          "Add",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 24,
                            vertical: isSmallScreen ? 10 : 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: 8,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: MovieCard(
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
            ),
          );
        },
      ),
    );
  }
}