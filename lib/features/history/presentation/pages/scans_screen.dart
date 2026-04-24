import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animations/animations.dart';
import 'package:smart_scan/shared/models/scan_model.dart';
import 'package:smart_scan/features/scan/data/repositories/scan_repository.dart';
import 'package:smart_scan/features/scan/presentation/pages/scan_detail_screen.dart';
import 'package:smart_scan/features/scan/presentation/pages/export_options_screen.dart';
import 'package:smart_scan/features/history/presentation/pages/search_scans_screen.dart';
import 'package:smart_scan/core/utils/page_transition_utils.dart';
import 'package:smart_scan/core/services/feedback_service.dart';
import '../bloc/scans_bloc.dart';

class ScansScreen extends StatelessWidget {
  const ScansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScansBloc(
        scanRepository: ScanRepository(),
      )..add(const LoadScansEvent()),
      child: const _ScansScreenContent(),
    );
  }
}

class _ScansScreenContent extends StatelessWidget {
  const _ScansScreenContent();

  Future<void> _deleteScan(BuildContext context, String scanId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le scan'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce scan et son image? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Delete from repository
        await ScanRepository().deleteScan(scanId);

        if (context.mounted) {
          // Update bloc
          try {
            context.read<ScansBloc>().add(DeleteScanEvent(scanId: scanId));
          } catch (e) {
            debugPrint('Warning: Could not access ScansBloc: $e');
          }

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scan supprimé'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Scans'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await FeedbackService().onTap();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              final scansBloc = context.read<ScansBloc>();
              Navigator.of(context).push(
                PageTransitionUtils.slideUpTransition<void>(
                  builder: (newContext) => BlocProvider.value(
                    value: scansBloc,
                    child: const SearchScansScreen(),
                  ),
                  routeName: '/search-scans',
                ),
              );
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ScansBloc>().add(const RefreshScansEvent());
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<ScansBloc, ScansState>(
        builder: (context, state) {
          if (state is ScansLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ScansError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[700])),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context
                        .read<ScansBloc>()
                        .add(const RefreshScansEvent()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ScansEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Scans Yet',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan a document to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          if (state is ScansLoaded) {
            return ListView.builder(
              itemCount: state.scans.length,
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              itemBuilder: (context, index) {
                final scan = state.scans[index];
                return _ScanCard(
                  scan: scan,
                  categoryName: scan.categoryId != null
                      ? state.categoryNames[scan.categoryId]
                      : null,
                  categoryColor: scan.categoryId != null
                      ? state.categoryColors[scan.categoryId]
                      : null,
                  onDelete: () => _deleteScan(context, scan.id),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final ScanModel scan;
  final String? categoryName;
  final int? categoryColor;
  final VoidCallback onDelete;

  const _ScanCard({
    required this.scan,
    required this.categoryName,
    required this.categoryColor,
    required this.onDelete,
  });

  Widget _buildThumbnail() {
    if (scan.imagePath != null && scan.imagePath!.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(scan.imagePath!),
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholderThumb(),
          ),
        );
      } catch (_) {}
    }
    return _placeholderThumb();
  }

  Widget _placeholderThumb() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.description, color: Colors.indigo[300], size: 30),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            PageTransitionUtils.sharedAxisTransition<void>(
              context: context,
              builder: (context) => ScanDetailScreen(scan: scan),
              routeName: '/scan-detail',
              transitionType: SharedAxisTransitionType.vertical,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              _buildThumbnail(),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(scan.createdAt),
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    if (categoryName != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: categoryColor != null
                              ? Color(categoryColor!).withValues(alpha: 0.15)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: categoryColor != null
                                ? Color(categoryColor!).withValues(alpha: 0.5)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          categoryName!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: categoryColor != null
                                ? Color(categoryColor!)
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                    if (scan.rawText != null && scan.rawText!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        scan.rawText!.length > 70
                            ? '${scan.rawText!.substring(0, 70)}…'
                            : scan.rawText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(children: [
                      Icon(Icons.open_in_new, size: 18),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ]),
                    onTap: () {
                      final nav = Navigator.of(context);
                      Future.delayed(Duration.zero, () {
                        nav.push(
                          MaterialPageRoute(
                            builder: (_) => ScanDetailScreen(scan: scan),
                          ),
                        );
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: const Row(children: [
                      Icon(Icons.file_download, size: 18),
                      SizedBox(width: 8),
                      Text('Export'),
                    ]),
                    onTap: () {
                      final nav = Navigator.of(context);
                      Future.delayed(Duration.zero, () {
                        nav.push(
                          MaterialPageRoute(
                            builder: (_) => ExportOptionsScreen(scan: scan),
                          ),
                        );
                      });
                    },
                  ),
                  PopupMenuItem(
                    onTap: onDelete,
                    child: const Row(children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
