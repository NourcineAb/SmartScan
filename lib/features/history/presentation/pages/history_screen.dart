import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_scan/core/services/feedback_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animations/animations.dart';
import 'package:smart_scan/shared/models/scan_model.dart';
import 'package:smart_scan/features/scan/data/repositories/scan_repository.dart';
import 'package:smart_scan/features/scan/presentation/pages/scan_detail_screen.dart';
import 'package:smart_scan/features/scan/presentation/pages/export_options_screen.dart';
import 'package:smart_scan/features/history/presentation/pages/search_scans_screen.dart';
import 'package:smart_scan/core/utils/page_transition_utils.dart';
import 'package:smart_scan/features/scan/presentation/pages/text_editor_screen.dart';
import 'package:smart_scan/core/services/export_service.dart';
import 'package:smart_scan/core/services/database_service.dart';
import 'package:smart_scan/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../bloc/history_bloc.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HistoryBloc(
        scanRepository: ScanRepository(),
      )..add(const LoadScansEvent()),
      child: const _HistoryScreenContent(),
    );
  }
}

class _HistoryScreenContent extends StatefulWidget {
  const _HistoryScreenContent();

  @override
  State<_HistoryScreenContent> createState() => _HistoryScreenContentState();
}

class _HistoryScreenContentState extends State<_HistoryScreenContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _savedTranslations = [];
  bool _isLoadingSavedTranslations = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedTranslations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedTranslations() async {
    setState(() => _isLoadingSavedTranslations = true);
    try {
      final translations =
          await ScanRepository().getAllSavedTranslations(limit: 100);
      setState(() => _savedTranslations = translations);
    } catch (e) {
      debugPrint('Error loading saved translations: $e');
    } finally {
      setState(() => _isLoadingSavedTranslations = false);
    }
  }

  Future<void> _deleteSavedTranslation(String translationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Translation'),
        content: const Text(
          'Are you sure you want to delete this saved translation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ScanRepository().deleteSavedTranslation(translationId);
        if (context.mounted) {
          await _loadSavedTranslations();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Translation deleted'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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
            context.read<HistoryBloc>().add(DeleteScanEvent(scanId: scanId));
          } catch (e) {
            debugPrint('Warning: Could not access HistoryBloc: $e');
          }

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scan supprimé'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Refresh global dashboard bloc
          try {
            context.read<DashboardBloc>().add(const RefreshDashboardEvent());
          } catch (_) {
            debugPrint('Warning: Could not access DashboardBloc from HistoryScreen');
          }
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
        title: const Text('History'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.document_scanner),
              text: 'Scans',
            ),
            Tab(
              icon: Icon(Icons.translate),
              text: 'Saved Translations',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              final historyBloc = context.read<HistoryBloc>();
              Navigator.of(context).push(
                PageTransitionUtils.slideUpTransition<void>(
                  builder: (newContext) => BlocProvider.value(
                    value: historyBloc,
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
              if (_tabController.index == 0) {
                context.read<HistoryBloc>().add(const RefreshScansEvent());
              } else {
                _loadSavedTranslations();
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Scans
          _buildScansTab(),
          // Tab 2: Saved Translations
          _buildSavedTranslationsTab(),
        ],
      ),
    );
  }

  Widget _buildScansTab() {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is HistoryError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context
                      .read<HistoryBloc>()
                      .add(const RefreshScansEvent()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is HistoryEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'No Scans Yet',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan a document to get started',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        if (state is HistoryLoaded) {
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
    );
  }

  Widget _buildSavedTranslationsTab() {
    if (_isLoadingSavedTranslations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_savedTranslations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.translate_outlined, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No Saved Translations',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Save translations from the translation tool',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _savedTranslations.length,
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      itemBuilder: (context, index) {
        final translation = _savedTranslations[index];
        return _TranslationCard(
          translation: translation,
          onUpdate: _loadSavedTranslations,
          onDelete: () => _deleteSavedTranslation(translation['id'] as String),
        );
      },
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

  Widget _buildThumbnail(BuildContext context) {
    if (scan.imagePath != null && scan.imagePath!.isNotEmpty) {
      try {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(scan.imagePath!),
                width: 64,
                height: 64,
                cacheWidth: 200, // Optimize memory for thumbnails
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderThumb(context),
              ),
            ),
            if (scan.additionalImages != null &&
                scan.additionalImages!.length > 1)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${scan.additionalImages!.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      } catch (_) {}
    }
    return _placeholderThumb(context);
  }

  Widget _placeholderThumb(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.description, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 30),
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
          FeedbackService().onTap();
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
              _buildThumbnail(context),
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
                            size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(scan.createdAt),
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                        if (scan.additionalImages != null &&
                            scan.additionalImages!.length > 1) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.copy,
                              size: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${scan.additionalImages!.length} pages',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                          ),
                        ],
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
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
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
                    child: Row(children: [
                      Icon(Icons.delete, size: 18, color: Theme.of(context).colorScheme.error),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
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

class _TranslationCard extends StatelessWidget {
  final Map<String, dynamic> translation;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const _TranslationCard({
    required this.translation,
    required this.onUpdate,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getLanguageName(String code) {
    const names = {
      'en': 'English',
      'fr': 'Français',
      'ar': 'العربية',
      'es': 'Español',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'ja': '日本語',
      'zh': '中文',
    };
    return names[code] ?? code.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.parse(translation['created_at'] as String);
    final sourceLang = translation['source_language'] as String;
    final targetLang = translation['target_language'] as String;
    final originalText = translation['original_text'] as String;
    final translatedText = translation['translated_text'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language pair + Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${_getLanguageName(sourceLang)} → ${_getLanguageName(targetLang)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Original text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    originalText.length > 150
                        ? '${originalText.substring(0, 150)}…'
                        : originalText,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Translated text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Translation',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    translatedText.length > 150
                        ? '${translatedText.substring(0, 150)}…'
                        : translatedText,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.content_copy, size: 18),
                  tooltip: 'Copy translation',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: translatedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Translation copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Edit',
                  onPressed: () async {
                    await FeedbackService().onTap();
                    final edited = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TextEditorScreen(initialText: translatedText),
                      ),
                    );

                    if (edited != null && edited != translatedText) {
                      try {
                        final db = DatabaseService();
                        await db.updateSavedTranslation(
                          translation['id'] as String,
                          edited,
                        );
                        onUpdate(); // Refresh the list without deleting
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Translation updated'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating translation: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.ios_share, size: 18),
                  tooltip: 'Export',
                  onPressed: () async {
                    await FeedbackService().onTap();
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.picture_as_pdf),
                              title: const Text('Export as PDF'),
                              onTap: () async {
                                Navigator.pop(context);
                                try {
                                  await ExportService().exportTranslation(
                                    title: 'Translation_${translation['id']}',
                                    originalText: translation['original_text'] ?? '',
                                    translatedText: translatedText,
                                    sourceLanguage: translation['source_language'] ?? 'auto',
                                    targetLanguage: targetLang,
                                    format: 'pdf',
                                  );
                                  await FeedbackService().onSuccess();
                                } catch (e) {
                                  debugPrint('PDF export failed: $e');
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.description),
                              title: const Text('Export as Word (.docx)'),
                              onTap: () async {
                                Navigator.pop(context);
                                try {
                                  await ExportService().exportTranslation(
                                    title: 'Translation_${translation['id']}',
                                    originalText: translation['original_text'] ?? '',
                                    translatedText: translatedText,
                                    sourceLanguage: translation['source_language'] ?? 'auto',
                                    targetLanguage: targetLang,
                                    format: 'docx',
                                  );
                                  await FeedbackService().onSuccess();
                                } catch (e) {
                                  debugPrint('Word export failed: $e');
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.code),
                              title: const Text('Export as XML'),
                              onTap: () async {
                                Navigator.pop(context);
                                try {
                                  await ExportService().exportTranslation(
                                    title: 'Translation_${translation['id']}',
                                    originalText: translation['original_text'] ?? '',
                                    translatedText: translatedText,
                                    sourceLanguage: translation['source_language'] ?? 'auto',
                                    targetLanguage: targetLang,
                                    format: 'xml',
                                  );
                                  await FeedbackService().onSuccess();
                                } catch (e) {
                                  debugPrint('XML export failed: $e');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () async {
                    await FeedbackService().onTap();
                    onDelete();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
