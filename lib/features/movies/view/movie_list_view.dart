import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../shared/widgets/app_empty.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_shimmer.dart';
import '../model/movie_model.dart';
import '../states/movie_list_bloc.dart';
import '../states/movie_list_event.dart';
import '../states/movie_list_state.dart';

class MovieListView extends StatelessWidget {
  const MovieListView({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<MovieListBloc>()..add(MovieListRequested()),
    child: Scaffold(
      body: BlocBuilder<MovieListBloc, MovieListState>(
        builder: (context, state) => switch (state.status) {
          MovieListStatus.initial ||
          MovieListStatus.loading => const _MovieListShimmer(),
          MovieListStatus.empty => const AppEmpty(
            message: 'Belum ada film yang bisa ditampilkan.',
          ),
          MovieListStatus.failure => AppError(
            message: state.errorMessage ?? 'Film belum bisa dimuat.',
            onRetry: () =>
                context.read<MovieListBloc>().add(MovieListRequested()),
          ),
          MovieListStatus.success =>
            state.movies.isEmpty
                ? const AppEmpty(
                    message: 'Belum ada film yang bisa ditampilkan.',
                  )
                : _MovieCollection(movies: state.movies),
        },
      ),
    ),
  );
}

class _MovieListShimmer extends StatelessWidget {
  const _MovieListShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('CineGo'),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: AppShimmerBox(
                width: 32,
                height: 32,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppShimmerBox(width: 150, height: 30),
                SizedBox(height: 10),
                AppShimmerBox(width: 225, height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const AppShimmerBox(
                    width: 66,
                    height: 82,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        AppShimmerBox(width: 120, height: 14),
                        SizedBox(height: 9),
                        AppShimmerBox(width: 145, height: 22),
                        SizedBox(height: 8),
                        AppShimmerBox(width: 130, height: 14),
                        SizedBox(height: 13),
                        AppShimmerBox(width: 78, height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: const [
                Expanded(child: AppShimmerBox(height: 20, width: 145)),
                AppShimmerBox(height: 14, width: 82),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: 5,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, _) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  AppShimmerBox(width: 34, height: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppShimmerBox(width: 170, height: 16),
                        SizedBox(height: 8),
                        AppShimmerBox(width: 155, height: 13),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  AppShimmerBox(width: 12, height: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MovieCollection extends StatelessWidget {
  const _MovieCollection({required this.movies});

  final List<MovieModel> movies;

  @override
  Widget build(BuildContext context) {
    final featuredMovie = movies.first;
    final remainingMovies = movies.skip(1).toList(growable: false);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('CineGo'),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Buka menu',
              onSelected: context.push,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: '/cinemas',
                  child: _MenuEntry(
                    icon: Icons.location_on_outlined,
                    label: 'Cari bioskop',
                  ),
                ),
                PopupMenuItem(
                  value: '/reminders',
                  child: _MenuEntry(
                    icon: Icons.notifications_none_rounded,
                    label: 'Pengingat',
                  ),
                ),
              ],
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: _PageIntroduction(movieCount: movies.length),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _FeaturedFilm(
              movie: featuredMovie,
              onTap: () => _openMovie(context, featuredMovie),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _CollectionHeading(count: remainingMovies.length),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          sliver: SliverList.separated(
            itemCount: remainingMovies.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final movie = remainingMovies[index];
              return _MovieRow(
                movie: movie,
                onTap: () => _openMovie(context, movie),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuEntry extends StatelessWidget {
  const _MenuEntry({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 24),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(fontWeight: .bold)),
    ],
  );
}

class _PageIntroduction extends StatelessWidget {
  const _PageIntroduction({required this.movieCount});

  final int movieCount;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Star Wars',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        '$movieCount episode tersedia',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
      ),
    ],
  );
}

class _FeaturedFilm extends StatelessWidget {
  const _FeaturedFilm({required this.movie, required this.onTap});

  final MovieModel movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final year = movie.releaseDate?.year.toString() ?? 'Tahun tidak diketahui';
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: movie.id == null ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 82,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _romanEpisode(movie.episodeId),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Episode ${_romanEpisode(movie.episodeId)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$year · ${movie.director}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lihat detail',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionHeading extends StatelessWidget {
  const _CollectionHeading({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          'Urutan episode',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      Text(
        '$count film',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white54),
      ),
    ],
  );
}

class _MovieRow extends StatelessWidget {
  const _MovieRow({required this.movie, required this.onTap});

  final MovieModel movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final year = movie.releaseDate?.year.toString() ?? '—';
    return InkWell(
      onTap: movie.id == null ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                _romanEpisode(movie.episodeId),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Episode ${movie.episodeId} · $year · ${movie.director}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

void _openMovie(BuildContext context, MovieModel movie) {
  final id = movie.id;
  if (id != null) context.push('/movies/$id');
}

String _romanEpisode(int episode) =>
    const {
      1: 'I',
      2: 'II',
      3: 'III',
      4: 'IV',
      5: 'V',
      6: 'VI',
      7: 'VII',
      8: 'VIII',
      9: 'IX',
    }[episode] ??
    '$episode';
