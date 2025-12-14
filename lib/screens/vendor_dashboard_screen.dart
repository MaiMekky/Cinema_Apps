// lib/screens/vendor_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/movies/movies_cubit.dart';
import '../cubit/movies/movies_state.dart';
// import '../models/movie_model.dart';
import '../widgets/movie_card.dart';
import '../utils/app_colors.dart';
import 'add_movie_screen.dart';
import 'booking_overview_screen.dart';

import 'notification_screen.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        // ✅ FIX: Increased height to accommodate content
        preferredSize: Size.fromHeight(isSmallScreen ? 90 : 100),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.background,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 10 : 12, // ✅ FIX: Reduced vertical padding
              ),
              child: Row(
                children: [
                  Container(
                    width: isSmallScreen ? 44 : 50, // ✅ FIX: Slightly smaller
                    height: isSmallScreen ? 44 : 50, // ✅ FIX: Slightly smaller
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.movie, color: Colors.white, size: isSmallScreen ? 22 : 26),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // ✅ FIX: Added to prevent column from expanding
                      children: [
                        Text(
                          "Vendor Dashboard",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: isSmallScreen ? 15 : 18, // ✅ FIX: Slightly smaller font
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis, // ✅ FIX: Prevent text overflow
                        ),
                        const SizedBox(height: 2), // ✅ FIX: Reduced spacing
                        BlocBuilder<MoviesCubit, MoviesState>(
                          builder: (context, state) {
                            int count = 0;
                            if (state is MoviesLoaded) count = state.movies.length;
                            return Text(
                              "$count movies",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: isSmallScreen ? 11 : 13, // ✅ FIX: Slightly smaller
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_none, size: isSmallScreen ? 22 : 24),
                        color: AppColors.textPrimary,
                        padding: EdgeInsets.all(isSmallScreen ? 4 : 6), // ✅ FIX: Reduced padding
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationScreen()),
                          );
                        },
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // open add screen
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddMovieScreen()),
                          );
                        },
                        icon: Icon(Icons.add, size: isSmallScreen ? 16 : 18, color: Colors.white),
                        label: Text(
                          "Add",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 13 : 14, // ✅ FIX: Slightly smaller
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 14 : 20, // ✅ FIX: Reduced padding
                            vertical: isSmallScreen ? 8 : 10, // ✅ FIX: Reduced padding
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
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
      body: BlocBuilder<MoviesCubit, MoviesState>(
        builder: (context, state) {
          if (state is MoviesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MoviesError) {
            return Center(child: Text(state.message));
          } else if (state is MoviesLoaded) {
            final movies = state.movies;
            if (movies.isEmpty) return const Center(child: Text("No movies yet"));
            return ListView.builder(
              padding: const EdgeInsets.all(16), // ✅ Add padding around the list
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16), // ✅ Space between cards
                  child: MovieCard(
                    movie: movie,
                    onView: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingOverviewScreen(
                            movieId: movie.id,
                            movieModel: movie,
                          ),
                        ),
                      );
                    },
                    onDelete: () => context.read<MoviesCubit>().deleteMovie(movie.id),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}