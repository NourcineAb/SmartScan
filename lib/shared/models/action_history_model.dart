import 'package:uuid/uuid.dart';

class ActionHistory {
  final String id;
  final String actionName;
  final String actionLabel;
  final String description;
  final DateTime timestamp;
  final String icon; // Pour l'affichage de l'icône

  ActionHistory({
    String? id,
    required this.actionName,
    required this.actionLabel,
    required this.description,
    required this.timestamp,
    required this.icon,
  }) : id = id ?? const Uuid().v4();

  /// Retourne le temps écoulé depuis l'action
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return 'Le ${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Convertit le modèle en Map pour la sérialisation
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actionName': actionName,
      'actionLabel': actionLabel,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'icon': icon,
    };
  }

  /// Crée un ActionHistory à partir d'un Map
  factory ActionHistory.fromMap(Map<String, dynamic> map) {
    return ActionHistory(
      id: map['id'] ?? '',
      actionName: map['actionName'] ?? '',
      actionLabel: map['actionLabel'] ?? '',
      description: map['description'] ?? '',
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      icon: map['icon'] ?? 'history',
    );
  }

  /// Crée une copie avec des champs optionnels modifiés
  ActionHistory copyWith({
    String? id,
    String? actionName,
    String? actionLabel,
    String? description,
    DateTime? timestamp,
    String? icon,
  }) {
    return ActionHistory(
      id: id ?? this.id,
      actionName: actionName ?? this.actionName,
      actionLabel: actionLabel ?? this.actionLabel,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      icon: icon ?? this.icon,
    );
  }
}
