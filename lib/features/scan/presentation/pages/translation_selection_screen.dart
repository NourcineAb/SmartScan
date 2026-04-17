import 'package:flutter/material.dart';
import 'package:smart_scan/shared/models/scan_model.dart';
import 'export_options_screen.dart';

class TranslationSelectionScreen extends StatefulWidget {
  final String extractedText;
  final String imagePath;

  const TranslationSelectionScreen({
    super.key,
    required this.extractedText,
    required this.imagePath,
  });

  @override
  State<TranslationSelectionScreen> createState() =>
      _TranslationSelectionScreenState();
}

class _TranslationSelectionScreenState
    extends State<TranslationSelectionScreen> {
  String? _selectedLanguage;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'Anglais', 'flag': '🇬🇧'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'ar', 'name': 'Arabe', 'flag': '🇸🇦'},
    {'code': 'es', 'name': 'Espagnol', 'flag': '🇪🇸'},
    {'code': 'de', 'name': 'Allemand', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italien', 'flag': '🇮🇹'},
    {'code': 'pt', 'name': 'Portugais', 'flag': '🇵🇹'},
    {'code': 'ja', 'name': 'Japonais', 'flag': '🇯🇵'},
    {'code': 'zh', 'name': 'Chinois', 'flag': '🇨🇳'},
  ];

  void _continueToExport() {
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une langue de traduction'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExportOptionsScreen(
          scan: ScanModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Export - ${DateTime.now().toString().split('.')[0]}',
            imagePath: widget.imagePath,
            rawText: widget.extractedText,
            translatedText: null,
            detectedLanguage: null,
            targetLanguage: _selectedLanguage,
            categoryId: null,
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner la traduction'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Choisissez la langue cible pour la traduction:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                final isSelected = _selectedLanguage == language['code'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.indigo[50],
                    leading: Text(
                      language['flag']!,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(language['name']!),
                    subtitle: Text('Code: ${language['code']}'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.indigo)
                        : const Icon(Icons.circle_outlined),
                    onTap: () {
                      setState(() {
                        _selectedLanguage = language['code'];
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _continueToExport,
                    icon: const Icon(Icons.check),
                    label: const Text('Suivant'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
