import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_shimmer.dart';
import '../model/movie_related_content_model.dart';
import '../model/movie_model.dart';
import '../states/movie_detail_bloc.dart';
import '../states/movie_detail_event.dart';
import '../states/movie_detail_state.dart';
import '../states/movie_related_detail_bloc.dart';
import '../states/movie_related_detail_event.dart';
import '../states/movie_related_detail_state.dart';

class MovieDetailView extends StatelessWidget {
  const MovieDetailView({super.key, required this.movieId});

  final int movieId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<MovieDetailBloc>()..add(MovieDetailRequested(movieId)),
    child: Scaffold(
      appBar: AppBar(title: const Text('Detail film')),
      body: BlocBuilder<MovieDetailBloc, MovieDetailState>(
        builder: (context, state) => switch (state.status) {
          MovieDetailStatus.initial ||
          MovieDetailStatus.loading => const _MovieDetailShimmer(),
          MovieDetailStatus.failure => AppError(
            message: state.errorMessage ?? 'Film belum bisa dimuat.',
            onRetry: () => context.read<MovieDetailBloc>().add(
              MovieDetailRequested(movieId),
            ),
          ),
          MovieDetailStatus.success => _MovieDetails(
            movie: state.movie!,
            relatedStatus: state.relatedStatus,
            relatedContent: state.relatedContent,
            relatedError: state.relatedError,
            onRetryRelated: () => context.read<MovieDetailBloc>().add(
              MovieRelatedContentRequested(),
            ),
          ),
        },
      ),
    ),
  );
}

class _MovieDetailShimmer extends StatelessWidget {
  const _MovieDetailShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - 44;
        final synopsisLineCount = (620 / (width / 8))
            .ceil()
            .clamp(7, 18)
            .toInt();
        const lineWidths = [1.0, 0.94, 0.98, 0.9];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppShimmerBox(width: 92, height: 18),
              const SizedBox(height: 14),
              AppShimmerBox(width: width * 0.82, height: 30),
              const SizedBox(height: 8),
              AppShimmerBox(width: width * 0.58, height: 30),
              const SizedBox(height: 10),
              AppShimmerBox(width: width * 0.42, height: 16),
              const SizedBox(height: 32),
              AppShimmerBox(width: width * 0.34, height: 20),
              const SizedBox(height: 14),
              ...List.generate(
                synopsisLineCount,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppShimmerBox(
                    width:
                        width *
                        (index == synopsisLineCount - 1
                            ? 0.58
                            : lineWidths[index % lineWidths.length]),
                    height: 14,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(height: 1),
              const SizedBox(height: 22),
              AppShimmerBox(width: width * 0.4, height: 20),
              const SizedBox(height: 20),
              _CreditShimmerRow(valueWidth: width * 0.43),
              const SizedBox(height: 22),
              _CreditShimmerRow(valueWidth: width * 0.5),
              const SizedBox(height: 22),
              _CreditShimmerRow(valueWidth: width * 0.35),
            ],
          ),
        );
      },
    ),
  );
}

class _CreditShimmerRow extends StatelessWidget {
  const _CreditShimmerRow({required this.valueWidth});

  final double valueWidth;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const AppShimmerBox(width: 92, height: 15),
      const SizedBox(width: 20),
      AppShimmerBox(width: valueWidth, height: 15),
    ],
  );
}

class _MovieDetails extends StatelessWidget {
  const _MovieDetails({
    required this.movie,
    required this.relatedStatus,
    required this.relatedContent,
    required this.relatedError,
    required this.onRetryRelated,
  });

  final MovieModel movie;
  final MovieRelatedStatus relatedStatus;
  final MovieRelatedContentModel? relatedContent;
  final String? relatedError;
  final VoidCallback onRetryRelated;

  @override
  Widget build(BuildContext context) {
    final year = movie.releaseDate?.year.toString() ?? 'Tahun tidak diketahui';
    final synopsis = movie.openingCrawl.trim();
    final formattedSynopsis = synopsis
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .trim()
        .split(RegExp(r'\n\s*\n'))
        .map((paragraph) => paragraph.replaceAll('\n', ' ').trim())
        .join('\n\n');

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Episode ${movie.episodeId}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  movie.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.08,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Star Wars  ·  $year',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: 28),
                const _SectionHeading(title: 'Ringkasan'),
                const SizedBox(height: 12),
                Text(
                  formattedSynopsis.isEmpty
                      ? 'Ringkasan film belum tersedia.'
                      : formattedSynopsis,
                  textAlign: TextAlign.justify,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(height: 1),
                const SizedBox(height: 22),
                const _SectionHeading(title: 'Informasi film'),
                const SizedBox(height: 8),
                _CreditRow(label: 'Sutradara', value: movie.director),
                _CreditRow(label: 'Produser', value: movie.producer),
                _CreditRow(label: 'Tanggal rilis', value: _releaseDate(movie)),
                const SizedBox(height: 28),
                const Divider(height: 1),
                const SizedBox(height: 22),
                const _SectionHeading(title: 'Semesta film'),
                const SizedBox(height: 8),
                _MovieRelatedSections(
                  status: relatedStatus,
                  content: relatedContent,
                  error: relatedError,
                  onRetry: onRetryRelated,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MovieRelatedSections extends StatelessWidget {
  const _MovieRelatedSections({
    required this.status,
    required this.content,
    required this.error,
    required this.onRetry,
  });

  final MovieRelatedStatus status;
  final MovieRelatedContentModel? content;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => switch (status) {
    MovieRelatedStatus.initial ||
    MovieRelatedStatus.loading => const _RelatedContentShimmer(),
    MovieRelatedStatus.failure => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          error ?? 'Data tambahan belum bisa dimuat.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
        ),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba lagi'),
        ),
      ],
    ),
    MovieRelatedStatus.success => _buildContent(context),
  };

  Widget _buildContent(BuildContext context) {
    final related = content ?? const MovieRelatedContentModel();
    final sections = [
      ('Karakter', related.characters),
      ('Spesies', related.species),
      ('Planet', related.planets),
      ('Kendaraan', related.vehicles),
      ('Kapal antarbintang', related.starships),
    ].where((section) => section.$2.isNotEmpty).toList(growable: false);

    if (sections.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tidak ada data semesta tambahan untuk film ini.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
          ),
          if (related.failedResourceCount > 0) ...[
            const SizedBox(height: 10),
            _PartialRelatedDataNotice(
              failedCount: related.failedResourceCount,
              onRetry: onRetry,
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (related.failedResourceCount > 0)
          _PartialRelatedDataNotice(
            failedCount: related.failedResourceCount,
            onRetry: onRetry,
          ),
        for (final section in sections)
          _RelatedResourceSection(
            title: section.$1,
            items: section.$2,
            onItemTap: (item) => _showRelatedDetail(context, item),
          ),
      ],
    );
  }
}

void _showRelatedDetail(BuildContext context, MovieRelatedItemModel item) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BlocProvider(
      create: (_) =>
          getIt<MovieRelatedDetailBloc>()
            ..add(MovieRelatedDetailRequested(item)),
      child: _MovieRelatedDetailSheet(item: item),
    ),
  );
}

class _PartialRelatedDataNotice extends StatelessWidget {
  const _PartialRelatedDataNotice({
    required this.failedCount,
    required this.onRetry,
  });

  final int failedCount;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '$failedCount data terkait gagal dimuat.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    ),
  );
}

class _RelatedResourceSection extends StatelessWidget {
  const _RelatedResourceSection({
    required this.title,
    required this.items,
    required this.onItemTap,
  });

  final String title;
  final List<MovieRelatedItemModel> items;
  final ValueChanged<MovieRelatedItemModel> onItemTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        for (var index = 0; index < items.length; index++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onItemTap(items[index]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.circle,
                          color: Colors.white38,
                          size: 6,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[index].name,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (items[index].subtitle.isNotEmpty ||
                                items[index].details.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                [items[index].subtitle, items[index].details]
                                    .where((value) => value.isNotEmpty)
                                    .join(' · '),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white54,
                                      height: 1.4,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (index < items.length - 1) const Divider(height: 1),
        ],
      ],
    ),
  );
}

class _MovieRelatedDetailSheet extends StatelessWidget {
  const _MovieRelatedDetailSheet({required this.item});

  final MovieRelatedItemModel item;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _relatedTypeName(item.type),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.accent),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: BlocBuilder<MovieRelatedDetailBloc, MovieRelatedDetailState>(
              builder: (context, state) => switch (state.status) {
                MovieRelatedDetailStatus.initial ||
                MovieRelatedDetailStatus.loading =>
                  const _RelatedDetailShimmer(),
                MovieRelatedDetailStatus.failure => _RelatedDetailError(
                  message: state.errorMessage ?? 'Detail belum bisa dimuat.',
                  onRetry: () => context.read<MovieRelatedDetailBloc>().add(
                    MovieRelatedDetailRequested(item),
                  ),
                ),
                MovieRelatedDetailStatus.success => _RelatedDetailContent(
                  detail: state.detail!,
                ),
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _RelatedDetailContent extends StatelessWidget {
  const _RelatedDetailContent({required this.detail});

  final MovieRelatedDetailModel detail;

  @override
  Widget build(BuildContext context) {
    if (detail.fields.isEmpty) {
      return const Center(child: Text('Belum ada detail tambahan.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      itemCount: detail.fields.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final field = detail.fields[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 132,
                child: Text(
                  field.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                ),
              ),
              Expanded(
                child: Text(
                  field.value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RelatedDetailError extends StatelessWidget {
  const _RelatedDetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    ),
  );
}

class _RelatedDetailShimmer extends StatelessWidget {
  const _RelatedDetailShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      itemCount: 7,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, index) => Row(
        children: [
          const AppShimmerBox(width: 116, height: 14),
          const SizedBox(width: 18),
          AppShimmerBox(width: 110 + index % 3 * 24, height: 14),
        ],
      ),
    ),
  );
}

String _relatedTypeName(MovieRelatedType type) => switch (type) {
  MovieRelatedType.character => 'KARAKTER',
  MovieRelatedType.species => 'SPESIES',
  MovieRelatedType.planet => 'PLANET',
  MovieRelatedType.vehicle => 'KENDARAAN',
  MovieRelatedType.starship => 'KAPAL ANTARBINTANG',
};

class _RelatedContentShimmer extends StatelessWidget {
  const _RelatedContentShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < 5; index++) ...[
          const SizedBox(height: 14),
          const AppShimmerBox(width: 88, height: 14),
          const SizedBox(height: 12),
          for (var item = 0; item < 2; item++) ...[
            const AppShimmerBox(height: 38),
            const SizedBox(height: 8),
          ],
        ],
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

String _releaseDate(MovieModel movie) {
  final date = movie.releaseDate;
  if (date == null) return 'Tidak diketahui';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
