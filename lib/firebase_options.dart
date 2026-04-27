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
    apiKey: 'AIzaSyBOSDxnRFJsWeSbWI9agTRj4wzve0gYgvc',
    appId: '1:780230137565:web:85b913fd287d263528ed34',
    messagingSenderId: '780230137565',
    projectId: 'smartscan-9dcac',
    storageBucket: 'smartscan-9dcac.firebasestorage.app',
  );
}
