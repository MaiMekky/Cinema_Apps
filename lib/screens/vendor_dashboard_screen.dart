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
                  Container(
                    width: isSmallScreen ? 48 : 56,
                    height: isSmallScreen ? 48 : 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.movie, color: Colors.white, size: isSmallScreen ? 24 : 28),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Vendor Dashboard",
                          style: TextStyle(color: AppColors.textPrimary, fontSize: isSmallScreen ? 16 : 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        BlocBuilder<MoviesCubit, MoviesState>(
                          builder: (context, state) {
                            int count = 0;
                            if (state is MoviesLoaded) count = state.movies.length;
                            return Text("$count movies",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: isSmallScreen ? 12 : 14),
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
                        icon: Icon(Icons.notifications_none, size: isSmallScreen ? 22 : 26),
                        color: AppColors.textPrimary,
                        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                        constraints: const BoxConstraints(),
                        onPressed: () async{
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
                        icon: Icon(Icons.add, size: isSmallScreen ? 16 : 20, color: Colors.white),
                        label: Text("Add", style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24, vertical: isSmallScreen ? 10 : 14),
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
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return MovieCard(
                  movie: movie,
                  onView: () {Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingOverviewScreen( movieId: movie.id,movieModel: movie,),
                  ),
                );},
                  onDelete: () => context.read<MoviesCubit>().deleteMovie(movie.id),
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
