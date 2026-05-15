import 'package:campus_connect_interface/core/configuracao/configuracao_api.dart';
import 'package:campus_connect_interface/core/rede/excecao_api.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/perfil/domain/repositorio_perfil.dart';
import 'package:campus_connect_interface/features/perfil/presentation/pick_profile_image_browser.dart';
import 'package:campus_connect_interface/features/perfil/presentation/tela_recorte_foto_perfil.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const int _kMaxImageBytes = 6 * 1024 * 1024;

String _mensagemErroUploadFoto(ApiException e, {required bool isAvatar}) {
  final path = isAvatar
      ? ApiConfig.profileAvatarUploadPath
      : ApiConfig.profileCoverUploadPath;
  final campo = isAvatar ? 'avatar' : 'cover';
  if (e.isNotFound) {
    return 'POST $path não encontrado (404). Reinicie a API (rebuild) e confira '
        'no log do Gin: POST $path';
  }
  if (e.statusCode == 400) {
    return 'O servidor não recebeu o ficheiro (400). O campo multipart deve ser '
        '"$campo" com bytes da imagem, não a URL blob: do browser.';
  }
  if (e.isUnauthorized) {
    return 'Sessão expirada. Faça login novamente.';
  }
  return 'Não foi possível enviar a foto (${e.statusCode}).';
}

Future<ImageSource?> showPickImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Câmera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    },
  );
}

void _showBlockingLoader(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: CircularProgressIndicator(),
        ),
      ),
    ),
  );
}

void _hideBlockingLoader(BuildContext context) {
  final nav = Navigator.of(context, rootNavigator: true);
  if (nav.canPop()) nav.pop();
}

/// Na web o `image_picker` costuma falhar com MissingPluginException; o
/// `file_picker` depende do registrador de plugins e também pode falhar
/// (`LateInitializationError`). Usamos `<input type="file">` via `dart:html`
/// (import condicional).
Future<({Uint8List bytes, String filename})?> _pickImageBytes({
  required BuildContext context,
  required double maxWidth,
  required double maxHeight,
  required int imageQuality,
}) async {
  if (kIsWeb) {
    final r = await pickProfileImageInBrowser();
    if (r == null) return null;
    final shrunk = await shrinkProfileImageBytesForWeb(r.bytes);
    final name = r.filename.trim().isEmpty ? 'image.jpg' : r.filename;
    return (bytes: shrunk, filename: name);
  }

  final source = await showPickImageSourceSheet(context);
  if (source == null || !context.mounted) return null;

  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: source,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    imageQuality: imageQuality,
  );
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  final name = file.name.trim().isEmpty ? 'image.jpg' : file.name;
  return (bytes: bytes, filename: name);
}

Future<bool> pickAndUploadProfileAvatar({
  required BuildContext context,
  required ProfileRepository repo,
}) async {
  final picked = await _pickImageBytes(
    context: context,
    maxWidth: 4096,
    maxHeight: 4096,
    imageQuality: 92,
  );
  if (picked == null || !context.mounted) return false;

  final bytes = picked.bytes;
  if (bytes.length > _kMaxImageBytes) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imagem muito grande. Escolha uma foto de até 6 MB.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }

  final recortado = await mostrarTelaRecorteFotoPerfil(
    context,
    imagemOriginal: bytes,
    tipo: TipoRecorteFotoPerfil.avatar,
  );
  if (recortado == null || !context.mounted) return false;

  final bytesParaEnvio = recortado.bytes;
  if (bytesParaEnvio.length > _kMaxImageBytes) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imagem muito grande. Escolha uma foto de até 6 MB.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }

  final name = recortado.filename.trim().isEmpty ? 'avatar.jpg' : recortado.filename;
  if (!context.mounted) return false;
  _showBlockingLoader(context);
  try {
    await repo.uploadProfileAvatar(bytes: bytesParaEnvio, filename: name);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil atualizada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mensagemErroUploadFoto(e, isAvatar: true)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    }
    return false;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar foto: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  } finally {
    if (context.mounted) _hideBlockingLoader(context);
  }
}

Future<bool> pickAndUploadProfileCover({
  required BuildContext context,
  required ProfileRepository repo,
}) async {
  final picked = await _pickImageBytes(
    context: context,
    maxWidth: 4096,
    maxHeight: 4096,
    imageQuality: 92,
  );
  if (picked == null || !context.mounted) return false;

  final bytes = picked.bytes;
  if (bytes.length > _kMaxImageBytes) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imagem muito grande. Escolha uma foto de até 6 MB.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }

  final recortado = await mostrarTelaRecorteFotoPerfil(
    context,
    imagemOriginal: bytes,
    tipo: TipoRecorteFotoPerfil.capa,
  );
  if (recortado == null || !context.mounted) return false;

  final bytesParaEnvio = recortado.bytes;
  if (bytesParaEnvio.length > _kMaxImageBytes) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imagem muito grande. Escolha uma foto de até 6 MB.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }

  final name = recortado.filename.trim().isEmpty ? 'cover.jpg' : recortado.filename;
  if (!context.mounted) return false;
  _showBlockingLoader(context);
  try {
    await repo.uploadProfileCover(bytes: bytesParaEnvio, filename: name);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de capa atualizada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mensagemErroUploadFoto(e, isAvatar: false)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    }
    return false;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar capa: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  } finally {
    if (context.mounted) _hideBlockingLoader(context);
  }
}

/// Blocos para alterar avatar e capa nas configurações do perfil.
class ProfilePhotosSection extends StatefulWidget {
  const ProfilePhotosSection({
    super.key,
    required this.repo,
    required this.onPhotosChanged,
  });

  final ProfileRepository repo;
  final VoidCallback onPhotosChanged;

  @override
  State<ProfilePhotosSection> createState() => _ProfilePhotosSectionState();
}

class _ProfilePhotosSectionState extends State<ProfilePhotosSection> {
  bool _busyAvatar = false;
  bool _busyCover = false;

  Future<void> _avatar() async {
    if (_busyAvatar) return;
    setState(() => _busyAvatar = true);
    final ok = await pickAndUploadProfileAvatar(
      context: context,
      repo: widget.repo,
    );
    if (ok) widget.onPhotosChanged();
    if (mounted) setState(() => _busyAvatar = false);
  }

  Future<void> _cover() async {
    if (_busyCover) return;
    setState(() => _busyCover = true);
    final ok = await pickAndUploadProfileCover(
      context: context,
      repo: widget.repo,
    );
    if (ok) widget.onPhotosChanged();
    if (mounted) setState(() => _busyCover = false);
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_camera_outlined,
                color: AppColors.primary.withValues(alpha: 0.95),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Fotos do perfil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Foto de perfil e imagem de capa visíveis na sua página.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.face_retouching_natural_outlined),
            title: const Text('Foto de perfil'),
            subtitle: const Text('Aparece no avatar e nas listagens.'),
            trailing: _busyAvatar
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _avatar,
                    child: const Text('Alterar'),
                  ),
          ),
          Divider(height: 1, color: AppColors.chipBorder.withValues(alpha: 0.65)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.panorama_wide_angle_select_outlined),
            title: const Text('Foto de capa'),
            subtitle: const Text('Banner no topo do perfil.'),
            trailing: _busyCover
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _cover,
                    child: const Text('Alterar'),
                  ),
          ),
        ],
      ),
    );
  }
}
