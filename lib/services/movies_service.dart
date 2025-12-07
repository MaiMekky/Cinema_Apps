import '../models/movie.dart';

class MoviesService {
  static List<Movie> getMovies() {
    return [
      Movie(
        id: "lwdkfjsdkfjj",
        title: "The Dark Universe",
        description:
            "An epic space adventure following a crew as they encounter mysterious cosmic forces...",
        posterUrl: "https://picsum.photos/600/400",
        duration: 120,
      ),
      Movie(
        id: "lsdkfjsldkfj",
        title: "City Lights",
        description:
            "A heartwarming drama about connection and hope in the busy city...",
        posterUrl: "https://picsum.photos/600/401",
        duration: 105,
      ),
    ];
  }
}
