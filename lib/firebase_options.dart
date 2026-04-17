// Stub Firebase options for web compatibility
class FirebaseOptions {
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String storageBucket;

  const FirebaseOptions({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    required this.storageBucket,
  });
}

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'web-stub-key',
    appId: 'web-stub-app-id',
    messagingSenderId: 'web-stub-sender-id',
    projectId: 'smartscan-firebase',
    storageBucket: 'smartscan-firebase.appspot.com',
  );
}
