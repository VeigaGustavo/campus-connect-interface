import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/snackbar_erro_api.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum TipoRecorteFotoPerfil {
  avatar,
  capa,
}

String _extensaoPorAssinatura(Uint8List bytes) {
  if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8) {
    return 'jpg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'png';
  }
  return 'jpg';
}

Future<({Uint8List bytes, String filename})?> mostrarTelaRecorteFotoPerfil(
  BuildContext context, {
  required Uint8List imagemOriginal,
  required TipoRecorteFotoPerfil tipo,
}) async {
  if (!context.mounted) return null;

  if (kIsWeb) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  if (!context.mounted) return null;

  return Navigator.of(context, rootNavigator: true).push<({Uint8List bytes, String filename})?>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => _TelaRecorteFotoPerfil(
        imagemOriginal: imagemOriginal,
        tipo: tipo,
      ),
    ),
  );
}

class _TelaRecorteFotoPerfil extends StatefulWidget {
  const _TelaRecorteFotoPerfil({
    required this.imagemOriginal,
    required this.tipo,
  });

  final Uint8List imagemOriginal;
  final TipoRecorteFotoPerfil tipo;

  @override
  State<_TelaRecorteFotoPerfil> createState() => _TelaRecorteFotoPerfilState();
}

class _TelaRecorteFotoPerfilState extends State<_TelaRecorteFotoPerfil> {
  final CropController _controller = CropController();

  bool _editorPronto = false;
  bool _aProcessarRecorte = false;
  int _desfazer = 0;
  int _refazer = 0;

  static const double _proporcaoCapa = 2.7;

  String get _titulo => switch (widget.tipo) {
        TipoRecorteFotoPerfil.avatar => 'Ajustar foto de perfil',
        TipoRecorteFotoPerfil.capa => 'Ajustar foto de capa',
      };

  void _confirmar() {
    if (!_editorPronto || _aProcessarRecorte) return;
    setState(() => _aProcessarRecorte = true);
    if (widget.tipo == TipoRecorteFotoPerfil.avatar) {
      _controller.cropCircle();
    } else {
      _controller.crop();
    }
  }

  void _onCropped(CropResult result) {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        final ext = _extensaoPorAssinatura(croppedImage);
        final nome = switch (widget.tipo) {
          TipoRecorteFotoPerfil.avatar => 'avatar.$ext',
          TipoRecorteFotoPerfil.capa => 'cover.$ext',
        };
        Navigator.of(context, rootNavigator: true).pop(
          (bytes: croppedImage, filename: nome),
        );
      case CropFailure(:final cause):
        setState(() => _aProcessarRecorte = false);
        showFloatingSnackBarMaybe(
          context,
          'Não foi possível recortar: $cause',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvatar = widget.tipo == TipoRecorteFotoPerfil.avatar;
    final dicaZoom = kIsWeb
        ? 'Roda do rato: zoom · Arrastar: mover a imagem'
        : 'Pinça com dois dedos: zoom · Arrastar: mover a imagem';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancelar',
          onPressed: _aProcessarRecorte
              ? null
              : () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Text(
          _titulo,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: (!_editorPronto || _aProcessarRecorte) ? null : _confirmar,
            child: _aProcessarRecorte
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.secondary,
                    ),
                  )
                : const Text(
                    'Usar',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.secondary,
                    ),
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              dicaZoom,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Desfazer',
                onPressed: (!_editorPronto || _desfazer == 0 || _aProcessarRecorte)
                    ? null
                    : () => _controller.undo(),
                icon: Icon(
                  Icons.undo_rounded,
                  color: _desfazer == 0
                      ? Colors.white24
                      : Colors.white.withValues(alpha: 0.9),
                ),
              ),
              IconButton(
                tooltip: 'Refazer',
                onPressed: (!_editorPronto || _refazer == 0 || _aProcessarRecorte)
                    ? null
                    : () => _controller.redo(),
                icon: Icon(
                  Icons.redo_rounded,
                  color: _refazer == 0
                      ? Colors.white24
                      : Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          Expanded(
            child: Crop(
              key: const ValueKey<String>('recorte_foto_perfil'),
              image: widget.imagemOriginal,
              controller: _controller,
              onCropped: _onCropped,
              aspectRatio: isAvatar ? 1 : _proporcaoCapa,
              withCircleUi: isAvatar,
              interactive: true,
              fixCropRect: true,
              baseColor: Colors.black,
              maskColor: Colors.black.withValues(alpha: 0.55),
              scrollZoomSensitivity: kIsWeb ? 0.11 : 0.07,
              progressIndicator: const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
              onStatusChanged: (status) {
                if (status == CropStatus.ready && mounted) {
                  setState(() => _editorPronto = true);
                }
              },
              onHistoryChanged: (h) {
                if (mounted) {
                  setState(() {
                    _desfazer = h.undoCount;
                    _refazer = h.redoCount;
                  });
                }
              },
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (!_editorPronto || _aProcessarRecorte) ? null : _confirmar,
                child: const Text(
                  'Usar esta área',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
