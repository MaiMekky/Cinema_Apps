import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/movie.dart';
import '../../models/seat.dart';
import '../../models/screening.dart';
import '../../services/booking_service.dart';
import '../../utils/app_colors.dart';

class BookingPage extends StatefulWidget {
  final String movieId;

  const BookingPage({super.key, required this.movieId});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  Movie? _movie;
  List<Screening> _screenings = [];
  Screening? _selectedScreening;
  final List<String> _selectedSeats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final movie = await BookingService.getMovie(widget.movieId);
      final screenings = await BookingService.getScreenings(widget.movieId);

      setState(() {
        _movie = movie;
        _screenings = screenings;
        _selectedScreening = screenings.isNotEmpty ? screenings[0] : null;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading booking data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectScreening(Screening screening) {
    setState(() {
      _selectedScreening = screening;
      _selectedSeats.clear();
    });
  }

  void _toggleSeat(String seatId) {
    setState(() {
      if (_selectedSeats.contains(seatId)) {
        _selectedSeats.remove(seatId);
      } else {
        _selectedSeats.add(seatId);
      }
    });
  }

  Future<void> _confirmBooking() async {
    if (_selectedScreening == null || _selectedSeats.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book seats')),
      );
      return;
    }

    try {
      await BookingService.bookSeats(
        movieId: widget.movieId,
        screeningId: _selectedScreening!.id,
        seatIds: _selectedSeats,
        userId: user.uid,
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text(
            'Booking Confirmed!',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            'You have successfully booked ${_selectedSeats.length} seat(s) for ${_movie?.title}\n\nTime: ${_formatTime(_selectedScreening!.startTime)}\nSeats: ${_selectedSeats.join(', ')}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Tickets',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(_movie!.posterUrl),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),

            Text(
              _movie!.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _movie!.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.schedule, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_movie!.duration),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 24),
                const Icon(Icons.movie, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_screenings.length} showtimes',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Divider(color: AppColors.card),

            const SizedBox(height: 16),
            const Text(
              'Select Showtime',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: _screenings.map((screening) {
                final isSelected = _selectedScreening?.id == screening.id;
                return GestureDetector(
                  onTap: () => _selectScreening(screening),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: Colors.red, width: 2) : null,
                    ),
                    child: Center(
                      child: Text(
                        _formatTime(screening.startTime),
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            if (_selectedScreening != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Seats:',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_selectedScreening!.availableSeats} / 47',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              'Select Your Seats',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  'S C R E E N',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            if (_selectedScreening != null)
              _buildSeatGrid(_selectedScreening!.seats),

            const SizedBox(height: 32),

            _buildLegend(),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedSeats.isEmpty ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[700],
                ),
                child: Text(
                  _selectedSeats.isEmpty
                      ? 'Select Seats to Book'
                      : 'Book ${_selectedSeats.length} Seat(s) - \$${_selectedSeats.length * 15}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSeatGrid(Map<String, Seat> seats) {
    final rows = <String, List<Seat>>{};

    for (var seat in seats.values) {
      final row = seat.id[0];
      rows.putIfAbsent(row, () => []);
      rows[row]!.add(seat);
    }

    final sortedRows = rows.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (var row in sortedRows) {
      row.value.sort((a, b) {
        final aNum = int.tryParse(a.id.substring(1)) ?? 0;
        final bNum = int.tryParse(b.id.substring(1)) ?? 0;
        return aNum.compareTo(bNum);
      });
    }

    return Center(
      child: Column(
        children: sortedRows.asMap().entries.map((rowEntry) {
          final rowIndex = rowEntry.key;
          final rowLetter = rowEntry.value.key;
          final rowSeats = rowEntry.value.value;
          final isLastRow = rowIndex == sortedRows.length - 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Text(
                  rowLetter,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    rowSeats.length + (isLastRow ? 0 : 2),
                    (index) {
                      if (!isLastRow) {
                        if (index < 4) {
                          final seat = rowSeats[index];
                          final isSelected = _selectedSeats.contains(seat.id);
                          final isBooked = seat.booked;

                          return _buildSeatWidget(
                            seat: seat,
                            isSelected: isSelected,
                            isBooked: isBooked,
                          );
                        } else if (index == 4 || index == 5) {
                          return const SizedBox(width: 29);
                        } else {
                          final seatIndex = index - 2;
                          final seat = rowSeats[seatIndex];
                          final isSelected = _selectedSeats.contains(seat.id);
                          final isBooked = seat.booked;

                          return _buildSeatWidget(
                            seat: seat,
                            isSelected: isSelected,
                            isBooked: isBooked,
                          );
                        }
                      } else {
                        final seat = rowSeats[index];
                        final isSelected = _selectedSeats.contains(seat.id);
                        final isBooked = seat.booked;

                        return _buildSeatWidget(
                          seat: seat,
                          isSelected: isSelected,
                          isBooked: isBooked,
                        );
                      }
                    },
                  ),
                ),

                if (rowLetter == 'F') const SizedBox(height: 24),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSeatWidget({
    required Seat seat,
    required bool isSelected,
    required bool isBooked,
  }) {
    return GestureDetector(
      onTap: isBooked ? null : () => _toggleSeat(seat.id),
      child: Container(
        width: 25,
        height: 25,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isBooked
              ? Colors.grey[700]
              : isSelected
              ? Colors.red
              : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.red, width: 2)
              : isBooked
              ? Border.all(color: Colors.grey.shade600, width: 1)
              : Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Center(
          child: Text(
            seat.id.substring(1),
            style: TextStyle(
              color: isBooked
                  ? Colors.grey[400]
                  : isSelected
                  ? Colors.white
                  : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Selected',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Booked',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
