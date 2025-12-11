import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/services/movies_repository.dart';
import '/cubit/movies/movies_cubit.dart';
import '/cubit/add_movie/add_movie_cubit.dart';
import '/cubit/edit_movie/edit_movie_cubit.dart';
import '/cubit/dashboard/dashboard_cubit.dart';
import 'screens/vendor_dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final repo = MoviesRepository();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MoviesCubit(repo)..watchAll()),
        BlocProvider(create: (_) => AddMovieCubit(repo)),
        BlocProvider(create: (_) => EditMovieCubit(repo)),
        BlocProvider(create: (_) => DashboardCubit(repo)..start()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vendor Dashboard',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111B2B),
      ),
      home: const VendorDashboardScreen(),
    );
  }
}
