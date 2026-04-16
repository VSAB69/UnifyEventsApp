import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Strategy: render each letter of UNIFY in its own widget with a GlobalKey.
//  After the word finishes typing, measure the I widget's position on screen.
//  Droplet travels a cubic bezier from off-screen left → low arc → high arc
//  → lands exactly on the I's dot position.
// ─────────────────────────────────────────────────────────────────────────────

const _kWord        = 'UNIFY';
const _kFontSize    = 72.0;
const _kLetterSpace = 12.0;
const _kDotR        = 11.0;

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});
  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with TickerProviderStateMixin {

  static const _word        = _kWord;
  static const _fontSize    = _kFontSize;
  static const _letterSpace = _kLetterSpace;
  static const _dotR        = _kDotR;

  // One key per letter — we only read the 'I' one (index 2)
  final _keys = List.generate(5, (_) => GlobalKey());

  int  _visibleCount = 0; // how many letters are shown
  Timer? _typeTimer;

  late final AnimationController _dropCtrl;
  late final AnimationController _splatCtrl;
  late final AnimationController _eventsCtrl;

  Offset? _dotPos;       // measured I dot centre in global screen coords
  bool _dropActive   = false;
  bool _dotHidden    = true;  // dot stays hidden until droplet lands
  bool _splatActive  = false;
  bool _splatDone    = false;

  @override
  void initState() {
    super.initState();

    _dropCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _splatCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _eventsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    // Type one letter every 160 ms
    _typeTimer = Timer.periodic(const Duration(milliseconds: 160), (t) {
      if (_visibleCount >= _word.length) {
        t.cancel();
        // All letters shown — measure then launch after a beat
        Future.delayed(const Duration(milliseconds: 500), _measureAndLaunch);
        return;
      }
      setState(() => _visibleCount++);
    });

    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) {
        ref.read(authProvider.notifier).checkAuth();
      }
    });
  }

  // Measure the I widget's position after it has been rendered
  void _measureAndLaunch() {
    if (!mounted) return;

    // Index 2 = 'I'
    final iKey = _keys[2];
    final box  = iKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      // Retry once if not ready yet
      Future.delayed(const Duration(milliseconds: 100), _measureAndLaunch);
      return;
    }

    final size   = box.size;
    final global = box.localToGlobal(Offset.zero);

    // Centre-X of the I glyph; dot sits above the top of the letter
    final dotX = global.dx + size.width / 2;
    final dotY = global.dy - _dotR - 4; // 4 px gap above cap line

    setState(() {
      _dotPos     = Offset(dotX, dotY);
      _dotHidden  = true;   // keep hidden while droplet travels
      _dropActive = true;
    });

    _dropCtrl.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _dropActive  = false;
        _splatActive = true;
        _dotHidden   = false; // droplet has landed — show the dot
      });
      _splatCtrl.forward().then((_) {
        if (!mounted) return;
        setState(() => _splatDone = true);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _eventsCtrl.forward();
        });
      });
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _dropCtrl.dispose();
    _splatCtrl.dispose();
    _eventsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_dropCtrl, _splatCtrl, _eventsCtrl]),
        builder: (context, _) {
          final dropT   = Curves.easeInOutCubic.transform(_dropCtrl.value);
          final splatT  = Curves.easeOut.transform(_splatCtrl.value);
          final eventsT = Curves.easeOut.transform(_eventsCtrl.value);

          return Stack(children: [

            // ── Word + tagline (centred) ────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Each letter is its own widget so we can key the I
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_word.length, (i) {
                      if (i >= _visibleCount) {
                        // Placeholder keeps row width stable once letter appears
                        return _LetterBox(
                          key:     _keys[i],
                          letter:  _word[i],
                          visible: false,
                        );
                      }

                      // For the I (index 2): draw letter but optionally hide
                      // the dot overlay while droplet is travelling
                      if (i == 2) {
                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            _LetterBox(
                              key:     _keys[i],
                              letter:  _word[i],
                              visible: true,
                            ),
                            // Dot only appears after droplet lands (_dotHidden starts true)
                            if (!_dotHidden)
                              Positioned(
                                top:  -(_dotR * 2 + 4),
                                child: Container(
                                  width: _dotR * 2, height: _dotR * 2,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFF1C7C),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }

                      return _LetterBox(
                        key:     _keys[i],
                        letter:  _word[i],
                        visible: true,
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // Tagline
                  Opacity(
                    opacity: eventsT,
                    child: Transform.translate(
                      offset: Offset(0, (1 - eventsT) * 12),
                      child: Text(
                        'college events, unified.',
                        style: GoogleFonts.manrope(
                          fontSize:      13,
                          fontWeight:    FontWeight.w500,
                          letterSpacing: 1.8,
                          color: const Color(0xFFFF1C7C).withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Flying droplet ──────────────────────────────────────
            if (_dropActive && _dotPos != null)
              CustomPaint(
                size: Size(sw, sh),
                painter: _DropletPainter(
                  t:      dropT,
                  target: _dotPos!,
                  sw:     sw,
                  sh:     sh,
                ),
              ),

            // ── Landing splat ───────────────────────────────────────
            if (_splatActive && !_splatDone && _dotPos != null)
              CustomPaint(
                size: Size(sw, sh),
                painter: _SplatPainter(t: splatT, centre: _dotPos!),
              ),
          ]);
        },
      ),
    );
  }
}

// ─── Single letter widget ─────────────────────────────────────────────────────

class _LetterBox extends StatelessWidget {
  final String  letter;
  final bool    visible;

  const _LetterBox({super.key, required this.letter, required this.visible});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: visible ? 1.0 : 0.0,
      child: Text(
        letter,
        style: GoogleFonts.sora(
          fontSize:      _kFontSize,
          fontWeight:    FontWeight.w900,
          color:         const Color(0xFFFF1C7C),
          letterSpacing: _kLetterSpace,
          height:        1,
        ),
      ),
    );
  }
}

// ─── Droplet ──────────────────────────────────────────────────────────────────

class _DropletPainter extends CustomPainter {
  final double t;
  final Offset target;
  final double sw, sh;

  static const _lime = Color(0xFFFF1C7C);

  const _DropletPainter({
    required this.t, required this.target,
    required this.sw, required this.sh,
  });

  // The four bezier control points — same curve the droplet follows
  Offset get _p0 => Offset(-80,       target.dy + 10);
  Offset get _p1 => Offset(sw * 0.22, target.dy + sh * 0.20);
  Offset get _p2 => Offset(sw * 0.76, target.dy - sh * 0.14);
  Offset get _p3 => target;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;

    final p0 = _p0; final p1 = _p1;
    final p2 = _p2; final p3 = _p3;

    // ── 1. Tapered trail ribbon ─────────────────────────────────────
    // Sample N points along the path from 0..t, build a variable-width
    // ribbon that starts thin (tail) and widens toward the head.
    const N      = 60;
    final tStart = (t - 0.55).clamp(0.0, 1.0); // trail fades in over first half
    final pts    = <Offset>[];
    final widths = <double>[];

    for (int i = 0; i <= N; i++) {
      final u   = tStart + (t - tStart) * (i / N);
      pts.add(_bez(p0, p1, p2, p3, u));
      // Width tapers: 0 at tail, maxW at head
      widths.add((i / N) * 7.0 + 1.0);
    }

    // Build ribbon as a filled path by walking left-side then right-side
    final ribbonPath = Path();
    final paint = Paint()..style = PaintingStyle.fill;

    // Left side (forward)
    for (int i = 0; i <= N; i++) {
      final tang = i < N
          ? (pts[i + 1] - pts[i])
          : (pts[N] - pts[N - 1]);
      final len  = tang.distance;
      if (len == 0) continue;
      final perp = Offset(-tang.dy / len, tang.dx / len);
      final hw   = widths[i] / 2;
      final lp   = pts[i] + perp * hw;
      if (i == 0) ribbonPath.moveTo(lp.dx, lp.dy);
      else        ribbonPath.lineTo(lp.dx, lp.dy);
    }
    // Round cap at head (left→right)
    final headTang = pts[N] - pts[N - 1];
    final headLen  = headTang.distance;
    if (headLen > 0) {
      final headPerp = Offset(-headTang.dy / headLen, headTang.dx / headLen);
      final hw       = widths[N] / 2;
      ribbonPath.arcToPoint(
        pts[N] - headPerp * hw,
        radius: Radius.circular(hw),
        clockwise: true,
      );
    }
    // Right side (backward)
    for (int i = N; i >= 0; i--) {
      final tang = i < N
          ? (pts[i + 1] - pts[i])
          : (pts[N] - pts[N - 1]);
      final len  = tang.distance;
      if (len == 0) continue;
      final perp = Offset(-tang.dy / len, tang.dx / len);
      final hw   = widths[i] / 2;
      final rp   = pts[i] - perp * hw;
      ribbonPath.lineTo(rp.dx, rp.dy);
    }
    ribbonPath.close();

    // Paint ribbon with gradient opacity: transparent at tail, full at head
    // We approximate by drawing multiple overlapping segments with increasing opacity
    // Simpler: draw the full ribbon semi-transparent, then overdraw near the head
    paint.color = _lime.withOpacity(0.55);
    canvas.drawPath(ribbonPath, paint);

    // Overdraw the front 30% of the trail at full opacity for crisp head transition
    final frontPath = Path();
    final frontStart = (0.70 * N).round();
    for (int i = frontStart; i <= N; i++) {
      final tang = i < N
          ? (pts[i + 1] - pts[i])
          : (pts[N] - pts[N - 1]);
      final len  = tang.distance;
      if (len == 0) continue;
      final perp = Offset(-tang.dy / len, tang.dx / len);
      final hw   = widths[i] / 2;
      if (i == frontStart) frontPath.moveTo((pts[i] + perp * hw).dx, (pts[i] + perp * hw).dy);
      else                 frontPath.lineTo((pts[i] + perp * hw).dx, (pts[i] + perp * hw).dy);
    }
    // cap + right side
    if (headLen > 0) {
      final headPerp = Offset(-headTang.dy / headLen, headTang.dx / headLen);
      final hw = widths[N] / 2;
      frontPath.arcToPoint(pts[N] - headPerp * hw,
          radius: Radius.circular(hw), clockwise: true);
    }
    for (int i = N; i >= frontStart; i--) {
      final tang = i < N
          ? (pts[i + 1] - pts[i])
          : (pts[N] - pts[N - 1]);
      final len  = tang.distance;
      if (len == 0) continue;
      final perp = Offset(-tang.dy / len, tang.dx / len);
      final hw   = widths[i] / 2;
      frontPath.lineTo((pts[i] - perp * hw).dx, (pts[i] - perp * hw).dy);
    }
    frontPath.close();
    paint.color = _lime.withOpacity(0.85);
    canvas.drawPath(frontPath, paint);

    // ── 2. Head blob ────────────────────────────────────────────────
    final headPos = pts[N];
    final headR   = 9.0 + t * 5.0;
    paint.color   = _lime;
    canvas.drawCircle(headPos, headR, paint);

    // Small specular highlight on the head — paint drop gloss
    canvas.drawCircle(
      headPos + Offset(-headR * 0.28, -headR * 0.28),
      headR * 0.22,
      Paint()..color = Colors.white.withOpacity(0.35)..style = PaintingStyle.fill,
    );
  }

  Offset _bez(Offset a, Offset b, Offset c, Offset d, double t) {
    final s = 1 - t;
    return Offset(
      s*s*s*a.dx + 3*s*s*t*b.dx + 3*s*t*t*c.dx + t*t*t*d.dx,
      s*s*s*a.dy + 3*s*s*t*b.dy + 3*s*t*t*c.dy + t*t*t*d.dy,
    );
  }

  @override
  bool shouldRepaint(covariant _DropletPainter old) => old.t != t;
}

// ─── Splat ────────────────────────────────────────────────────────────────────
// Just a brief circular ripple on landing — no arms, no sun shape.

class _SplatPainter extends CustomPainter {
  final double t;
  final Offset centre;
  static const _lime = Color(0xFFFF1C7C);

  const _SplatPainter({required this.t, required this.centre});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;

    // Dot squashes outward briefly then fades — pure clean landing
    final eased   = Curves.easeOut.transform(t);
    final opacity = (1.0 - eased).clamp(0.0, 1.0);
    final r       = _kDotR + eased * 10.0;

    final paint = Paint()
      ..color = _lime.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(centre, r, paint);
  }

  @override
  bool shouldRepaint(covariant _SplatPainter old) => old.t != t;
}
