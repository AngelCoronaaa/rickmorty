import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import 'glass.dart';

const _opciones = [
  (ThemeMode.system, Icons.brightness_auto_rounded, 'Sistema'),
  (ThemeMode.light, Icons.light_mode_rounded, 'Claro'),
  (ThemeMode.dark, Icons.dark_mode_rounded, 'Oscuro'),
];

bool _esOscuro(BuildContext context, ThemeMode modo) => switch (modo) {
  ThemeMode.dark => true,
  ThemeMode.light => false,
  ThemeMode.system =>
    MediaQuery.platformBrightnessOf(context) == Brightness.dark,
};

/// Botón circular sol ↔ luna: al tocarlo alterna entre claro y oscuro con
/// una transición; al mantenerlo pulsado abre el selector (incluye "Sistema").
class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final oscuro = _esOscuro(context, controller.themeMode);

    return GestureDetector(
      onLongPress: () => mostrarSelectorTema(context),
      child: GlassButton(
        circular: true,
        tooltip: 'Cambiar aspecto',
        onPressed: () =>
            controller.setThemeMode(oscuro ? ThemeMode.light : ThemeMode.dark),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, anim) => RotationTransition(
            turns: Tween(begin: 0.4, end: 1.0).animate(anim),
            child: ScaleTransition(scale: anim, child: child),
          ),
          child: Icon(
            oscuro ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            key: ValueKey(oscuro),
          ),
        ),
      ),
    );
  }
}

/// Hoja inferior de vidrio para elegir el aspecto de la app.
Future<void> mostrarSelectorTema(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    elevation: 0,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassContainer(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aspecto',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              const ThemeSegmentedControl(),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Control segmentado Sistema / Claro / Oscuro.
class ThemeSegmentedControl extends StatelessWidget {
  const ThemeSegmentedControl({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context);
    final controller = AppScope.of(context).controller;
    final modo = controller.themeMode;
    final indice = _opciones.indexWhere((o) => o.$1 == modo);

    return Container(
      height: 76,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: p.colorScheme.onSurface.withValues(alpha: 0.07),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(-1 + indice * 1.0, 0),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            child: FractionallySizedBox(
              widthFactor: 1 / _opciones.length,
              heightFactor: 1,
              child: GlassContainer(
                radius: 18,
                blur: 8,
                tint: p.colorScheme.onSurface.withValues(alpha: 0.12),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Row(
            children: [
              for (final (valor, icono, etiqueta) in _opciones)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => controller.setThemeMode(valor),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: valor == modo ? 1 : 0.55,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icono, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            etiqueta,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
