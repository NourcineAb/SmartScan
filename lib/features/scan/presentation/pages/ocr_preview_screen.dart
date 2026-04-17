import 'package:flutter/material.dart';
import 'package:smart_scan/core/services/feedback_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'text_editor_screen.dart';

class OCRPreviewScreen extends StatefulWidget {
  final String imagePath;
  final String extractedText;

  const OCRPreviewScreen({
    super.key,
    required this.imagePath,
    required this.extractedText,
  });

  @override
  State<OCRPreviewScreen> createState() => _OCRPreviewScreenState();
}

class _OCRPreviewScreenState extends State<OCRPreviewScreen> {
  late String _currentText;

  @override
  void initState() {
    super.initState();
    _currentText = widget.extractedText;
  }

  void _editText() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => TextEditorScreen(initialText: _currentText),
      ),
    )
        .then((editedText) {
      if (editedText != null) {
        setState(() {
          _currentText = editedText;
        });
      }
    });
  }

  Widget _buildImagePreview() {
    if (kIsWeb) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Image preview',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    try {
      return Image.file(File(widget.imagePath), fit: BoxFit.cover);
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: Center(child: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Preview'), elevation: 0),
      body: Column(
        children: [
          // Image preview
          Expanded(
            flex: 1,
            child: Container(
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
          ),
          // Extracted text display
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Extracted text:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentText.isEmpty
                          ? 'No text detected'
                          : _currentText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Review extracted text. Editing is optional — tap Continue to proceed as-is.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Retake'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _editText,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Text'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          FeedbackService().onSuccess();
                          Navigator.pop(context, {
                            'text': _currentText,
                            'imagePath': widget.imagePath,
                          });
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
