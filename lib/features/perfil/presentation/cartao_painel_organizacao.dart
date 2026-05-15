import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/perfil/domain/perfil_usuario.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cartão com totais do `organization_panel` e pré-visualização das listas (contrato v2).
class OrganizationPanelCard extends StatelessWidget {
  const OrganizationPanelCard({
    super.key,
    required this.panel,
    required this.profileType,
  });

  final OrganizationPanel panel;
  final AccountProfileType profileType;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                color: AppColors.primary.withValues(alpha: 0.95),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Painel da organização',
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
            'Conteúdo publicado por esta conta (amostra até 12 itens por lista na API).',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
          if (panel.parentInstitution != null) ...[
            const SizedBox(height: 14),
            _infoRow(
              icon: Icons.apartment_outlined,
              label: 'Instituição vinculada',
              value: panel.parentInstitution!,
            ),
          ],
          if (panel.mapUrl != null && panel.mapUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openMap(context, panel.mapUrl!.trim()),
                icon: const Icon(Icons.map_outlined, size: 20),
                label: const Text('Abrir mapa / localização'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (profileType == AccountProfileType.empresa) ...[
            _listPreview('Vagas', panel.jobs, panel.jobsTotal, Icons.work_outline_rounded),
            _listPreview('Eventos', panel.events, panel.eventsTotal, Icons.event_available_outlined),
            _listPreview('Posts', _postsAsListed(panel.posts), panel.postsTotal, Icons.article_outlined),
          ] else if (profileType == AccountProfileType.universidade) ...[
            _listPreview('Eventos', panel.events, panel.eventsTotal, Icons.event_available_outlined),
            _listPreview('Posts', _postsAsListed(panel.posts), panel.postsTotal, Icons.article_outlined),
          ] else if (profileType == AccountProfileType.comunidade) ...[
            _listPreview('Grupos', panel.groups, panel.groupsTotal, Icons.groups_2_outlined),
            _listPreview('Eventos', panel.events, panel.eventsTotal, Icons.event_available_outlined),
            _listPreview('Posts', _postsAsListed(panel.posts), panel.postsTotal, Icons.article_outlined),
          ] else ...[
            _listPreview('Eventos', panel.events, panel.eventsTotal, Icons.event_available_outlined),
            _listPreview('Posts', _postsAsListed(panel.posts), panel.postsTotal, Icons.article_outlined),
          ],
        ],
      ),
    );
  }

  List<OrganizationPanelListedItem> _postsAsListed(List<OrganizationPanelPost> posts) {
    return posts
        .map(
          (p) => OrganizationPanelListedItem(
            id: p.id,
            title: p.preview.length > 80 ? '${p.preview.substring(0, 80)}…' : p.preview,
            subtitle: '',
            referenceId: p.id,
            createdAt: p.createdAt,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _openMap(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL do mapa inválida.')),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary.withValues(alpha: 0.85)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _listPreview(
    String title,
    List<OrganizationPanelListedItem> items,
    int total,
    IconData icon,
  ) {
    if (total == 0 && items.isEmpty) return const SizedBox.shrink();
    final preview = items.take(3).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '$title ($total)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (preview.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Nenhum item na amostra.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                ),
              ),
            )
          else
            ...preview.map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.chipBorder.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title.isNotEmpty ? e.title : '(sem título)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (e.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          e.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
