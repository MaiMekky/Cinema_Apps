import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/movies/movies_cubit.dart';
import '../cubit/movies/movies_state.dart';
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
      backgroundColor: AppColors.background, // dark navy
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isSmallScreen ? 70 : 90),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.background,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 10 : 12,
              ),
              child: Row(
                children: [
                  // Red circular icon like CineBook logo
                  Container(
                    width: isSmallScreen ? 44 : 50,
                    height: isSmallScreen ? 44 : 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935), // primary red accent
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_movies,
                      color: Colors.white,
                      size: isSmallScreen ? 22 : 26,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "CineBook Vendor",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 15 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        BlocBuilder<MoviesCubit, MoviesState>(
                          builder: (context, state) {
                            int count = 0;
                            if (state is MoviesLoaded) count = state.movies.length;
                            return Text(
                              "$count movies",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isSmallScreen ? 11 : 13,
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
                        icon: Icon(
                          Icons.notifications_none,
                          size: isSmallScreen ? 22 : 24,
                        ),
                        color: Colors.white,
                        padding:
                            EdgeInsets.all(isSmallScreen ? 4 : 6),
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationScreen()),
                          );
                        },
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddMovieScreen()),
                          );
                        },
                        icon: Icon(
                          Icons.add,
                          size: isSmallScreen ? 16 : 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          "Add",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935), // red button like login
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 14 : 20,
                            vertical: isSmallScreen ? 8 : 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
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
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.white70),
              ),
            );
          } else if (state is MoviesLoaded) {
            final movies = state.movies;
            if (movies.isEmpty) {
              return const Center(
                child: Text(
                  "No movies yet",
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
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
                          builder: (_) => BookingOverviewScreen(
                            movieId: movie.id,
                            movieModel: movie,
                          ),
                        ),
                      );
                    },
                    onDelete: () =>
                        context.read<MoviesCubit>().deleteMovie(movie.id),
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
