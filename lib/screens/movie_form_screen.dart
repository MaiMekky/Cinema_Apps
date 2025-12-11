import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/movie_model.dart';
import '../utils/app_colors.dart';

class MovieFormScreen extends StatefulWidget {
  final MovieModel? movie;

  const MovieFormScreen({super.key, this.movie});

  @override
  State<MovieFormScreen> createState() => _MovieFormScreenState();
}

class _MovieFormScreenState extends State<MovieFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _imageController = TextEditingController();
  final _durationController = TextEditingController();
  final List<TextEditingController> _slotControllers = [];

  bool get isEdit => widget.movie != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      final m = widget.movie!;
      _titleController.text = m.title;
      _descController.text = m.description;
      _imageController.text = m.imageBase64;
      _durationController.text = m.duration.toString();

      for (var slot in m.timeSlots) {
        _slotControllers.add(TextEditingController(text: slot));
      }
    } else {
      _durationController.text = "120";
      _slotControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _imageController.dispose();
    _durationController.dispose();
    for (var c in _slotControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void saveForm() {
    if (!_formKey.currentState!.validate()) return;

    final movie = MovieModel(
      id: isEdit ? widget.movie!.id : const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      imageBase64: _imageController.text.trim(),
      duration: int.parse(_durationController.text.trim()),
      timeSlots: _slotControllers.map((c) => c.text.trim()).toList(),
    );

    Navigator.pop(context, movie);
  }

  void addSlot() {
    if (_slotControllers.length < 5) {
      setState(() => _slotControllers.add(TextEditingController()));
    }
  }

  void removeSlot(int index) {
    setState(() => _slotControllers.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? "Edit Movie" : "Add Movie"),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textFieldLabel("Movie Image URL"),
              textField(_imageController, "https://example.com/image.jpg"),

              const SizedBox(height: 20),

              textFieldLabel("Title"),
              textField(_titleController, "Movie title"),

              const SizedBox(height: 20),

              textFieldLabel("Description"),
              textField(_descController, "Movie description...", maxLines: 4),

              const SizedBox(height: 20),

              textFieldLabel("Duration (minutes)"),
              textField(_durationController, "120", keyboard: TextInputType.number),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  textFieldLabel("Time Slots (max 5)"),
                  TextButton.icon(
                    onPressed: addSlot,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Slot"),
                  )
                ],
              ),

              for (int i = 0; i < _slotControllers.length; i++)
                Row(
                  children: [
                    Expanded(
                      child: textField(_slotControllers[i], "10:00 AM"),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => removeSlot(i),
                    )
                  ],
                ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isEdit ? "Update Movie" : "Add Movie"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable label
  Widget textFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
    );
  }

  // Custom styled input
  Widget textField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: (v) => v!.isEmpty ? "Required" : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.card,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}