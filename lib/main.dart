import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    firebaseError = e.toString();
  }

  runApp(StarterApp(firebaseError: firebaseError));
}

class StarterApp extends StatelessWidget {
  const StarterApp({super.key, this.firebaseError});

  final String? firebaseError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StarterHome(firebaseError: firebaseError),
    );
  }
}

class StarterHome extends StatelessWidget {
  const StarterHome({super.key, this.firebaseError});

  final String? firebaseError;

  @override
  Widget build(BuildContext context) {
    final options = DefaultFirebaseOptions.currentPlatform;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OurMoment Starter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '앱 내부 코드를 초기화했습니다.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('이제 이 프로젝트를 기준으로 새로 개발을 시작하면 됩니다.'),
            const SizedBox(height: 24),
            Text('Firebase Project: ${options.projectId}'),
            Text('Storage Bucket: ${options.storageBucket}'),
            const SizedBox(height: 16),
            Text(
              firebaseError == null ? 'Firebase 초기화: 성공' : 'Firebase 초기화: 실패',
              style: TextStyle(
                color: firebaseError == null ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (firebaseError != null) ...[
              const SizedBox(height: 8),
              Text(
                firebaseError!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
