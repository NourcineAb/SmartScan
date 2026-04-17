import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_scan/features/scan/data/repositories/scan_repository.dart';
import 'package:smart_scan/features/scan/presentation/pages/scan_detail_screen.dart';
import 'package:smart_scan/features/scan/presentation/pages/export_options_screen.dart';
import 'package:smart_scan/shared/models/scan_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/category_model.dart';
import '../../../../core/services/feedback_service.dart';

class CategoryDocumentsScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryDocumentsScreen({super.key, required this.category});

  @override
  State<CategoryDocumentsScreen> createState() =>
      _CategoryDocumentsScreenState();
}

class _CategoryDocumentsScreenState extends State<CategoryDocumentsScreen> {
  late Future<List<ScanModel>> _scansFuture;

  @override
  void initState() {
    super.initState();
    _scansFuture = ScanRepository().getScansByCategory(widget.category.id);
  }

  void _refresh() {
    setState(() {
      _scansFuture = ScanRepository().getScansByCategory(widget.category.id);
    });
  }

  Future<void> _deleteScan(ScanModel scan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Scan?'),
        content: Text('Delete "${scan.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ScanRepository().deleteScan(scan.id);
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Scan deleted'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final catColor = Color(widget.category.color);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
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
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: 'Refresh'),
        ],
      ),
      body: FutureBuilder<List<ScanModel>>(
        future: _scansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final scans = snapshot.data ?? [];
          if (scans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No documents in this category',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Scan a document and assign it here'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scans.length,
            itemBuilder: (context, i) {
              final scan = scans[i];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: scan.imagePath != null && scan.imagePath!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(scan.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.description, color: catColor),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.description,
                                color: catColor, size: 24),
                          ),
                  ),
                  title: Text(scan.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_formatDate(scan.createdAt),
                      style: const TextStyle(fontSize: 12)),
                  trailing: PopupMenuButton(
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        child: const Row(children: [
                          Icon(Icons.open_in_new, size: 18),
                          SizedBox(width: 8),
                          Text('View')
                        ]),
                        onTap: () {
                          final nav = Navigator.of(context);
                          Future.delayed(Duration.zero, () {
                            nav.push(
                              MaterialPageRoute(
                                  builder: (_) => ScanDetailScreen(scan: scan)),
                            );
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(children: [
                          Icon(Icons.file_download, size: 18),
                          SizedBox(width: 8),
                          Text('Export')
                        ]),
                        onTap: () {
                          final nav = Navigator.of(context);
                          Future.delayed(Duration.zero, () {
                            nav.push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ExportOptionsScreen(scan: scan)),
                            );
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(children: [
                          Icon(Icons.delete, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: AppColors.error))
                        ]),
                        onTap: () => _deleteScan(scan),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ScanDetailScreen(scan: scan)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
