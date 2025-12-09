import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../utils/app_colors.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MovieCard({
    super.key,
    required this.movie,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final isMediumScreen = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                movie.imageUrl,
                width: isSmallScreen ? 100 : (isMediumScreen ? 120 : 140),
                height: isSmallScreen ? 160 : (isMediumScreen ? 180 : 200),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: isSmallScreen ? 100 : (isMediumScreen ? 120 : 140),
                    height: isSmallScreen ? 140 : (isMediumScreen ? 160 : 180),
                    color: AppColors.background,
                    child: Icon(
                      Icons.movie,
                      color: AppColors.textSecondary,
                      size: isSmallScreen ? 40 : 50,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            // Movie Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    movie.title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  // Description
                  Text(
                    movie.description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: isSmallScreen ? 12 : 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  // Duration and Slots
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.textSecondary,
                        size: isSmallScreen ? 14 : 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${movie.duration} min",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: isSmallScreen ? 11 : 13,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.textSecondary,
                        size: isSmallScreen ? 14 : 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${movie.timeSlots.length} slots",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: isSmallScreen ? 11 : 13,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  // Action Buttons
                  Row(
                    children: [
                      // View Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onView,
                          icon: Icon(
                            Icons.remove_red_eye,
                            size: isSmallScreen ? 16 : 18,
                            color: Colors.white,
                          ),
                          label: Text(
                            "View",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 13 : 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      // Edit Button
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        color: AppColors.textSecondary,
                        iconSize: isSmallScreen ? 18 : 20,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.buttonBackground,
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      // Delete Button
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        color: AppColors.textSecondary,
                        iconSize: isSmallScreen ? 18 : 20,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.buttonBackground,
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}