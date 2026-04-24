import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/features/scan/presentation/pages/scan_detail_screen.dart';
import 'package:smart_scan/core/services/feedback_service.dart';
import '../bloc/history_bloc.dart';

class SearchScansScreen extends StatefulWidget {
  const SearchScansScreen({super.key});

  @override
  State<SearchScansScreen> createState() => _SearchScansScreenState();
}

class _SearchScansScreenState extends State<SearchScansScreen> {
  late TextEditingController _searchController;
  final FocusNode _searchFocus = FocusNode();
  String _selectedFilter = 'all';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _performSearch(BuildContext context, String query) {
    if (query.isEmpty) {
      context.read<HistoryBloc>().add(const LoadScansEvent());
    } else {
      context.read<HistoryBloc>().add(SearchScansEvent(query: query.trim()));
    }
  }

  void _onSearchChanged(String value) async {
    _debounce?.cancel();
    setState(() {});
    await FeedbackService().onTap();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(context, value);
    });
  }

  void _clearSearch(BuildContext context) {
    _searchController.clear();
    _debounce?.cancel();
    context.read<HistoryBloc>().add(const LoadScansEvent());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher des scans'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await FeedbackService().onTap();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      decoration: InputDecoration(
                        hintText: 'Rechercher dans vos scans...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _clearSearch(context),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) => _onSearchChanged(value),
                      onSubmitted: (value) => _performSearch(context, value),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'Tout'),
                          const SizedBox(width: 8),
                          _buildFilterChip('title', 'Titre'),
                          const SizedBox(width: 8),
                          _buildFilterChip('content', 'Contenu'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildSearchResults(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(HistoryState state) {
    if (state is HistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is HistoryError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.message),
          ],
        ),
      );
    }

    if (state is HistoryEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Commencez à taper pour rechercher'
                  : 'Aucun résultat trouvé',
            ),
          ],
        ),
      );
    }

    if (state is HistoryLoaded) {
      if (state.scans.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('Aucun résultat trouvé'),
            ],
          ),
        );
      }
      return ListView.builder(
        itemCount: state.scans.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemBuilder: (context, index) {
          final scan = state.scans[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: scan.imagePath != null
                  ? Image.file(
                      File(scan.imagePath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image),
                    )
                  : const Icon(Icons.article),
              title: Text(scan.title),
              subtitle: Text(
                scan.rawText ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScanDetailScreen(scan: scan),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Commencez à taper pour rechercher'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = filter),
    );
  }
}
