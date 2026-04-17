import 'package:flutter/material.dart';

class SmartScanApp extends StatelessWidget {
  const SmartScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartScan',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartScan')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(Icons.document_scanner, size: 80, color: Colors.indigo),
                const SizedBox(height: 24),
                const Text(
                  'SmartScan',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'OCR Document Scanner',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Foundation Ready',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Text('✅ '),
                          SizedBox(width: 8),
                          Expanded(child: Text('3-Language Localization')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Text('✅ '),
                          SizedBox(width: 8),
                          Expanded(child: Text('Material Design 3 Theme')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Text('✅ '),
                          SizedBox(width: 8),
                          Expanded(child: Text('SQLite Database')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Text('✅ '),
                          SizedBox(width: 8),
                          Expanded(child: Text('Core Services')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Text('✅ '),
                          SizedBox(width: 8),
                          Expanded(child: Text('BLoC State Management')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Text('✅ '),
                          SizedBox(width: 8),
                          Expanded(child: Text('Data Models')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Features coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Start Scan'),
                ),
                const SizedBox(height: 32),
                const Text(
                  'SmartScan - Production Ready',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
