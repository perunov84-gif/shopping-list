import 'package:flutter/material.dart';

/// Фирменная заставка «AP» на чёрном фоне. Продолжает системную заставку Android/iOS
/// (тот же логотип в том же месте), держится около секунды и плавно исчезает.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.child, required this.hold});
  final Widget child;
  final Duration hold;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _fade =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 1);
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.hold, () async {
      if (!mounted) return;
      await _fade.reverse();
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: FadeTransition(
          opacity: _fade,
          child: const ColoredBox(
            color: Colors.black,
            child: Center(
              child: Image(image: AssetImage('assets/images/splash_logo.png'), width: 288, height: 288),
            ),
          ),
        ),
      ),
    ]);
  }
}
