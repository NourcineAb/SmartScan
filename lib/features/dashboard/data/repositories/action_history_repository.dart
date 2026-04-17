import '../../../../shared/models/action_history_model.dart';

class ActionHistoryRepository {
  static final ActionHistoryRepository _instance =
      ActionHistoryRepository._internal();

  final List<ActionHistory> _history = [];
  static const int maxHistoryItems = 100; // Limiter à 100 éléments

  factory ActionHistoryRepository() {
    return _instance;
  }

  ActionHistoryRepository._internal();

  /// Ajouter une action à l'historique
  void recordAction({
    required String actionName,
    required String actionLabel,
    required String description,
    required String icon,
  }) {
    final action = ActionHistory(
      actionName: actionName,
      actionLabel: actionLabel,
      description: description,
      timestamp: DateTime.now(),
      icon: icon,
    );

    _history.insert(0, action); // Ajouter au début (le plus récent)

    // Limiter à maxHistoryItems
    if (_history.length > maxHistoryItems) {
      _history.removeRange(maxHistoryItems, _history.length);
    }
  }

  /// Récupérer tout l'historique
  List<ActionHistory> getHistory() {
    return List.unmodifiable(_history);
  }

  /// Récupérer un nombre limité d'actions récentes
  List<ActionHistory> getRecentActions(int limit) {
    return _history.take(limit).toList();
  }

  /// Rechercher des actions par nom
  List<ActionHistory> searchActions(String query) {
    return _history
        .where(
          (action) =>
              action.actionName.toLowerCase().contains(query.toLowerCase()) ||
              action.actionLabel.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  /// Compter les actions
  int getActionCount() {
    return _history.length;
  }

  /// Compter les actions pour un type spécifique
  int getActionCountByName(String actionName) {
    return _history.where((action) => action.actionName == actionName).length;
  }

  /// Obtenir les statistiques des actions
  Map<String, int> getActionStats() {
    final stats = <String, int>{};
    for (final action in _history) {
      stats[action.actionName] = (stats[action.actionName] ?? 0) + 1;
    }
    return stats;
  }

  /// Vider l'historique
  void clearHistory() {
    _history.clear();
  }

  /// Supprimer une action spécifique
  bool removeAction(String id) {
    final initialLength = _history.length;
    _history.removeWhere((action) => action.id == id);
    return _history.length < initialLength;
  }
}
