import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/shared/models/scan_model.dart';
import 'package:smart_scan/features/scan/presentation/pages/scan_detail_screen.dart';
import 'package:smart_scan/core/utils/page_transition_utils.dart';
import 'package:animations/animations.dart';
import 'package:smart_scan/core/services/feedback_service.dart';
import '../bloc/scans_bloc.dart';

class SearchScansScreen extends StatefulWidget {
  const SearchScansScreen({super.key});

  @override
  State<SearchScansScreen> createState() => _SearchScansScreenState();
}

class _SearchScansScreenState extends State<SearchScansScreen> {
  late TextEditingController _searchController;
  final FocusNode _searchFocus = FocusNode();
  String _selectedFilter = 'all'; // all, recent, title, content

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Request focus on search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _performSearch(BuildContext context, String query) {
    if (query.trim().isEmpty) {
      return;
    }
    context.read<ScansBloc>().add(SearchScansEvent(query: query.trim()));
  }

  void _clearSearch(BuildContext context) {
    _searchController.clear();
    context.read<ScansBloc>().add(const LoadScansEvent());
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
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          // Search bar with filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search input
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                  onSubmitted: (value) => _performSearch(context, value),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Tous',
                        value: 'all',
                        onTap: () => setState(() => _selectedFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Titres',
                        value: 'title',
                        onTap: () => setState(() => _selectedFilter = 'title'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Contenus',
                        value: 'content',
                        onTap: () =>
                            setState(() => _selectedFilter = 'content'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Récents',
                        value: 'recent',
                        onTap: () => setState(() => _selectedFilter = 'recent'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Search button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _performSearch(context, _searchController.text),
                    icon: const Icon(Icons.search),
                    label: const Text('Rechercher'),
                  ),
                ),
              ],
            ),
          ),
          // Search results
          Expanded(
            child: BlocBuilder<ScansBloc, ScansState>(
              builder: (context, state) {
                if (state is ScansInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Entrez une recherche',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Recherchez dans les titres et contenus de vos scans',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ScansLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is ScansError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        const Text('Erreur lors de la recherche'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _performSearch(
                            context,
                            _searchController.text,
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
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
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text('Aucun résultat trouvé'),
                        const SizedBox(height: 8),
                        Text(
                          'Essayez une autre recherche',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ScansLoaded) {
                  return ListView.builder(
                    itemCount: state.scans.length,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    itemBuilder: (context, index) {
                      final scan = state.scans[index];
                      return _buildSearchResultCard(context, scan);
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.transparent,
      selectedColor: Colors.indigo[100],
      side: BorderSide(
        color: isSelected ? Colors.indigo : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildSearchResultCard(BuildContext context, ScanModel scan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.indigo[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.description, color: Colors.indigo[700]),
        ),
        title: Text(
          scan.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatDate(scan.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            if (scan.rawText != null)
              Text(
                scan.rawText!.substring(
                  0,
                  (scan.rawText!.length > 60 ? 60 : scan.rawText!.length),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          Navigator.of(context).push(
            PageTransitionUtils.sharedAxisTransition<void>(
              context: context,
              builder: (context) => ScanDetailScreen(scan: scan),
              routeName: '/scan-detail-search',
              transitionType: SharedAxisTransitionType.vertical,
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 1) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
