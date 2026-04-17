import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/shared/models/scan_model.dart';
import 'package:smart_scan/features/scan/data/repositories/scan_repository.dart';
import 'package:smart_scan/features/history/presentation/bloc/scans_bloc.dart';
import 'package:smart_scan/features/scan/presentation/pages/export_options_screen.dart';
import 'package:smart_scan/features/translation/presentation/pages/translation_screen.dart';
import 'dart:io';
import 'package:smart_scan/core/services/database_service.dart';
import 'package:smart_scan/core/services/feedback_service.dart';

class ScanDetailScreen extends StatefulWidget {
  final ScanModel scan;

  const ScanDetailScreen({super.key, required this.scan});

  @override
  State<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _textController;
  final ScanRepository _scanRepository = ScanRepository();
  bool _isEditing = false;
  bool _isSaving = false;
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.scan.title);
    _textController = TextEditingController(text: widget.scan.rawText ?? '');
    _loadCategoryName();
  }

  Future<void> _loadCategoryName() async {
    if (widget.scan.categoryId == null) return;
    try {
      final map = await DatabaseService().getCategory(widget.scan.categoryId!);
      if (map != null && mounted) {
        setState(() => _categoryName = map['name'] as String?);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveScan() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le titre ne peut pas être vide'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _scanRepository.updateScan(
        scanId: widget.scan.id,
        title: _titleController.text,
        rawText: _textController.text,
      );

      if (mounted) {
        // Update parent ScansBloc if available
        context.read<ScansBloc>().add(const RefreshScansEvent());

        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteScan() async {
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

    if (confirmed == true && mounted) {
      try {
        await _scanRepository.deleteScan(widget.scan.id);
        if (mounted) {
          context
              .read<ScansBloc>()
              .add(DeleteScanEvent(scanId: widget.scan.id));
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scan supprimé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildImagePreview() {
    if (widget.scan.imagePath == null || widget.scan.imagePath!.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucune image disponible',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    try {
      return GestureDetector(
        onTap: () {
          _showImageFullScreen(context, widget.scan.imagePath!);
        },
        child: Image.file(
          File(widget.scan.imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    const Text('Image non trouvée'),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: Center(child: Text('Erreur: $e')),
      );
    }
  }

  void _showImageFullScreen(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageFullScreenViewer(imagePath: imagePath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? const Text('Modifier le scan')
            : const Text('Détails du scan'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await FeedbackService().onTap();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Export',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ExportOptionsScreen(scan: widget.scan),
                  ),
                );
              },
            ),
          if (!_isEditing)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                  onTap: () {
                    setState(() => _isEditing = true);
                  },
                ),
                PopupMenuItem(
                  onTap: _deleteScan,
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview
              Container(
                width: double.infinity,
                height: 300,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImagePreview(),
                ),
              ),

              // Title Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing)
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titre du scan',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                      )
                    else
                      Text(
                        widget.scan.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(widget.scan.createdAt),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Metadata Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetadataRow('Langue détectée',
                        widget.scan.detectedLanguage ?? 'Non détectée'),
                    _buildMetadataRow('Langue cible',
                        widget.scan.targetLanguage ?? 'Non traduit'),
                    _buildMetadataRow(
                        'Category',
                        _categoryName ??
                            widget.scan.categoryId ??
                            'Not categorized'),
                    if (widget.scan.imagePath != null)
                      _buildMetadataRow(
                          'Chemin de l\'image', widget.scan.imagePath!),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Text Content Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Texte original',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isEditing)
                      TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Texte du scan',
                        ),
                        minLines: 5,
                        maxLines: null,
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border:
                              Border.all(color: Colors.grey[300]!, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.scan.rawText ?? 'Aucun texte',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Translated Text Section (if available)
              if (widget.scan.translatedText != null &&
                  widget.scan.translatedText!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Texte traduit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          border:
                              Border.all(color: Colors.blue[200]!, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.scan.translatedText!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Translation Action Button
              if (!_isEditing &&
                  widget.scan.rawText != null &&
                  widget.scan.rawText!.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FeedbackService().onTap();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TranslationScreen(
                              initialText: widget.scan.rawText,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.translate),
                      label: const Text('Traduire'),
                    ),
                  ),
                ),

              // Action Buttons
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  _titleController.text = widget.scan.title;
                                  _textController.text =
                                      widget.scan.rawText ?? '';
                                  setState(() => _isEditing = false);
                                },
                          icon: const Icon(Icons.close),
                          label: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveScan,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label:
                              Text(_isSaving ? 'Sauvegarde...' : 'Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Full-screen image viewer with zoom capability
class ImageFullScreenViewer extends StatefulWidget {
  final String imagePath;

  const ImageFullScreenViewer({super.key, required this.imagePath});

  @override
  State<ImageFullScreenViewer> createState() => _ImageFullScreenViewerState();
}

class _ImageFullScreenViewerState extends State<ImageFullScreenViewer> {
  late TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else if (_doubleTapDetails != null) {
      _transformationController.value = Matrix4.identity()
        ..translate(-_doubleTapDetails!.localPosition.dx * 2,
            -_doubleTapDetails!.localPosition.dy * 2)
        ..scale(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Image',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: GestureDetector(
          onDoubleTapDown: (details) => _doubleTapDetails = details,
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(80),
            minScale: 0.5,
            maxScale: 4,
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Image non trouvée',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
