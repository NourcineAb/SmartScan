import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/features/scan/presentation/bloc/export_bloc.dart';
import 'package:smart_scan/shared/models/scan_model.dart';
import 'package:smart_scan/core/services/feedback_service.dart';

class ExportOptionsScreen extends StatelessWidget {
  final ScanModel scan;

  const ExportOptionsScreen({
    super.key,
    required this.scan,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExportBloc(),
      child: _ExportOptionsView(scan: scan),
    );
  }
}

class _ExportOptionsView extends StatefulWidget {
  final ScanModel scan;

  const _ExportOptionsView({required this.scan});

  @override
  State<_ExportOptionsView> createState() => _ExportOptionsViewState();
}

class _ExportOptionsViewState extends State<_ExportOptionsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Scan'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await FeedbackService().onTap();
            Navigator.pop(context);
          },
        ),
      ),
      body: BlocListener<ExportBloc, ExportState>(
        listener: (context, state) {
          if (state is ExportCompleted) {
            FeedbackService().onSave();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is ExportError) {
            FeedbackService().onError();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: BlocBuilder<ExportBloc, ExportState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export ${widget.scan.title}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose a format to export your scan',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Export options
                  Text(
                    'Export Format',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // PDF Option
                  _ExportOptionCard(
                    title: 'PDF Document',
                    description: 'Export as a formatted PDF document',
                    icon: Icons.picture_as_pdf,
                    color: Colors.red,
                    isLoading:
                        state is ExportInProgress && state.exportType == 'pdf',
                    onPressed: state is! ExportInProgress
                        ? () {
                            context.read<ExportBloc>().add(
                                  ExportToPDFEvent(scan: widget.scan),
                                );
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // TXT Option
                  _ExportOptionCard(
                    title: 'Text File',
                    description: 'Export as plain text (.txt)',
                    icon: Icons.description,
                    color: Colors.orange,
                    isLoading:
                        state is ExportInProgress && state.exportType == 'txt',
                    onPressed: state is! ExportInProgress
                        ? () {
                            context.read<ExportBloc>().add(
                                  ExportToTXTEvent(scan: widget.scan),
                                );
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Word Option
                  _ExportOptionCard(
                    title: 'Word Document',
                    description: 'Export as Word document (.docx)',
                    icon: Icons.article,
                    color: Colors.blue,
                    isLoading:
                        state is ExportInProgress && state.exportType == 'word',
                    onPressed: state is! ExportInProgress
                        ? () {
                            context.read<ExportBloc>().add(
                                  ExportToWordEvent(scan: widget.scan),
                                );
                          }
                        : null,
                  ),

                  const SizedBox(height: 32),

                  // Export info section
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Export Information',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Files are saved to your device storage\n'
                            '• Original and translated text will be included\n'
                            '• You can share these files with others\n'
                            '• All metadata (date, language) will be preserved',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                      height: 1.6,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status section
                  if (state is! ExportInitial) ...[
                    _buildStatusSection(context, state),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, ExportState state) {
    if (state is ExportInProgress) {
      return Card(
        color: Colors.amber[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Exporting ${state.exportType.toUpperCase()}...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    } else if (state is ExportCompleted) {
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<ExportBloc>().add(
                              ShareExportedFileEvent(
                                filePath: state.filePath,
                                subject:
                                    'SmartScan Export: ${widget.scan.title}',
                              ),
                            );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (state is ExportError) {
      return Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ExportOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ExportOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        )
                      : Icon(icon, color: color, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
