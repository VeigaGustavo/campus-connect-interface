import 'dart:typed_data';

import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/rede/excecao_api.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/snackbar_erro_api.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/feed/domain/repositorio_feed_posts.dart';
import 'package:campus_connect_interface/features/feed/presentation/seletor_midia_post_feed.dart';
import 'package:flutter/material.dart';

Future<String?> showCreateFeedPostModal(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const CreateFeedPostSheet(),
  );
}

class CreateFeedPostSheet extends StatefulWidget {
  const CreateFeedPostSheet({super.key});

  @override
  State<CreateFeedPostSheet> createState() => _CreateFeedPostSheetState();
}

class _CreateFeedPostSheetState extends State<CreateFeedPostSheet> {
  final _textController = TextEditingController();
  FeedPostContentKind _contentKind = FeedPostContentKind.simple;
  final List<PostAttachmentDraft> _attachments = [];
  bool _submitting = false;

  static const _kinds = FeedPostContentKind.values;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  IconData _iconFor(FeedPostContentKind k) => switch (k) {
        FeedPostContentKind.simple => Icons.chat_bubble_outline_rounded,
        FeedPostContentKind.article => Icons.article_outlined,
        FeedPostContentKind.campusNews => Icons.newspaper_outlined,
        FeedPostContentKind.magazine => Icons.menu_book_outlined,
        FeedPostContentKind.notice => Icons.campaign_outlined,
        FeedPostContentKind.project => Icons.lightbulb_outline_rounded,
      };

  IconData _attachmentIcon(FeedAttachmentType t) => switch (t) {
        FeedAttachmentType.image => Icons.image_outlined,
        FeedAttachmentType.video => Icons.videocam_outlined,
        FeedAttachmentType.link => Icons.link_rounded,
        FeedAttachmentType.file => Icons.attach_file_rounded,
      };

  Future<void> _addImage() async {
    if (_submitting) return;
    final picked = await pickPostImageBytes(context);
    if (picked == null || !mounted) return;
    try {
      assertAttachmentSize(FeedAttachmentType.image, picked.bytes.length);
    } on FormatException catch (e) {
      if (!mounted) return;
      showFloatingSnackBar(context, e.message);
      return;
    }
    await _uploadBytes(
      bytes: picked.bytes,
      filename: picked.filename,
      type: FeedAttachmentType.image,
      previewBytes: picked.bytes,
    );
  }

  Future<void> _addVideo() async {
    if (_submitting) return;
    final picked = await pickPostVideoBytes(context);
    if (picked == null || !mounted) return;
    try {
      assertAttachmentSize(FeedAttachmentType.video, picked.bytes.length);
    } on FormatException catch (e) {
      if (!mounted) return;
      showFloatingSnackBar(context, e.message);
      return;
    }
    await _uploadBytes(
      bytes: picked.bytes,
      filename: picked.filename,
      type: FeedAttachmentType.video,
    );
  }

  Future<void> _addLink() async {
    if (_submitting) return;
    final draft = await showAddPostLinkDialog(context);
    if (draft == null || !mounted) return;
    setState(() => _attachments.add(draft));
  }

  Future<void> _uploadBytes({
    required List<int> bytes,
    required String filename,
    required FeedAttachmentType type,
    List<int>? previewBytes,
  }) async {
    setState(() => _submitting = true);
    try {
      final repo = DependencyScope.of(context).feedPostsRepository;
      final uploaded = await repo.uploadAttachment(
        bytes: bytes,
        filename: filename,
        type: type,
      );
      if (!mounted) return;
      setState(() {
        _attachments.add(
          PostAttachmentDraft(
            type: uploaded.type,
            url: uploaded.url,
            name: uploaded.name ?? filename,
            localPreviewBytes: previewBytes != null
                ? Uint8List.fromList(previewBytes)
                : null,
          ),
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      showApiErrorSnackBar(context, e);
    } catch (e) {
      if (!mounted) return;
      showFloatingSnackBar(context, '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _attachments.isEmpty) {
      showFloatingSnackBar(
        context,
        'Escreva um texto ou adicione um anexo.',
      );
      return;
    }
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      final repo = DependencyScope.of(context).feedPostsRepository;
      final post = await repo.createPost(
        CreatePostRequest(
          text: text,
          contentKind: _contentKind,
          attachments: _attachments.map((a) => a.toAttachment()).toList(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(post.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      showApiErrorSnackBar(context, e);
    } catch (e) {
      if (!mounted) return;
      showFloatingSnackBar(context, 'Erro ao publicar: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Material(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.chipBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const Expanded(
                        child: Text(
                          'Novo post',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Publicar',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    children: [
                      SoftCard(
                        padding: const EdgeInsets.all(14),
                        child: TextField(
                          controller: _textController,
                          enabled: !_submitting,
                          maxLines: 6,
                          minLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'O que você quer compartilhar?',
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Anexos (opcional)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _mediaButton(
                            icon: Icons.image_outlined,
                            label: 'Imagem',
                            onTap: _addImage,
                          ),
                          const SizedBox(width: 8),
                          _mediaButton(
                            icon: Icons.videocam_outlined,
                            label: 'Vídeo',
                            onTap: _addVideo,
                          ),
                          const SizedBox(width: 8),
                          _mediaButton(
                            icon: Icons.link_rounded,
                            label: 'Link',
                            onTap: _addLink,
                          ),
                        ],
                      ),
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ..._attachments.asMap().entries.map((e) {
                          final i = e.key;
                          final a = e.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SoftCard(
                              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                              child: Row(
                                children: [
                                  if (a.type == FeedAttachmentType.image &&
                                      a.localPreviewBytes != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        a.localPreviewBytes!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _attachmentIcon(a.type),
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a.displayLabel,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (a.type == FeedAttachmentType.link)
                                          Text(
                                            a.url,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary
                                                  .withValues(alpha: 0.9),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _submitting
                                        ? null
                                        : () => setState(
                                              () => _attachments.removeAt(i),
                                            ),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        'Tipo de conteúdo (opcional)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Se não escolher, será um post simples.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: _kinds.map((k) {
                          final selected = _contentKind == k;
                          return FilterChip(
                            avatar: Icon(
                              _iconFor(k),
                              size: 18,
                              color: selected
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                            label: Text(k.labelPt),
                            selected: selected,
                            onSelected: _submitting
                                ? null
                                : (v) {
                                    if (!v) return;
                                    setState(() => _contentKind = k);
                                  },
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.chipBorder,
                            ),
                            showCheckmark: false,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _mediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: _submitting ? null : onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.chipBorder),
        ),
      ),
    );
  }
}
