// lib/screens/booking_overview_screen.dart
import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/movie_model.dart';
import '../services/movies_repository.dart';
import '../utils/app_colors.dart';
import 'dart:convert';

class BookingOverviewScreen extends StatefulWidget {
  final String movieId;
  final MovieModel movieModel;

  const BookingOverviewScreen({super.key, required this.movieId, required this.movieModel});

  @override
  State<BookingOverviewScreen> createState() => _BookingOverviewScreenState();
}

class _BookingOverviewScreenState extends State<BookingOverviewScreen> {
  late String selectedSlotDocId; // e.g. slot_1
  late String selectedSlotLabel;
  final MoviesRepository _repo = MoviesRepository();

  @override
  void initState() {
    super.initState();
    // default select first slot docId = slot_1
    selectedSlotDocId = 'slot_1';
    selectedSlotLabel = widget.movieModel.timeSlots.isNotEmpty ? widget.movieModel.timeSlots.first : '';
  }

  void onSlotChanged(int index) {
    setState(() {
      selectedSlotDocId = 'slot_${index + 1}';
      selectedSlotLabel = widget.movieModel.timeSlots[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalSeats = widget.movieModel.seats;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: const Text("Booking Overview")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.movieModel.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Booking Overview", style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 16),
              if (widget.movieModel.imageBase64.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Image.memory(
                      base64Decode(widget.movieModel.imageBase64),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              const Text("Select Time Slot", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(widget.movieModel.timeSlots.length, (i) {
                  final slotLabel = widget.movieModel.timeSlots[i];
                  final isSelected = slotLabel == selectedSlotLabel;
                  return GestureDetector(
                    onTap: () => onSlotChanged(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(color: isSelected ? AppColors.primary : Colors.grey[700], borderRadius: BorderRadius.circular(10)),
                      child: Text(slotLabel, style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          // seats card using stream
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Text("Seat Layout - $selectedSlotLabel", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Container(height: 40, margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.3), Colors.transparent], stops: const [0.0, 0.3, 0.5, 0.7, 1.0]),
                borderRadius: BorderRadius.circular(4),
              ), child: const Center(child: Text('S C R E E N', style: TextStyle(letterSpacing: 4)))), const SizedBox(height: 24),

              StreamBuilder<List<bool>>(
                stream: _repo.watchSeats(widget.movieId, selectedSlotDocId, totalSeats),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final seatStatus = snap.data!;
                  final booked = seatStatus.where((x) => x).length;
                  final available = totalSeats - booked;

                  return Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text("Booked Seats:", style: TextStyle(color: Colors.white70)), Text("$booked / $totalSeats", style: const TextStyle(color: Colors.redAccent, fontSize: 16)), ]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text("Available Seats:", style: TextStyle(color: Colors.white70)), Text("$available", style: const TextStyle(color: Colors.greenAccent, fontSize: 16)), ]),
                    const SizedBox(height: 20),
                    _buildSeatLayout(seatStatus),
                    const SizedBox(height: 16),
                    _buildLegend(),
                  ]);
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }

 Widget _buildSeatLayout(List<bool> seatStatus) {
  final rows = ["A", "B", "C", "D", "H"];
  final seatsPerRow = {"A": 9, "B": 9, "C": 9, "D": 9, "H": 11};
  int index = 0; // global seat index: 0..46

  return Column(
    children: rows.map((rowLetter) {
      final seatCount = seatsPerRow[rowLetter]!;
      final isLastRow = rowLetter == "H";

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    seatCount + (isLastRow ? 0 : 2),
                    (i) {
                      // middle gap for non‑last rows
                      if (!isLastRow && (i == 4 || i == 5)) {
                        return const SizedBox(width: 12);
                      }

                      int seatNum = i;
                      if (!isLastRow && i >= 6) {
                        seatNum -= 2;
                      }
                      if (seatNum >= seatCount) {
                        return const SizedBox.shrink();
                      }

                      // no more seats in status list
                      if (index >= seatStatus.length) {
                        return const SizedBox.shrink();
                      }

                      final isBooked = seatStatus[index];
                      final seatWidget = Container(
                        width: 25,
                        height: 25,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color:
                              isBooked ? Colors.redAccent : AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isBooked
                                ? Colors.redAccent
                                : Colors.white24,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          // GLOBAL NUMBERING: 1..47
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                              color: isBooked
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );

                      index++; // advance global index ONLY for real seats
                      return seatWidget;
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

  Widget _buildLegend() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Row(children: [ Container(width: 20, height: 20, decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 8), const Text('Available', style: TextStyle(color: Colors.white70)), ]),
      Row(children: [ Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 8), const Text('Booked', style: TextStyle(color: Colors.white70)), ]),
    ]);
  }
}
