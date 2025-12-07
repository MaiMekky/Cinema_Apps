class Movie {
  String id;
  String title;
  String description;
  String imageUrl;
  int duration;
  List<String> timeSlots;

  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.duration,
    required this.timeSlots,
  });
}