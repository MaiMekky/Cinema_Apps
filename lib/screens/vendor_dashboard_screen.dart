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
                          // ✅ CHANGE THIS:
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddMovieScreen(),
                            ),
                          );
                          
                          // ✅ ADD THIS: Show snackbar when returning from AddMovieScreen
                      if (result == 'movie_added') {
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                                content: Row(
                                  children: [
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '"Movie added successfully!',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const Icon(Icons.check_circle, color: Colors.white),
                                  ],
                                ),
                                backgroundColor: const Color(0xFFE53914),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.only(top: 80, left: 16, right: 16),
                              ),
                        );
                      }
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
      body: BlocListener<MoviesCubit, MoviesState>(
        listener: (context, state) {
          if (state is MoviesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(child: Text('Delete failed: ${state.message}', style: const TextStyle(fontSize: 15))),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(top: 80, left: 16, right: 16),
              ),
            );
          }
        },
        child: BlocBuilder<MoviesCubit, MoviesState>(
          builder: (context, state) {
            if (state is MoviesLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)));
            } else if (state is MoviesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white70, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<MoviesCubit>().watchAll(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                      ),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            } else if (state is MoviesLoaded) {
              final movies = state.movies;
              if (movies.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.movie_outlined, color: Colors.white70, size: 80),
                      const SizedBox(height: 16),
                      const Text(
                        "No movies yet",
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Add your first movie to get started",
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ],
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
                      onDelete: () {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const SizedBox(width: 12),
                                Expanded(child: Text('Deleting "${movie.title}"...', style: const TextStyle(fontSize: 15))),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(top: 80, left: 16, right: 16),
                          ),
                        );
                        
                        context.read<MoviesCubit>().deleteMovie(movie.id);
                        
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '"${movie.title}" deleted successfully!',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const Icon(Icons.check_circle, color: Colors.white),
                                  ],
                                ),
                                backgroundColor: const Color(0xFFE53914),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.only(top: 80, left: 16, right: 16),
                              ),
                            );
                          }
                        });
                      },
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
