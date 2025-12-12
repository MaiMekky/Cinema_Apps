import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/movie.dart';
import '../../models/seat.dart';
import '../../models/slot.dart';
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
  List<Slot> _slots = [];
  Slot? _selectedSlot;
  Map<String, Seat> _seats = {};
  final List<String> _selectedSeats = [];
  bool _isLoading = true;
  StreamSubscription? _seatsSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _seatsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final movie = await BookingService.getMovie(widget.movieId);
      final slots = await BookingService.getSlots(widget.movieId);
      
      setState(() {
        _movie = movie;
        _slots = slots;
        _selectedSlot = slots.isNotEmpty ? slots[0] : null;
        _isLoading = false;
      });

      if (_selectedSlot != null) {
        _loadSeats(_selectedSlot!.id);
      }
    } catch (e) {
      print("Error loading booking data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadSeats(String slotId) {
    // Cancel previous subscription
    _seatsSubscription?.cancel();
    
    // Get initial seats
    BookingService.getSeats(widget.movieId, slotId).then((seats) {
      if (mounted) {
        setState(() {
          _seats = seats;
          _selectedSeats.clear();
        });
      }
    });

    // Listen for real-time updates
    _seatsSubscription = BookingService.listenToSeats(widget.movieId, slotId).listen((seats) {
      if (mounted) {
        setState(() {
          _seats = seats;
          // Remove any selected seats that are now booked
          _selectedSeats.removeWhere((seatId) => seats[seatId]?.booked == true);
        });
      }
    });
  }

  void _selectSlot(Slot slot) {
    if (_selectedSlot?.id != slot.id) {
      setState(() {
        _selectedSlot = slot;
        _selectedSeats.clear();
      });
      _loadSeats(slot.id);
    }
  }

  void _toggleSeat(String seatId) {
    final seat = _seats[seatId];
    if (seat == null || seat.booked) return;

    setState(() {
      if (_selectedSeats.contains(seatId)) {
        _selectedSeats.remove(seatId);
      } else {
        _selectedSeats.add(seatId);
      }
    });
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null || _selectedSeats.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book seats')),
      );
      return;
    }

    try {
      // Check availability first
      final isAvailable = await BookingService.checkSeatsAvailability(
        movieId: widget.movieId,
        slotId: _selectedSlot!.id,
        seatIds: _selectedSeats,
      );

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Some seats are no longer available. Please select different seats.')),
        );
        return;
      }

      // Use transaction for safer booking
      await BookingService.bookSeatsWithTransaction(
        movieId: widget.movieId,
        slotId: _selectedSlot!.id,
        seatIds: _selectedSeats,
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
            'You have successfully booked ${_selectedSeats.length} seat(s) for ${_movie?.title}\n\nTime: ${_selectedSlot?.label}\nSeats: ${_selectedSeats.join(', ')}',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }

  // Calculate available seats
  int get _availableSeats {
    return _seats.values.where((seat) => !seat.booked).length;
  }

  // Format seat layout based on seat numbers
  Map<String, List<Seat>> _organizeSeatsByRow() {
    final rows = <String, List<Seat>>{};
    
    for (var seat in _seats.values) {
      // Extract row letter and seat number
      final seatNumber = int.tryParse(seat.id);
      if (seatNumber != null) {
        // Determine row based on seat number
        String rowLetter;
        if (seatNumber <= 9) rowLetter = 'A';
        else if (seatNumber <= 18) rowLetter = 'B';
        else if (seatNumber <= 27) rowLetter = 'C';
        else if (seatNumber <= 36) rowLetter = 'D';
        else if (seatNumber <= 45) rowLetter = 'E';
        else if (seatNumber <= 54) rowLetter = 'F';
        else if (seatNumber <= 63) rowLetter = 'G';
        else rowLetter = 'H';
        
        rows.putIfAbsent(rowLetter, () => []);
        rows[rowLetter]!.add(seat);
      }
    }
    
    // Sort seats within each row
    for (var row in rows.values) {
      row.sort((a, b) {
        final aNum = int.tryParse(a.id) ?? 0;
        final bNum = int.tryParse(b.id) ?? 0;
        return aNum.compareTo(bNum);
      });
    }
    
    return rows;
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

    if (_movie == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Movie not found',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
          ),
        ),
      );
    }

    final seatRows = _organizeSeatsByRow();
    final sortedRowLetters = seatRows.keys.toList()..sort();

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
            // Movie poster
            Container(
              height: 220,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(_movie!.imageBase64),
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

            // Movie title
            Text(
              _movie!.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Movie description
            Text(
              _movie!.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            
            // Movie details
            Row(
              children: [
                const Icon(Icons.schedule, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_movie!.duration} min',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 24),
                const Icon(Icons.event_seat, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_movie!.seats} seats',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Divider(color: AppColors.card),

            // Time slots
            const SizedBox(height: 16),
            const Text(
              'Select Time Slot',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _slots.map((slot) {
                final isSelected = _selectedSlot?.id == slot.id;
                return GestureDetector(
                  onTap: () => _selectSlot(slot),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: Colors.red, width: 2) : null,
                    ),
                    child: Text(
                      slot.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            if (_selectedSlot != null) ...[
              // Available seats count
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
                      '$_availableSeats / ${_movie!.seats}',
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

            // Seat selection
            const Text(
              'Select Your Seats',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Screen indicator
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

            // Seat grid
            if (_seats.isNotEmpty)
              _buildSeatGrid(seatRows, sortedRowLetters),
            if (_seats.isEmpty)
              const Center(
                child: Text(
                  'No seats available for this time slot',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),

            const SizedBox(height: 32),

            // Legend
            _buildLegend(),

            const SizedBox(height: 40),

            // Book button
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

  Widget _buildSeatGrid(Map<String, List<Seat>> seatRows, List<String> rowLetters) {
    return Column(
      children: rowLetters.map((rowLetter) {
        final rowSeats = seatRows[rowLetter] ?? [];
        final isWideRow = rowLetter == 'H'; // H row has 11 seats
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Row label
              Text(
                rowLetter,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),

              // Seats with aisle gap for rows A-G
              if (!isWideRow)
                Row(
                  children: [
                    // Left section (seats 1-4)
                    Row(
                      children: rowSeats.take(4).map((seat) {
                        return _buildSeatWidget(seat);
                      }).toList(),
                    ),
                    
                    // Aisle gap
                    const SizedBox(width: 29),
                    
                    // Right section (seats 5-9)
                    Row(
                      children: rowSeats.skip(4).map((seat) {
                        return _buildSeatWidget(seat);
                      }).toList(),
                    ),
                  ],
                )
              else
                // Row H - all seats in one line (11 seats)
                Row(
                  children: rowSeats.map((seat) {
                    return _buildSeatWidget(seat);
                  }).toList(),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeatWidget(Seat seat) {
    final isSelected = _selectedSeats.contains(seat.id);
    final isBooked = seat.booked;

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
            seat.id, // Shows the seat number (1, 2, 3, etc.)
            style: TextStyle(
              color: isBooked
                  ? Colors.grey[400]
                  : isSelected
                      ? Colors.white
                      : AppColors.textPrimary,
              fontSize: 10,
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
