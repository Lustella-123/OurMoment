import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
    return OurMomentApp(firebaseError: firebaseError);
  }
}

class OurMomentApp extends StatefulWidget {
  const OurMomentApp({super.key, this.firebaseError});

  final String? firebaseError;

  @override
  State<OurMomentApp> createState() => _OurMomentAppState();
}

class _OurMomentAppState extends State<OurMomentApp> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
      ),
      home: !_splashDone
          ? const _SplashScreen()
          : widget.firebaseError != null
          ? _BootstrapErrorScreen(error: widget.firebaseError!)
          : const _AuthFlowGate(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: const Icon(Icons.image_outlined, size: 64),
            ),
            const SizedBox(height: 14),
            const Text(
              'SPLASH IMAGE PLACEHOLDER',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text('추후 로고/스플래시 이미지로 교체하세요'),
          ],
        ),
      ),
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 36),
              const SizedBox(height: 10),
              const Text(
                'Firebase 초기화 실패',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthFlowGate extends StatelessWidget {
  const _AuthFlowGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold(text: '로그인 상태 확인 중...');
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const _LoginScreen();
        }
        return _SignedInGate(user: user);
      },
    );
  }
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen();

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  bool _loading = false;

  Future<void> _runLogin(Future<UserCredential> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final credential = await action();
      final user = credential.user;
      if (user != null) {
        await _AppDataService.ensureUserDoc(user);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithKakao() async {
    await _runLogin(_AuthService.signInWithKakaoOidc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '바로 시작하기',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '설명 없이 바로 로그인하고 시작합니다.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
                    FilledButton.icon(
                      onPressed: _loading
                          ? null
                          : () => _runLogin(_AuthService.signInWithApple),
                      icon: const Icon(Icons.apple),
                      label: const Text('Sign in with Apple'),
                    ),
                  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
                    const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE500),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _loading ? null : _signInWithKakao,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('카카오 로그인'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                    ),
                    onPressed: _loading
                        ? null
                        : () => _runLogin(_AuthService.signInWithGoogle),
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('구글 로그인'),
                  ),
                  if (_loading) ...[
                    const SizedBox(height: 18),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignedInGate extends StatelessWidget {
  const _SignedInGate({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _AppDataService.ensureUserDoc(user),
      builder: (context, initSnapshot) {
        if (initSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold(text: '계정 준비 중...');
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(_AppDataService.usersCollection)
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const _LoadingScaffold(text: '연결 상태 확인 중...');
            }

            final data = userSnapshot.data!.data() ?? <String, dynamic>{};
            final coupleId = data['couple_id'] as String?;
            if (coupleId == null || coupleId.isEmpty) {
              return _MatchingScreen(user: user, myUserData: data);
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(_AppDataService.couplesCollection)
                  .doc(coupleId)
                  .snapshots(),
              builder: (context, coupleSnapshot) {
                if (!coupleSnapshot.hasData) {
                  return const _LoadingScaffold(text: '커플 데이터 확인 중...');
                }

                final coupleDoc = coupleSnapshot.data!;
                final coupleData = coupleDoc.data();
                if (coupleData == null) {
                  return _InvalidCoupleScreen(coupleId: coupleId);
                }

                if (!_AppDataService.isAnniversarySet(coupleData)) {
                  return _AnniversaryScreen(coupleId: coupleId, uid: user.uid);
                }
                return _MainHomeScreen(coupleId: coupleId, uid: user.uid);
              },
            );
          },
        );
      },
    );
  }
}

class _MatchingScreen extends StatefulWidget {
  const _MatchingScreen({required this.user, required this.myUserData});

  final User user;
  final Map<String, dynamic> myUserData;

  @override
  State<_MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<_MatchingScreen> {
  final TextEditingController _partnerCodeController = TextEditingController();
  bool _loading = false;
  String? _myCode;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadMyCode());
  }

  @override
  void dispose() {
    _partnerCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadMyCode() async {
    try {
      final existingCode = widget.myUserData['invite_code'] as String?;
      final code = await _AppDataService.getOrCreateInviteCode(
        uid: widget.user.uid,
        existingCode: existingCode,
      );
      if (!mounted) return;
      setState(() {
        _myCode = code;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '초대 코드 생성 실패: $e');
    }
  }

  Future<void> _shareInvite() async {
    if (_myCode == null) return;
    final inviteLink = '${_AppDataService.inviteBaseUrl}?code=$_myCode';
    final message = '''
우리 커플 앱에 연결해줘 💕
초대 코드: $_myCode
링크: $inviteLink
''';
    await Share.share(message);
  }

  Future<void> _connectCouple() async {
    final code = _partnerCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = '상대방 코드를 입력해 주세요.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _AppDataService.connectByInviteCode(
        myUid: widget.user.uid,
        partnerCode: code,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연결 완료! 기념일을 설정해 주세요.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('연결 대기'),
        actions: [
          TextButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            child: const Text('로그아웃'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '아직 커플 연결 전이에요.',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('내 코드를 공유하거나 상대방 코드를 입력해서 연결하세요.'),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('내 코드 공유', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(
                    _myCode ?? '코드 생성 중...',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _myCode == null ? null : _shareInvite,
                    icon: const Icon(Icons.chat),
                    label: const Text('카카오톡으로 초대 링크 보내기'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('상대 코드 입력', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _partnerCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '예: A1B2C3',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loading ? null : _connectCouple,
                    child: const Text('연결 완료하기'),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}

class _AnniversaryScreen extends StatefulWidget {
  const _AnniversaryScreen({required this.coupleId, required this.uid});

  final String coupleId;
  final String uid;

  @override
  State<_AnniversaryScreen> createState() => _AnniversaryScreenState();
}

class _AnniversaryScreenState extends State<_AnniversaryScreen> {
  bool _useDatingStart = true;
  bool _useWedding = false;
  DateTime? _datingStartDate;
  DateTime? _weddingDate;
  bool _saving = false;
  String? _error;

  bool get _canSubmit {
    final hasDating = _useDatingStart && _datingStartDate != null;
    final hasWedding = _useWedding && _weddingDate != null;
    return hasDating || hasWedding;
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(1970, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (selected != null) onPicked(selected);
  }

  Future<void> _save() async {
    if (!_canSubmit) {
      setState(() => _error = '연애 시작일 또는 결혼 기념일 중 최소 1개를 입력해 주세요.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _AppDataService.saveAnniversary(
        coupleId: widget.coupleId,
        uid: widget.uid,
        datingStart: _useDatingStart ? _datingStartDate : null,
        weddingAnniversary: _useWedding ? _weddingDate : null,
      );
    } catch (e) {
      setState(() => _error = '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '날짜 선택';
    return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기념일 설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '커플 연결이 완료됐어요!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '메인 홈 진입 전, 기념일을 설정해 주세요.\n둘 중 하나 이상은 필수이며, 둘 다 저장할 수도 있어요.',
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            value: _useDatingStart,
            onChanged: (v) => setState(() => _useDatingStart = v),
            title: const Text('연애 시작일'),
          ),
          ListTile(
            enabled: _useDatingStart,
            title: Text(_formatDate(_datingStartDate)),
            trailing: const Icon(Icons.calendar_month),
            onTap: _useDatingStart
                ? () => _pickDate(
                    current: _datingStartDate,
                    onPicked: (d) => setState(() => _datingStartDate = d),
                  )
                : null,
          ),
          const Divider(),
          SwitchListTile(
            value: _useWedding,
            onChanged: (v) => setState(() => _useWedding = v),
            title: const Text('결혼 기념일'),
          ),
          ListTile(
            enabled: _useWedding,
            title: Text(_formatDate(_weddingDate)),
            trailing: const Icon(Icons.calendar_month),
            onTap: _useWedding
                ? () => _pickDate(
                    current: _weddingDate,
                    onPicked: (d) => setState(() => _weddingDate = d),
                  )
                : null,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('기념일 저장하고 홈으로'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}

class _MainHomeScreen extends StatefulWidget {
  const _MainHomeScreen({required this.coupleId, required this.uid});

  final String coupleId;
  final String uid;

  @override
  State<_MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<_MainHomeScreen> {
  int _index = 0;
  static const _labels = ['홈', '피드', '달력', '메모', '설정'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_labels[_index])),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_labels[_index]} 화면',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('각 탭은 이후 단계에서 개별 구현 예정입니다.'),
              const SizedBox(height: 14),
              Text('couple_id: ${widget.coupleId}'),
              if (_index == 4) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('로그아웃'),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(icon: Icon(Icons.dynamic_feed_outlined), label: '피드'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: '달력'),
          NavigationDestination(icon: Icon(Icons.sticky_note_2_outlined), label: '메모'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: '설정'),
        ],
      ),
    );
  }
}

class _InvalidCoupleScreen extends StatelessWidget {
  const _InvalidCoupleScreen({required this.coupleId});

  final String coupleId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 38),
              const SizedBox(height: 10),
              Text('커플 데이터($coupleId)를 찾지 못했어요.'),
              const SizedBox(height: 8),
              const Text('관리자 확인 후 다시 로그인해 주세요.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('로그아웃'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class _AuthService {
  static Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('구글 로그인이 취소되었습니다.');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  static Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );
    return FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  static Future<UserCredential> signInWithKakaoOidc() async {
    final provider = OAuthProvider('oidc.kakao');
    provider.addScope('profile_nickname');
    provider.setCustomParameters(const {'prompt': 'login'});
    return FirebaseAuth.instance.signInWithProvider(provider);
  }

  static String _generateNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List<String>.generate(
      length,
      (i) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

class _AppDataService {
  static const usersCollection = 'users';
  static const couplesCollection = 'couples';
  static const inviteCodesCollection = 'invite_codes';
  static const inviteBaseUrl = 'https://ourmoment.app/invite';

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> ensureUserDoc(User user) async {
    final ref = _db.collection(usersCollection).doc(user.uid);
    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'display_name': user.displayName,
      'photo_url': user.photoURL,
      'last_login_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<String> getOrCreateInviteCode({
    required String uid,
    String? existingCode,
  }) async {
    if (existingCode != null && existingCode.isNotEmpty) {
      return existingCode.toUpperCase();
    }

    final userRef = _db.collection(usersCollection).doc(uid);

    for (var i = 0; i < 20; i++) {
      final code = _generateCode();
      final codeRef = _db.collection(inviteCodesCollection).doc(code);
      try {
        await _db.runTransaction((tx) async {
          final codeSnap = await tx.get(codeRef);
          if (codeSnap.exists) {
            throw StateError('collision');
          }

          tx.set(codeRef, {
            'owner_uid': uid,
            'created_at': FieldValue.serverTimestamp(),
          });
          tx.set(userRef, {
            'invite_code': code,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        });
        return code;
      } on StateError {
        continue;
      }
    }
    throw Exception('초대 코드 생성에 실패했습니다. 잠시 후 다시 시도해 주세요.');
  }

  static Future<void> connectByInviteCode({
    required String myUid,
    required String partnerCode,
  }) async {
    final normalizedCode = partnerCode.trim().toUpperCase();
    final partnerCodeRef = _db.collection(inviteCodesCollection).doc(normalizedCode);
    final myRef = _db.collection(usersCollection).doc(myUid);
    final newCoupleRef = _db.collection(couplesCollection).doc();

    await _db.runTransaction((tx) async {
      final partnerCodeSnap = await tx.get(partnerCodeRef);
      if (!partnerCodeSnap.exists) {
        throw Exception('유효하지 않은 코드입니다.');
      }

      final partnerUid = partnerCodeSnap.data()?['owner_uid'] as String?;
      if (partnerUid == null) {
        throw Exception('코드 데이터가 올바르지 않습니다.');
      }
      if (partnerUid == myUid) {
        throw Exception('내 코드는 입력할 수 없습니다.');
      }

      final partnerRef = _db.collection(usersCollection).doc(partnerUid);
      final mySnap = await tx.get(myRef);
      final partnerSnap = await tx.get(partnerRef);

      final myCoupleId = mySnap.data()?['couple_id'] as String?;
      final partnerCoupleId = partnerSnap.data()?['couple_id'] as String?;
      if ((myCoupleId ?? '').isNotEmpty) {
        throw Exception('이미 커플 연결이 완료된 계정입니다.');
      }
      if ((partnerCoupleId ?? '').isNotEmpty) {
        throw Exception('상대방은 이미 다른 커플과 연결되어 있습니다.');
      }

      tx.set(newCoupleRef, {
        'members': [myUid, partnerUid],
        'anniversary_set': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      tx.set(myRef, {
        'couple_id': newCoupleRef.id,
        'partner_uid': partnerUid,
        'matched_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      tx.set(partnerRef, {
        'couple_id': newCoupleRef.id,
        'partner_uid': myUid,
        'matched_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  static Future<void> saveAnniversary({
    required String coupleId,
    required String uid,
    required DateTime? datingStart,
    required DateTime? weddingAnniversary,
  }) async {
    final ref = _db.collection(couplesCollection).doc(coupleId);
    await ref.set({
      'anniversary_set': true,
      'anniversary_set_by': uid,
      'anniversary_set_at': FieldValue.serverTimestamp(),
      'anniversaries': {
        'dating_start': datingStart != null ? Timestamp.fromDate(datingStart) : null,
        'wedding_anniversary': weddingAnniversary != null
            ? Timestamp.fromDate(weddingAnniversary)
            : null,
      },
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static bool isAnniversarySet(Map<String, dynamic> coupleData) {
    final setFlag = coupleData['anniversary_set'] == true;
    final anniversaries = coupleData['anniversaries'];
    if (anniversaries is! Map<String, dynamic>) {
      return setFlag;
    }

    final hasDating = anniversaries['dating_start'] != null;
    final hasWedding = anniversaries['wedding_anniversary'] != null;
    return setFlag || hasDating || hasWedding;
  }

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List<String>.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
