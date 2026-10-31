import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/cinemas/view/cinema_list_view.dart';
import '../../features/movies/view/movie_detail_view.dart';
import '../../features/movies/view/movie_list_view.dart';
import '../../features/reminders/view/reminder_form_view.dart';
import '../../features/reminders/view/reminder_list_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/movies',
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/movies'),
    GoRoute(path: '/movies', builder: (_, _) => const MovieListView()),
    GoRoute(
      path: '/movies/:id',
      builder: (_, state) => MovieDetailView(
        movieId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
      ),
    ),
    GoRoute(path: '/cinemas', builder: (_, _) => const CinemaListView()),
    GoRoute(path: '/reminders', builder: (_, _) => const ReminderListView()),
    GoRoute(
      path: '/reminders/new',
      builder: (_, _) => const ReminderFormView(),
    ),
  ],
  errorBuilder: (_, _) =>
      Scaffold(body: const Center(child: Text('Halaman tidak ditemukan.'))),
);
