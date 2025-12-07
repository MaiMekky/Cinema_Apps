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

            // TOP CARD ----------------------------------------------
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Movie name
                  Text(
                    widget.movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),
                  const Text("Booking Overview",
                      style: TextStyle(color: Colors.white60)),

                  const SizedBox(height: 16),

                  // FIXED-SIZE IMAGE (NO STRETCHING)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Image.network(
                        widget.movie.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text("Select Time Slot",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),

                  // Time Slots
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.movie.timeSlots.map((slot) {
                      bool isSelected = slot == selectedSlot;
                      return GestureDetector(
                        onTap: () => setState(() => selectedSlot = slot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey[700],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            slot,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Booked Seats:",
                          style: TextStyle(color: Colors.white70)),
                      Text("$booked / $totalSeats",
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 16)),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Available Seats:",
                          style: TextStyle(color: Colors.white70)),
                      Text("$available",
                          style: const TextStyle(
                              color: Colors.greenAccent, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SEAT LAYOUT CARD -------------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    "Seat Layout - $selectedSlot",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),

                  // SCREEN BANNER
                  Container(
                    height: 35,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.6),
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "S C R E E N",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // SEATS (CUSTOM ROW LAYOUT LIKE CUSTOMER APP)
                  buildSeatLayout(),

                  const SizedBox(height: 24),

                  // LEGEND
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SeatLegend(color: Colors.grey, label: "Available"),
                      SizedBox(width: 24),
                      SeatLegend(color: Colors.redAccent, label: "Booked"),
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

  // =============================================================
  // FINAL PERFECT SEAT LAYOUT (same style as customer version)
  // =============================================================
  Widget buildSeatLayout() {
    final rows = ["A", "B", "C", "D", "E", "F"];
    final seatsPerRow = [8, 8, 8, 8, 8, 7]; // total = 47

    int index = 0;

    return Column(
      children: [
        for (int r = 0; r < rows.length; r++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Row label
                Text(
                  rows[r],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),

                // Seats in this row
                Row(
                  children: List.generate(seatsPerRow[r], (seatIndex) {
                    // String seatId = "${rows[r]}${seatIndex + 1}";
                    bool booked = seatStatus[index];

                    Widget seatWidget = GestureDetector(
                      onTap: () => toggleSeat(index),
                      child: Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: booked
                              ? Colors.redAccent
                              : Colors.grey[700],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: booked
                                ? Colors.red
                                : Colors.white24,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.event_seat,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    );

                    index++;
                    return seatWidget;
                  }),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// LEGEND ---------------------------------------------------------
class SeatLegend extends StatelessWidget {
  final Color color;
  final String label;

  const SeatLegend({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}