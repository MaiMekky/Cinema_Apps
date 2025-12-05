import '../models/movie.dart';

class MoviesService {
  static List<Movie> getMovies() {
    return [
      Movie(
        title: "The Dark Universe",
        description:
            "An epic space adventure following a crew as they encounter mysterious cosmic forces...",
        imageUrl: "https://picsum.photos/600/400",
        duration: 120,
      ),
      Movie(
        title: "City Lights",
        description:
            "A heartwarming drama about connection and hope in the busy city...",
        imageUrl: "https://picsum.photos/600/401",
        duration: 105,
      ),
    ];
  }
}
