// F3.1 spike v4 — second-source globe trial.
//
// `flutter_earth_globe` had unfixable rotation-axis bugs that broke the
// drag UX. Trying `flutter_globe_3d` (GPU-shader rendering, smoother
// gestures per its README) before deciding on ADR-010 Path A vs B.
//
// Default texture = the package's bundled photorealistic earth.jpg. NOT
// our target aesthetic — F3.2 will swap to a custom abstract texture via
// the `texture: ImageProvider` constructor parameter once rotation
// quality is confirmed acceptable.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_globe_3d/flutter_globe_3d.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Modern abstract palette — F3.2 will replace the procedural texture
// generator below with Natural Earth polygons rasterized at user-specific
// visited fills, but the constants here lock the visual identity.
const _oceanColor = Color(0xFF0F1A2A);
// Mid-tan that survives both the package's ambient (0.05) and full-sun
// (1.0) shader multipliers without going pure white or invisible.
const _landColor = Color(0xFFA89678);
const _visitedPinColor = Color(0xFFE8B86B);

class GlobeScreen extends StatefulWidget {
  const GlobeScreen({super.key});

  @override
  State<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends State<GlobeScreen> {
  final EarthController _controller = EarthController();
  MemoryImage? _texture;
  Timer? _resumeAutoRotateTimer;

  // The package's built-in resume-after-interaction is ~1s — too eager.
  // We override it: disable auto-rotate immediately on touch, schedule
  // re-enable 8s after the user lifts their finger.
  static const _resumeAutoRotateAfter = Duration(seconds: 8);

  // Cache the last light lat/lng we set. Comparing this on every controller
  // tick lets us bail before the cycle setFixedLightCoordinates →
  // notifyListeners → our listener → setFixedLightCoordinates → ... can
  // recurse indefinitely.
  double _lastLightLat = double.nan;
  double _lastLightLng = double.nan;

  // Track viewport changes (fold/unfold/rotation) so we can reset the
  // controller's internal zoom + camera state. Without this, prior gesture
  // state (e.g. user zoomed in on the cover display, then unfolded) leaks
  // into the new layout and the globe renders comically oversized.
  double? _lastCanvasSide;

  static const _dummyPins = [
    _DummyPin('seoul', 'Seoul', 37.5665, 126.9780),
    _DummyPin('tokyo', 'Tokyo', 35.6762, 139.6503),
    _DummyPin('paris', 'Paris', 48.8566, 2.3522),
    _DummyPin('nyc', 'New York', 40.7128, -74.0060),
    _DummyPin('sydney', 'Sydney', -33.8688, 151.2093),
    _DummyPin('cairo', 'Cairo', 30.0444, 31.2357),
  ];

  @override
  void initState() {
    super.initState();
    // The package's example uses 18 (spinny demo). Slower is calmer.
    _controller.rotateSpeed = 0.8;
    _controller.enableAutoRotate = true;
    _controller.minZoom = 0.1;
    // followCamera mode has a hardcoded -1.5/+1.5/-1.0 light offset (see
    // package earth.dart) which leaves a wide dark band on the visible
    // hemisphere. fixedCoordinates lets us put the light *at* the initial
    // camera focus so the user lands on a fully lit hemisphere. F3.2 can
    // wire a listener that follows the controller's lat/lng to keep the
    // light moving with rotation.
    _controller.setLightMode(EarthLightMode.fixedCoordinates);
    _controller.setFixedLightCoordinates(37.5, 126.9);
    _controller.addListener(_syncLightToCamera);
    for (final p in _dummyPins) {
      _controller.addNode(
        EarthNode(
          id: p.id,
          latitude: p.lat,
          longitude: p.lng,
          child: _pin(p.label),
        ),
      );
    }
    _initTexture();
  }

  Future<void> _initTexture() async {
    final pngBytes = await _renderEarthTexture();
    if (!mounted) return;
    setState(() => _texture = MemoryImage(pngBytes));
  }

  @override
  void dispose() {
    _resumeAutoRotateTimer?.cancel();
    _controller.removeListener(_syncLightToCamera);
    super.dispose();
  }

  /// Keep the fixed-coordinate light point glued to the camera's current
  /// view center so the lit hemisphere is always the one facing the user.
  /// Eliminates the dark terminator stripe that comes with realTime /
  /// followCamera modes. See `EarthController.setCameraFocus` for the
  /// inverse mapping (offset → lat/lng).
  void _syncLightToCamera() {
    // dx = -(lon + 90) × π/180 × 200  →  lon = -dx × 180/(200π) - 90
    // dy =  lat × π/180 × 200          →  lat =  dy × 180/(200π)
    const radToDeg = 180.0 / (200.0 * math.pi);
    final lat = _controller.offset.dy * radToDeg;
    var lng = -_controller.offset.dx * radToDeg - 90.0;
    // Wrap to [-180, 180].
    lng = ((lng + 180.0) % 360.0 + 360.0) % 360.0 - 180.0;
    if ((lat - _lastLightLat).abs() < 0.05 &&
        (lng - _lastLightLng).abs() < 0.05) {
      return;
    }
    _lastLightLat = lat;
    _lastLightLng = lng;
    _controller.setFixedLightCoordinates(lat, lng);
  }

  void _onUserTouchStart() {
    _resumeAutoRotateTimer?.cancel();
    if (_controller.enableAutoRotate) {
      _controller.enableAutoRotate = false;
    }
  }

  void _onUserTouchEnd() {
    _resumeAutoRotateTimer?.cancel();
    _resumeAutoRotateTimer = Timer(_resumeAutoRotateAfter, () {
      if (!mounted) return;
      _controller.enableAutoRotate = true;
    });
  }

  /// Renders a 2048×1024 equirectangular PNG: solid ocean + rough continent
  /// ovals (placeholder geometry until F3.2 swaps in Natural Earth polygons).
  Future<Uint8List> _renderEarthTexture() async {
    const w = 2048.0;
    const h = 1024.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()..color = _oceanColor,
    );

    final land = Paint()..color = _landColor;
    void blob(double cxFrac, double cyFrac, double wFrac, double hFrac) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * cxFrac, h * cyFrac),
          width: w * wFrac,
          height: h * hFrac,
        ),
        land,
      );
    }

    blob(0.22, 0.36, 0.18, 0.30); // North America
    blob(0.30, 0.66, 0.10, 0.26); // South America
    blob(0.51, 0.30, 0.10, 0.14); // Europe
    blob(0.55, 0.58, 0.12, 0.34); // Africa
    blob(0.72, 0.38, 0.22, 0.30); // Asia
    blob(0.82, 0.72, 0.10, 0.10); // Australia

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  }

  Widget _pin(String label) {
    return GestureDetector(
      onTap: () => _onPinTap(label),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: _visitedPinColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _visitedPinColor.withValues(alpha: 0.6),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  void _onPinTap(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — country drill-down coming in F3.3'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Full body area so zoom-in doesn't clip top/bottom. The package keeps the
    // globe round regardless of canvas aspect ratio — extra space is just
    // background, not a stretched sphere.
    final bodyHeight =
        media.size.height - kToolbarHeight - media.padding.top - media.padding.bottom;

    // Square canvas locked to the smaller of (width, available height).
    // This keeps the globe a consistent visual size regardless of aspect
    // ratio — folded portrait, unfolded near-square (Fold/iPad), or
    // landscape all render identically. `initialScale` is then a pure
    // canvas-pixel constant.
    final canvasSide = math.min(media.size.width, bodyHeight);
    const initialScale = 4.5;

    // Reset controller state when the viewport changes (fold/unfold). Has
    // to happen post-frame because controller mutations during build are
    // forbidden by Flutter.
    if (_lastCanvasSide != null && (_lastCanvasSide! - canvasSide).abs() > 10) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.setZoom(1.0);
        _controller.setCameraFocus(37.5, 126.9);
      });
    }
    _lastCanvasSide = canvasSide;
    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2638),
        foregroundColor: Colors.white,
        title: const Text(
          'ITER',
          style: TextStyle(letterSpacing: 6, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Wait for the procedural texture before mounting Earth3D —
            // otherwise the package briefly shows its bundled photoreal
            // Earth before our custom texture swaps in (visible flash).
            if (_texture == null)
              const CircularProgressIndicator(color: _visitedPinColor)
            else
              Listener(
                // Pause auto-rotate the moment the user touches; resume
                // 8s after the last lift. Lets the user browse without the
                // globe spinning away while they decide.
                onPointerDown: (_) => _onUserTouchStart(),
                onPointerUp: (_) => _onUserTouchEnd(),
                onPointerCancel: (_) => _onUserTouchEnd(),
                behavior: HitTestBehavior.translucent,
                child: Earth3D(
                  // Key on canvasSide so Flutter rebuilds Earth3D when the
                  // user folds/unfolds — otherwise stale internal zoom state
                  // leaks across the layout change.
                  key: ValueKey('earth-$canvasSide'),
                  controller: _controller,
                  texture: _texture!,
                  nightTexture: _texture!,
                  initialScale: initialScale,
                  initialLatitude: 37.5,
                  initialLongitude: 126.9,
                  size: Size(canvasSide, canvasSide),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 24,
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'flutter_globe_3d trial · ${_dummyPins.length} pins',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DummyPin {
  const _DummyPin(this.id, this.label, this.lat, this.lng);
  final String id;
  final String label;
  final double lat;
  final double lng;
}
