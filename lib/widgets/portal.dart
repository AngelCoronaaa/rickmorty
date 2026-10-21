import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Portal verde que gira, inspirado en el de Rick and Morty.
class Portal extends StatefulWidget {
  const Portal({super.key, this.size = 150, this.rapido = false});

  final double size;

  /// Gira más rápido (por ejemplo mientras se valida el acceso).
  final bool rapido;

  @override
  State<Portal> createState() => _PortalState();
}

class _PortalState extends State<Portal> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox.square(
      dimension: s,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final v = widget.rapido ? 4 : 1;
            final t = _ctrl.value * 2 * math.pi * v;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF97CE4C).withValues(alpha: 0.55),
                        blurRadius: s * 0.35,
                        spreadRadius: s * 0.02,
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < 4; i++)
                  Transform.rotate(
                    angle: t * (i.isEven ? 1 : -1.4) + i,
                    child: Container(
                      width: s * (1 - i * 0.17),
                      height: s * (1 - i * 0.17),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            const Color(0xFFD7F7A0),
                            const Color(0xFF97CE4C).withValues(alpha: 0.2),
                            const Color(0xFF3FA535),
                            const Color(0xFF97CE4C).withValues(alpha: 0.1),
                            const Color(0xFFD7F7A0),
                          ],
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: s * 0.3,
                  height: s * 0.3,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.white, Color(0xFFB8F36B)],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
