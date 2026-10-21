import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../models/character.dart';
import '../theme/app_theme.dart';
import '../widgets/aparecer.dart';
import '../widgets/character_widgets.dart';
import '../widgets/glass.dart';
import '../widgets/theme_selector.dart';

/// Formulario para agregar un personaje o editar uno existente.
/// Al guardar cierra devolviendo el personaje resultante.
class CharacterFormScreen extends StatefulWidget {
  const CharacterFormScreen({super.key, this.personaje});

  /// `null` para crear uno nuevo.
  final Character? personaje;

  @override
  State<CharacterFormScreen> createState() => _CharacterFormScreenState();
}

class _CharacterFormScreenState extends State<CharacterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Character? _original = widget.personaje;
  late final _nombre = TextEditingController(text: _original?.name);
  late final _especie = TextEditingController(text: _original?.species);
  late final _tipo = TextEditingController(text: _original?.type);
  late final _origen = TextEditingController(text: _original?.origin);
  late final _ubicacion = TextEditingController(text: _original?.location);
  late final _imagen = TextEditingController(text: _original?.image);
  late Estado _estado = _original?.status ?? Estado.alive;
  late Genero _genero = _original?.gender ?? Genero.male;
  bool _guardando = false;

  bool get _edicion => _original != null;

  @override
  void dispose() {
    for (final c in [_nombre, _especie, _tipo, _origen, _ubicacion, _imagen]) {
      c.dispose();
    }
    super.dispose();
  }

  static final _soloTexto = RegExp(r"^[\p{L}\p{N} .,'()\-_/]+$", unicode: true);

  String? Function(String?) _obligatorio(
    String que, {
    int min = 2,
    int max = 40,
  }) => (valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Escribe $que';
    if (texto.length < min) return 'Escribe al menos $min caracteres';
    if (texto.length > max) return 'Máximo $max caracteres';
    if (!_soloTexto.hasMatch(texto)) return 'Hay caracteres no permitidos';
    return null;
  };

  String? _opcional(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return null;
    if (texto.length > 40) return 'Máximo 40 caracteres';
    if (!_soloTexto.hasMatch(texto)) return 'Hay caracteres no permitidos';
    return null;
  }

  String? _validarImagen(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return null;
    final uri = Uri.tryParse(texto);
    final valida =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.contains('.');
    return valida ? null : 'Escribe un enlace válido (http o https)';
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _guardando = true);

    final characters = AppScope.read(context).characters;
    final base =
        _original ??
        const Character(
          id: 0,
          name: '',
          status: Estado.alive,
          species: '',
          gender: Genero.male,
          origin: '',
        );
    final c = base.copyWith(
      name: _nombre.text.trim(),
      species: _especie.text.trim(),
      type: _tipo.text.trim(),
      origin: _origen.text.trim(),
      location: _ubicacion.text.trim(),
      image: _imagen.text.trim(),
      status: _estado,
      gender: _genero,
    );

    final Character resultado;
    if (_edicion) {
      await characters.editar(c);
      resultado = c;
    } else {
      resultado = await characters.agregar(c);
    }
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return LiquidBackground(
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  Row(
                    children: [
                      GlassButton(
                        circular: true,
                        tooltip: 'Volver',
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close_rounded),
                      ),
                      const Spacer(),
                      const ThemeButton(),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _edicion ? 'Editar personaje' : 'Nuevo personaje',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Aparecer(orden: 1, child: _formulario()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    return Form(
      key: _formKey,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _vistaPrevia(),
            const SizedBox(height: 22),
            _campo(
              'Nombre',
              _nombre,
              'Ej. Rick Sanchez',
              Icons.badge_rounded,
              _obligatorio('el nombre'),
              capitalizar: true,
            ),
            _campo(
              'Especie',
              _especie,
              'Ej. Human',
              Icons.biotech_rounded,
              _obligatorio('la especie'),
              capitalizar: true,
            ),
            const _Etiqueta('Estado'),
            _Opciones<Estado>(
              valores: Estado.values,
              seleccionado: _estado,
              nombre: (e) => e.etiqueta,
              color: (e) => e.color,
              onCambio: (e) => setState(() => _estado = e),
            ),
            const SizedBox(height: 18),
            const _Etiqueta('Género'),
            _Opciones<Genero>(
              valores: Genero.values,
              seleccionado: _genero,
              nombre: (g) => g.etiqueta,
              onCambio: (g) => setState(() => _genero = g),
            ),
            const SizedBox(height: 18),
            _campo(
              'Origen',
              _origen,
              'Ej. Earth (C-137)',
              Icons.public_rounded,
              _obligatorio('el origen'),
              capitalizar: true,
            ),
            _campo(
              'Última ubicación (opcional)',
              _ubicacion,
              'Ej. Citadel of Ricks',
              Icons.place_rounded,
              _opcional,
              capitalizar: true,
            ),
            _campo(
              'Tipo (opcional)',
              _tipo,
              'Ej. Genetic experiment',
              Icons.category_rounded,
              _opcional,
              capitalizar: true,
            ),
            _campo(
              'Imagen (opcional)',
              _imagen,
              'https://…/foto.jpg',
              Icons.image_rounded,
              _validarImagen,
              teclado: TextInputType.url,
              ultimo: true,
              alCambiar: () => setState(() {}),
            ),
            const SizedBox(height: 8),
            GlassButton(
              tint: AppTheme.verdePortal.withValues(alpha: 0.92),
              onPressed: _guardando ? null : _guardar,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_edicion ? Icons.save_rounded : Icons.add_rounded),
                  const SizedBox(width: 10),
                  Text(
                    _guardando
                        ? 'Guardando…'
                        : _edicion
                        ? 'Guardar cambios'
                        : 'Agregar personaje',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Foto con los datos escritos hasta ahora.
  Widget _vistaPrevia() {
    final imagen = _imagen.text.trim();
    final c = Character(
      id: 0,
      name: _nombre.text,
      status: _estado,
      species: _especie.text,
      gender: _genero,
      origin: _origen.text,
      image: _validarImagen(imagen) == null ? imagen : '',
    );
    return Center(
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _estado.color, width: 3),
          boxShadow: [
            BoxShadow(
              color: _estado.color.withValues(alpha: 0.4),
              blurRadius: 22,
            ),
          ],
        ),
        child: ClipOval(child: CharacterImage(c)),
      ),
    );
  }

  Widget _campo(
    String etiqueta,
    TextEditingController controller,
    String hint,
    IconData icono,
    String? Function(String?) validador, {
    bool capitalizar = false,
    bool ultimo = false,
    TextInputType? teclado,
    VoidCallback? alCambiar,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Etiqueta(etiqueta),
          TextFormField(
            controller: controller,
            keyboardType: teclado,
            textCapitalization: capitalizar
                ? TextCapitalization.words
                : TextCapitalization.none,
            textInputAction: ultimo
                ? TextInputAction.done
                : TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: validador,
            onChanged: (_) => setState(() {}),
            onFieldSubmitted: ultimo ? (_) => _guardar() : null,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icono),
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Elección única entre varias opciones, con chips de vidrio.
class _Opciones<T> extends StatelessWidget {
  const _Opciones({
    required this.valores,
    required this.seleccionado,
    required this.nombre,
    required this.onCambio,
    this.color,
  });

  final List<T> valores;
  final T seleccionado;
  final String Function(T) nombre;
  final Color Function(T)? color;
  final ValueChanged<T> onCambio;

  @override
  Widget build(BuildContext context) {
    final p = GlassPalette.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in valores)
          Presionable(
            onTap: () {
              HapticFeedback.selectionClick();
              onCambio(v);
            },
            semanticLabel: nombre(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: v == seleccionado
                    ? (color?.call(v) ?? AppTheme.verdePortal).withValues(
                        alpha: 0.28,
                      )
                    : p.control,
                border: Border.all(
                  color: v == seleccionado
                      ? (color?.call(v) ?? AppTheme.verdePortal)
                      : p.borde,
                  width: v == seleccionado ? 1.5 : 1,
                ),
              ),
              child: Text(
                nombre(v),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: v == seleccionado
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: onSurface.withValues(
                    alpha: v == seleccionado ? 1 : 0.75,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
