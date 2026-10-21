import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fondo de manchas de color difuminadas. Sus colores salen de [GlassPalette],
/// por eso se funden suavemente al cambiar entre claro y oscuro.
class LiquidBackground extends StatelessWidget {
  const LiquidBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = GlassPalette.of(context);

    return ColoredBox(
      color: p.fondo,
      child: Stack(
        children: [
          _Mancha(const Alignment(-1.3, -1.0), 460, p.mancha1),
          _Mancha(const Alignment(1.4, -0.1), 380, p.mancha2),
          _Mancha(const Alignment(-0.4, 1.3), 420, p.mancha3),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Mancha extends StatelessWidget {
  const _Mancha(this.alignment, this.size, this.color);

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Texto legible sobre un color: oscuro sobre colores claros y blanco
/// sobre colores oscuros.
Color colorSobre(Color fondo) =>
    fondo.computeLuminance() > 0.5 ? const Color(0xFF14181F) : Colors.white;

/// Superficie de vidrio: desenfoque del fondo, relleno translúcido,
/// borde luminoso y un brillo en la esquina superior.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.blur = 22,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final double blur;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final p = GlassPalette.of(context);
    final borderRadius = BorderRadius.circular(radius);

    // El relleno va en su propia capa: BoxDecoration ignora `color`
    // cuando también recibe `gradient`.
    final superficie = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: tint ?? p.vidrio,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: p.borde),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, 0.45, 1],
            colors: [p.brilloA, p.brilloA.withValues(alpha: 0), p.brilloB],
          ),
        ),
        child: child,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: p.sombra,
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        // Con blur 0 se omite el desenfoque (más ligero en listas largas).
        child: blur > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: superficie,
              )
            : superficie,
      ),
    );
  }
}

/// Botón de vidrio que se "hunde" ligeramente al presionarlo.
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.circular = false,
    this.tint,
    this.tooltip,
    this.padding,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool circular;
  final Color? tint;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _presionado = false;

  void _presionar(bool valor) {
    if (widget.onPressed == null) return;
    setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radio = widget.circular ? 24.0 : 26.0;
    final colorContenido = widget.tint != null
        ? colorSobre(widget.tint!)
        : scheme.onSurface;

    Widget boton = AnimatedOpacity(
      opacity: widget.onPressed == null ? 0.6 : 1,
      duration: const Duration(milliseconds: 200),
      child: AnimatedScale(
        scale: _presionado ? 0.92 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: GlassContainer(
          radius: radio,
          tint: widget.tint,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onPressed,
              onTapDown: (_) => _presionar(true),
              onTapUp: (_) => _presionar(false),
              onTapCancel: () => _presionar(false),
              borderRadius: BorderRadius.circular(radio),
              child: Padding(
                padding:
                    widget.padding ??
                    (widget.circular
                        ? const EdgeInsets.all(12)
                        : const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          )),
                child: IconTheme.merge(
                  data: IconThemeData(size: 22, color: colorContenido),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colorContenido,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      boton = Tooltip(message: widget.tooltip, child: boton);
    }
    return boton;
  }
}

/// Hace "presionable" cualquier tarjeta: se encoge un poco al tocarla.
class Presionable extends StatefulWidget {
  const Presionable({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _presionado = true),
          onTapUp: (_) => setState(() => _presionado = false),
          onTapCancel: () => setState(() => _presionado = false),
          child: AnimatedScale(
            scale: _presionado ? 0.97 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Control segmentado de vidrio con un indicador que se desliza.
class GlassSegmented<T> extends StatelessWidget {
  const GlassSegmented({
    super.key,
    required this.opciones,
    required this.valor,
    required this.onCambio,
    this.alto = 48,
  });

  /// Pares valor → etiqueta.
  final List<(T, String)> opciones;
  final T valor;
  final ValueChanged<T> onCambio;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final p = GlassPalette.of(context);
    final indice = opciones.indexWhere((o) => o.$1 == valor);
    final n = opciones.length;

    return Container(
      height: alto,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: p.control,
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * indice / (n - 1), 0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: GlassContainer(
                radius: 14,
                blur: 8,
                tint: p.controlActivo,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Row(
            children: [
              for (final (v, texto) in opciones)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onCambio(v),
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: v == valor ? 1 : 0.55,
                        child: Text(
                          texto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
