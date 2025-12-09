import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../utils/app_colors.dart';

class BookingOverviewScreen extends StatefulWidget {
  final Movie movie;

  const BookingOverviewScreen({super.key, required this.movie});

  @override
  State<BookingOverviewScreen> createState() => _BookingOverviewScreenState();
}

class _BookingOverviewScreenState extends State<BookingOverviewScreen> {
  String selectedSlot = "";
  int totalSeats = 47;

  // false = available , true = booked
  List<bool> seatStatus = [];

  @override
  void initState() {
    super.initState();
    selectedSlot = widget.movie.timeSlots.first;
    seatStatus = List.generate(totalSeats, (_) => false);
  }

  void toggleSeat(int index) {
    setState(() => seatStatus[index] = !seatStatus[index]);
  }

  @override
  Widget build(BuildContext context) {
    int booked = seatStatus.where((x) => x).length;
    int available = totalSeats - booked;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("Booking Overview"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // TOP CARD ----------------------------
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text("Booking Overview", style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Image.network(widget.movie.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Select Time Slot", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.movie.timeSlots.map((slot) {
                      bool isSelected = slot == selectedSlot;
                      return GestureDetector(
                        onTap: () => setState(() => selectedSlot = slot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.grey[700],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(slot, style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Booked Seats:", style: TextStyle(color: Colors.white70)),
                      Text("$booked / $totalSeats", style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Available Seats:", style: TextStyle(color: Colors.white70)),
                      Text("$available", style: const TextStyle(color: Colors.greenAccent, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SEAT LAYOUT CARD ---------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text("Seat Layout - $selectedSlot", style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),

                  // SCREEN BANNER
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
                  buildSeatLayout(),
                  const SizedBox(height: 32),
                  _buildLegend(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // Total = 47
  // =============================================================
  Widget buildSeatLayout() {
    final rows = ["A", "B", "C", "D", "H"];

    // EXACT CUSTOMER LAYOUT
    final seatsPerRow = {
      "A": 9, // 4 + 5
      "B": 9,
      "C": 9,
      "D": 9,
      "H": 11, // last row, no gap
    };

    int index = 0;

    return Center(
      child: Column(
        children: rows.map((rowLetter) {
          final seatCount = seatsPerRow[rowLetter]!;
          final isLastRow = rowLetter == "H";

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rowLetter,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  children: List.generate(
                    seatCount + (isLastRow ? 0 : 2), // +2 for gap positions
                    (i) {
                      // GAP after 4th seat (positions 4 and 5)
                      if (!isLastRow && (i == 4 || i == 5)) {
                        return const SizedBox(width: 29);
                      }

                      int seatNum = i;
                      if (!isLastRow && i >= 6) {
                        seatNum -= 2;
                      }

                      if (seatNum >= seatCount) return const SizedBox.shrink();

                      bool isBooked = seatStatus[index];

                      final widget = GestureDetector(
                        onTap: () => toggleSeat(index),
                        child: Container(
                          width: 25,
                          height: 25,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isBooked ? Colors.redAccent : AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isBooked ? Colors.redAccent : Colors.white24,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "${seatNum + 1}",
                              style: TextStyle(
                                color: isBooked ? Colors.white : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );

                      index++;
                      return widget;
                    },
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
            const Text('Available', style: TextStyle(color: Colors.white70)),
          ],
        ),
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Booked', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    );
  }
}