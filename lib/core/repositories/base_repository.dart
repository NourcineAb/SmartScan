/// Base repository interface
/// All repositories should extend this to ensure consistent contract
abstract class BaseRepository {
  /// Initialize the repository
  /// Called once at app startup
  Future<void> initialize();

  /// Clean up resources
  /// Called when repository is no longer needed
  Future<void> dispose();
}
