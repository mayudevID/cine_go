import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class CineGoApp extends StatelessWidget {
  const CineGoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'CineGo',
    locale: const Locale('id'),
    supportedLocales: const [Locale('id')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.dark,
    scrollBehavior: const _BouncingScrollBehavior(),
    routerConfig: appRouter,
    debugShowCheckedModeBanner: false,
  );
}

class _BouncingScrollBehavior extends MaterialScrollBehavior {
  const _BouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
