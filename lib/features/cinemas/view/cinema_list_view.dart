import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Visibility;

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/mapbox_config.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_shimmer.dart';
import '../model/cinema_model.dart';
import '../model/cinema_route_model.dart';
import '../states/cinema_bloc.dart';
import '../states/cinema_event.dart';
import '../states/cinema_state.dart';

class CinemaListView extends StatefulWidget {
  const CinemaListView({super.key});

  @override
  State<CinemaListView> createState() => _CinemaListViewState();
}

class _CinemaListViewState extends State<CinemaListView> {
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<CinemaBloc>()..add(CinemasRequested()),
    child: Scaffold(
      appBar: AppBar(title: const Text('Cari bioskop')),
      body: BlocBuilder<CinemaBloc, CinemaState>(
        builder: (context, state) => switch (state.status) {
          CinemaStatus.initial ||
          CinemaStatus.loading => const _CinemaListShimmer(),
          CinemaStatus.failure => AppError(
            message: state.errorMessage ?? 'Daftar bioskop belum bisa dimuat.',
          ),
          CinemaStatus.empty => const Center(
            child: Text('Bioskop tidak ditemukan.'),
          ),
          CinemaStatus.success =>
            state.cinemas.isEmpty
                ? const Center(child: Text('Bioskop tidak ditemukan.'))
                : _CinemaFinderContent(
                    cinemas: state.cinemas,
                    selectedCinema: state.selectedCinema,
                    route: state.route,
                    routeStatus: state.routeStatus,
                    routeError: state.routeError,
                    onCinemaSelected: (cinema) {
                      context.read<CinemaBloc>().add(CinemaSelected(cinema));
                    },
                  ),
        },
      ),
    ),
  );
}

class _CinemaFinderContent extends StatefulWidget {
  const _CinemaFinderContent({
    required this.cinemas,
    required this.selectedCinema,
    required this.route,
    required this.routeStatus,
    required this.routeError,
    required this.onCinemaSelected,
  });

  final List<CinemaModel> cinemas;
  final CinemaModel? selectedCinema;
  final CinemaRouteModel? route;
  final CinemaRouteStatus routeStatus;
  final String? routeError;
  final ValueChanged<CinemaModel> onCinemaSelected;

  @override
  State<_CinemaFinderContent> createState() => _CinemaFinderContentState();
}

class _CinemaFinderContentState extends State<_CinemaFinderContent> {
  static const _initialSheetExtent = 0.46;

  bool _mapLayoutReady = false;
  final _sheetController = DraggableScrollableController();
  MapboxMap? _map;
  bool _initialCameraPositioned = false;
  CircleAnnotationManager? _markerManager;
  PolylineAnnotationManager? _routeManager;
  ScrollController? _cinemaListScrollController;
  final Map<String, CinemaModel> _cinemaByMarker = {};

  double get _defaultSheetHeight {
    if (_sheetController.isAttached && _sheetController.size > 0) {
      return _sheetController.pixels /
          _sheetController.size *
          _initialSheetExtent;
    }
    return MediaQuery.sizeOf(context).height * _initialSheetExtent;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mapLayoutReady = true);
    });
  }

  Future<void> _selectCinema(CinemaModel cinema) async {
    final sheetReset = _sheetController.isAttached
        ? _sheetController.animateTo(
            _initialSheetExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          )
        : Future<void>.value();
    widget.onCinemaSelected(cinema);
    await sheetReset;
    final listScrollController = _cinemaListScrollController;
    if (listScrollController?.hasClients ?? false) {
      await listScrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
    await _focusCinema(cinema);
  }

  Future<void> _focusCinema(CinemaModel cinema) async {
    final map = _map;
    if (map == null) return;
    await map.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(cinema.longitude, cinema.latitude)),
        zoom: 14.5,
        padding: MbxEdgeInsets(
          top: 24,
          left: 24,
          bottom: 24 + _defaultSheetHeight,
          right: 24,
        ),
      ),
      MapAnimationOptions(duration: 700),
    );
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CinemaFinderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.route != oldWidget.route ||
        widget.routeStatus != oldWidget.routeStatus) {
      _drawRoute();
    }
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    _map = map;
    await map.logo.updateSettings(
      LogoSettings(
        position: OrnamentPosition.TOP_RIGHT,
        marginTop: 12,
        marginRight: 12,
      ),
    );
    await map.compass.updateSettings(
      CompassSettings(
        position: OrnamentPosition.TOP_LEFT,
        marginTop: 12,
        marginLeft: 12,
      ),
    );
    await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    _markerManager = await map.annotations.createCircleAnnotationManager();
    _routeManager = await map.annotations.createPolylineAnnotationManager();
    final markers = await _markerManager!.createMulti(
      widget.cinemas.map((cinema) {
        final annotation = CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(cinema.longitude, cinema.latitude),
          ),
          circleColor: AppColors.cinemaMarker.toARGB32(),
          circleRadius: 8,
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 2,
        );
        return annotation;
      }).toList(),
    );
    for (var index = 0; index < markers.length; index++) {
      final marker = markers[index];
      if (marker != null) _cinemaByMarker[marker.id] = widget.cinemas[index];
    }
    _markerManager!.tapEvents(
      onTap: (annotation) {
        final cinema = _cinemaByMarker[annotation.id];
        if (cinema != null) unawaited(_selectCinema(cinema));
      },
    );
    try {
      await getIt<LocationService>().getCurrentPosition();
      await map.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          locationPuck: LocationPuck(locationPuck2D: DefaultLocationPuck2D()),
        ),
      );
    } catch (_) {
      if (messenger?.mounted ?? false) {
        messenger!.showSnackBar(
          const SnackBar(
            content: Text(
              'Izinkan akses lokasi untuk menampilkan posisi Anda.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final map = _map;
    if (map == null || _initialCameraPositioned) return;
    _initialCameraPositioned = true;

    final selectedCinema = widget.selectedCinema;
    if (selectedCinema != null) {
      await _focusCinema(selectedCinema);
      return;
    }

    log("LOGX onStyleLoaded: $_defaultSheetHeight");

    final camera = await map.cameraForCoordinatesPadding(
      widget.cinemas
          .map((c) => Point(coordinates: Position(c.longitude, c.latitude)))
          .toList(growable: false),
      CameraOptions(
        padding: MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
      ),
      MbxEdgeInsets(
        top: 36,
        left: 36,
        bottom: 36 + _defaultSheetHeight,
        right: 36,
      ),
      null,
      null,
    );

    await map.setCamera(camera);
  }

  Future<void> _drawRoute() async {
    final route = widget.route;
    final manager = _routeManager;

    if (manager == null) return;
    await manager.deleteAll();

    if (widget.routeStatus != CinemaRouteStatus.success || route == null) {
      return;
    }

    if (route.coordinates.length < 2) return;

    await manager.create(
      PolylineAnnotationOptions(
        geometry: LineString(
          coordinates: route.coordinates
              .map((point) => Position(point.longitude, point.latitude))
              .toList(),
        ),
        lineColor: AppColors.accent.toARGB32(),
        lineWidth: 5,
      ),
    );

    final map = _map;
    if (map == null) return;

    log("LOGX drawRoute: $_defaultSheetHeight");

    final camera = await map.cameraForCoordinatesPadding(
      route.coordinates
          .map((p) => Point(coordinates: Position(p.longitude, p.latitude)))
          .toList(growable: false),
      //* Debug
      // widget.cinemas
      //     .map((c) => Point(coordinates: Position(c.longitude, c.latitude)))
      //     .toList(growable: false),
      CameraOptions(
        padding: MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
      ),
      MbxEdgeInsets(
        top: 36,
        left: 36,
        bottom: 36 + _defaultSheetHeight,
        right: 36,
      ),
      null,
      null,
    );

    await Future.delayed(Duration(milliseconds: 500));
    await map.flyTo(camera, MapAnimationOptions(duration: 700));
  }

  @override
  Widget build(BuildContext context) {
    final selectedCinema = widget.selectedCinema;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: !MapboxConfig.isConfigured
              ? const _MapboxTokenRequired()
              : !_mapLayoutReady
              ? const ColoredBox(color: AppColors.background)
              : MapWidget(
                  key: const ValueKey('cinema-mapbox-map'),
                  styleUri: MapboxStyles.DARK,
                  gestureRecognizers: {
                    Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
                  },
                  viewport: const IdleViewportState(),
                  onMapCreated: _onMapCreated,
                  onStyleLoadedListener: _onStyleLoaded,
                ),
        ),
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: _initialSheetExtent,
          minChildSize: 0.24,
          maxChildSize: 0.88,
          builder: (context, scrollController) {
            _cinemaListScrollController = scrollController;
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 18,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bioskop di Jakarta',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${widget.cinemas.length} lokasi',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SelectedCinemaCard(
                    cinema: selectedCinema,
                    routeStatus: widget.routeStatus,
                    route: widget.route,
                    routeError: widget.routeError,
                  ),
                  const SizedBox(height: 12),
                  for (final cinema in widget.cinemas) ...[
                    _CinemaRow(
                      cinema: cinema,
                      isSelected: cinema.id == selectedCinema?.id,
                      onTap: () => unawaited(_selectCinema(cinema)),
                    ),
                    if (cinema != widget.cinemas.last) const Divider(height: 1),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MapboxTokenRequired extends StatelessWidget {
  const _MapboxTokenRequired();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surface,
    child: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Tambahkan MAPBOX_ACCESS_TOKEN untuk menampilkan peta.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class _SelectedCinemaCard extends StatelessWidget {
  const _SelectedCinemaCard({
    required this.cinema,
    required this.routeStatus,
    required this.route,
    required this.routeError,
  });

  final CinemaModel? cinema;
  final CinemaRouteStatus routeStatus;
  final CinemaRouteModel? route;
  final String? routeError;

  String get _etaText {
    if (cinema == null) {
      return 'Pilih bioskop untuk melihat rute dan perkiraan waktu tiba.';
    }
    if (routeStatus == CinemaRouteStatus.loading) {
      return 'Menghitung estimasi perjalanan...';
    }
    if (routeStatus == CinemaRouteStatus.failure) {
      final error = routeError?.toLowerCase() ?? '';
      return error.contains('token')
          ? 'Token akses Mapbox diperlukan untuk menghitung rute.'
          : error.contains('lokasi') || error.contains('izin')
          ? 'Izinkan akses lokasi untuk melihat estimasi perjalanan.'
          : 'Estimasi perjalanan belum tersedia.';
    }
    if (routeStatus != CinemaRouteStatus.success || route == null) {
      return 'Pilih bioskop untuk melihat estimasi perjalanan dari lokasi Anda';
    }
    final distance = route!.distanceMeters >= 1000
        ? '${(route!.distanceMeters / 1000).toStringAsFixed(1)} km'
        : '${route!.distanceMeters.round()} m';
    return '${_formatDuration(route!.eta)} · $distance berkendara';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final parts = <String>[
      if (hours > 0) '$hours jam',
      if (minutes > 0) '$minutes menit',
      if (seconds > 0) '$seconds detik',
    ];
    return parts.isEmpty ? '0 detik' : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on, color: AppColors.accent, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cinema?.name ?? 'Belum memilih bioskop',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                _etaText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white60),
              ),
            ],
          ),
        ),
        if (routeStatus == CinemaRouteStatus.loading)
          const AppShimmer(child: AppShimmerBox(width: 38, height: 12)),
      ],
    ),
  );
}

class _CinemaRow extends StatelessWidget {
  const _CinemaRow({
    required this.cinema,
    required this.isSelected,
    required this.onTap,
  });

  final CinemaModel cinema;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
    leading: Icon(
      Icons.theaters_outlined,
      color: isSelected ? AppColors.accent : Colors.white60,
    ),
    title: Text(
      cinema.name,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '${cinema.address}\n${cinema.latitude}, ${cinema.longitude}',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white54, height: 1.4),
      ),
    ),
    isThreeLine: true,
    onTap: onTap,
  );
}

class _CinemaListShimmer extends StatelessWidget {
  const _CinemaListShimmer();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const Positioned.fill(
        child: AppShimmer(
          child: AppShimmerBox(
            height: double.infinity,
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
      DraggableScrollableSheet(
        initialChildSize: 0.46,
        minChildSize: 0.24,
        maxChildSize: 0.88,
        builder: (context, scrollController) => AppShimmer(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              children: [
                const Center(child: AppShimmerBox(width: 38, height: 4)),
                const SizedBox(height: 24),
                const AppShimmerBox(width: 170, height: 20),
                const SizedBox(height: 16),
                const AppShimmerBox(height: 64),
                const SizedBox(height: 12),
                for (var index = 0; index < 5; index++) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        AppShimmerBox(width: 24, height: 24),
                        SizedBox(width: 12),
                        Expanded(child: AppShimmerBox(height: 42)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
