import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'core/theme/pastel_theme.dart';
import 'features/camera/presentation/screens/camera_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geocam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: PastelColors.bgDark,
        colorScheme: const ColorScheme.dark(
          primary: PastelColors.pink,
          secondary: PastelColors.lavender,
          surface: PastelColors.surfaceDark,
          tertiary: PastelColors.mint,
        ),
        fontFamily: null,
        splashFactory: InkSparkle.splashFactory,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const CameraScreen(),
    );
  }
}
