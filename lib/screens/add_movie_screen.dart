// lib/screens/add_movie_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/add_movie/add_movie_cubit.dart';
import '../cubit/add_movie/add_movie_state.dart';
import '../utils/app_colors.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class AddMovieScreen extends StatefulWidget {
  const AddMovieScreen({super.key});

  @override
  State<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends State<AddMovieScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController title = TextEditingController();
  TextEditingController desc = TextEditingController();
  TextEditingController duration = TextEditingController(text: "120");
  TextEditingController seats = TextEditingController(text: "47");
  List<TextEditingController> slots = [TextEditingController()];
  File? selectedImage;
  Uint8List? webImage;

  Future pickFromGallery() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img != null) {
      if (kIsWeb) {
        webImage = await img.readAsBytes();
      } else {
        selectedImage = File(img.path);
      }
      setState(() {});
    }
  }

  bool saveMovie() {
    if (selectedImage == null && webImage == null) {
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        const SizedBox(width: 12),
        Expanded(child: Text("Please upload movie image", style: const TextStyle(fontSize: 15))),
        Icon(Icons.close, color: Colors.white),
      ],
    ),
    backgroundColor: Colors.red,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.only(top: 80, left: 16, right: 16),
  ),
);

      return false;
    }

    if (!_formKey.currentState!.validate()) return false;

    final slotsList = slots
        .map((e) => e.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    context.read<AddMovieCubit>().addMovie(
      title: title.text.trim(),
      description: desc.text.trim(),
      imageFile: selectedImage,
      webImage: webImage,
      duration: int.tryParse(duration.text.trim()) ?? 120,
      timeSlots: slotsList,
    );

    return true;
  }

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Add New Movie"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body:BlocListener<AddMovieCubit, AddMovieState>(
  listener: (context, state) {
    if (state is AddMovieLoading) {

    } else if (state is AddMovieSuccess) {

      Navigator.pop(context, 'movie_added');
    } else if (state is AddMovieFailure) {
  
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(child: Text(state.message, style: const TextStyle(fontSize: 15))),
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

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Movie Image *",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: imageButton(
                        "Upload Image",
                        Icons.upload,
                        pickFromGallery,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                if ((selectedImage != null) || (webImage != null))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: kIsWeb
                          ? Image.memory(webImage!, fit: BoxFit.cover)
                          : Image.file(selectedImage!, fit: BoxFit.cover),
                    ),
                  ),

                const SizedBox(height: 26),
                label("Movie Title *"),
                input(title, "Enter movie title"),
                const SizedBox(height: 22),
                label("Description *"),
                input(desc, "Enter movie description", max: 3),
                const SizedBox(height: 22),
                label("Movie Duration (minutes) *"),
                input(duration, "120", keyboard: TextInputType.number),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    label("Time Slots (Max 5)"),
                    GestureDetector(
                      onTap: slots.length < 5
                          ? () => setState(
                              () => slots.add(TextEditingController()),
                            )
                          : null,
                      child: const Text(
                        "+ Add Slot",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ✅ FIX: Added spacing between time slots using ListView.separated
                ListView.separated(
                  shrinkWrap: true, // Important: allows ListView inside Column
                  physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                  itemCount: slots.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12), // ✅ Space between slots
                  itemBuilder: (context, i) => Row(
                    children: [
                      Expanded(child: input(slots[i], "10:00 AM")),
                      IconButton(
                        onPressed: () => setState(() => slots.removeAt(i)),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                label("Number of Seats"),
                input(seats, "47", keyboard: TextInputType.number, enabled: false),
                const SizedBox(height: 35),
                Row(
                  children: [
                    Expanded(child: cancelBtn()),
                    const SizedBox(width: 14),
                    Expanded(child: addBtn()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget input(
    TextEditingController c,
    String h, {
    int max = 1,
    keyboard = TextInputType.text,
     bool enabled = true,
  }) => TextFormField(
    controller: c,
    maxLines: max,
    keyboardType: keyboard,
     enabled: enabled,
    validator: (v) => v!.isEmpty ? "Required" : null,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      filled: true,
      fillColor: const Color(0xff121C29),
      hintText: h,
      hintStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget imageButton(String text, IconData icon, Function() action) =>
      GestureDetector(
        onTap: action,
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white70),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );

  Widget label(text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget cancelBtn() => OutlinedButton(
    onPressed: () => Navigator.pop(context),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.white70, width: 1.3),
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    child: const Text(
      "Cancel",
      style: TextStyle(color: Colors.white70, fontSize: 15),
    ),
  );

Widget addBtn() => BlocBuilder<AddMovieCubit, AddMovieState>(
  builder: (context, state) {
    return ElevatedButton(
onPressed: state is AddMovieLoading 
    ? null 
    : () => saveMovie(),
      style: ElevatedButton.styleFrom(
        backgroundColor: state is AddMovieLoading 
            ? Colors.grey 
            : const Color(0xFFE53914),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: state is AddMovieLoading
          ? const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))
            )
          : const Text(
              "Add Movie",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
    );
  },
);

}