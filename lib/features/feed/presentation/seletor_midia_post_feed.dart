import 'package:campus_connect_interface/features/feed/domain/repositorio_feed_posts.dart';
import 'package:campus_connect_interface/features/feed/presentation/pick_feed_video_browser.dart';
import 'package:campus_connect_interface/features/perfil/presentation/pick_profile_image_browser.dart';
import 'package:campus_connect_interface/features/perfil/presentation/secao_fotos_perfil.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const int kMaxPostImageBytes = 8 * 1024 * 1024;
const int kMaxPostVideoBytes = 80 * 1024 * 1024;

class PostAttachmentDraft {
  const PostAttachmentDraft({
    required this.type,
    required this.url,
    this.name,
    this.localPreviewBytes,
  });

  final FeedAttachmentType type;
  final String url;
  final String? name;
  final Uint8List? localPreviewBytes;

  FeedAttachment toAttachment() => FeedAttachment(
        type: type,
        url: url,
        name: name,
      );

  String get displayLabel => switch (type) {
        FeedAttachmentType.image => name ?? 'Imagem',
        FeedAttachmentType.video => name ?? 'Vídeo',
        FeedAttachmentType.link => name ?? url,
        FeedAttachmentType.file => name ?? 'Arquivo',
      };
}

Future<({Uint8List bytes, String filename})?> pickPostImageBytes(
  BuildContext context,
) async {
  if (kIsWeb) {
    return pickProfileImageInBrowser();
  }
  return _pickImageBytes(context);
}

Future<({Uint8List bytes, String filename})?> _pickImageBytes(
  BuildContext context,
) async {
  final source = await showPickImageSourceSheet(context);
  if (source == null || !context.mounted) return null;
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 88,
  );
  if (file == null) return null;
  return (bytes: await file.readAsBytes(), filename: file.name);
}

Future<({Uint8List bytes, String filename})?> pickPostVideoBytes(
  BuildContext context,
) => pickFeedVideoBytes(context);

Future<PostAttachmentDraft?> showAddPostLinkDialog(BuildContext context) async {
  final urlController = TextEditingController();
  final titleController = TextEditingController();
  final result = await showDialog<PostAttachmentDraft>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Adicionar link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://...',
            ),
            keyboardType: TextInputType.url,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Título (opcional)',
              hintText: 'Ex.: Artigo recomendado',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            var url = urlController.text.trim();
            if (url.isEmpty) return;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              url = 'https://$url';
            }
            final uri = Uri.tryParse(url);
            if (uri == null || !uri.hasAuthority) return;
            final title = titleController.text.trim();
            Navigator.pop(
              ctx,
              PostAttachmentDraft(
                type: FeedAttachmentType.link,
                url: url,
                name: title.isEmpty ? null : title,
              ),
            );
          },
          child: const Text('Adicionar'),
        ),
      ],
    ),
  );
  urlController.dispose();
  titleController.dispose();
  return result;
}

void assertAttachmentSize(FeedAttachmentType type, int byteLength) {
  final max = type == FeedAttachmentType.video
      ? kMaxPostVideoBytes
      : kMaxPostImageBytes;
  if (byteLength > max) {
    final mb = (max / (1024 * 1024)).round();
    throw FormatException('Arquivo muito grande. Limite: ${mb}MB.');
  }
}
