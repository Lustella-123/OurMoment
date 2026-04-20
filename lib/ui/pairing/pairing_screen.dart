import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/auth_repository.dart';
import '../../services/couple_repository.dart';
import '../../services/invite_deep_link.dart';
import '../../services/user_repository.dart';

enum PairingScreenMode { solo, pending }

class PairingScreen extends StatefulWidget {
  const PairingScreen({
    super.key,
    required this.uid,
    required this.mode,
    this.initialInviteCode,
  });

  final String uid;
  final PairingScreenMode mode;
  final String? initialInviteCode;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _codeCtrl = TextEditingController();
  bool _busyCreateInvite = false;
  bool _busyConnect = false;
  bool _busyLogout = false;
  DateTime? _selectedRelationshipStart;

  @override
  void initState() {
    super.initState();
    final i = widget.initialInviteCode;
    if (i != null && i.isNotEmpty) {
      _codeCtrl.text = i.toUpperCase();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  String _mapError(CoupleInviteError e) {
    switch (e) {
      case CoupleInviteError.invalidCode:
        return '유효하지 않은 초대 코드입니다.';
      case CoupleInviteError.cannotInviteSelf:
        return '내 초대 코드는 내가 입력할 수 없습니다.';
      case CoupleInviteError.alreadyInCouple:
        return '이미 커플 상태입니다.';
      case CoupleInviteError.inviteeAlreadyPaired:
        return '이미 커플 연결이 완료된 계정입니다.';
      case CoupleInviteError.coupleFull:
        return '이미 연결이 완료된 코드입니다.';
      case CoupleInviteError.notAuthenticated:
        return '로그인이 필요합니다.';
      case CoupleInviteError.relationshipStartRequired:
        return '사귄 날짜를 먼저 선택해 주세요.';
    }
  }

  Future<void> _pickRelationshipStart() async {
    final now = DateTime.now();
    final initial = _selectedRelationshipStart ?? now;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1970, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDate: DateTime(initial.year, initial.month, initial.day),
      helpText: '사귄 날짜 선택',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedRelationshipStart = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
    });
  }

  Future<void> _createInvite(DateTime relationshipStart) async {
    setState(() => _busyCreateInvite = true);
    try {
      await context.read<CoupleRepository>().createInviteCode(
            relationshipStart: relationshipStart,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageForCreateError(e))),
      );
    } finally {
      if (mounted) setState(() => _busyCreateInvite = false);
    }
  }

  Future<void> _accept() async {
    setState(() => _busyConnect = true);
    try {
      await context.read<CoupleRepository>().acceptInvite(_codeCtrl.text);
    } on CoupleInviteError catch (e) {
      if (!mounted) return;
      final msg = _mapError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('연결 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyConnect = false);
    }
  }

  Future<void> _share(String code) async {
    final link = inviteDeepLink(code);
    final text = 'Our Moment 초대 코드: $code\n$link';
    await Share.share(text);
  }

  Future<void> _logout() async {
    if (_busyConnect || _busyCreateInvite || _busyLogout) return;
    setState(() => _busyLogout = true);
    try {
      await context.read<AuthRepository>().signOut();
    } finally {
      if (mounted) setState(() => _busyLogout = false);
    }
  }

  bool get _anyBusy => _busyConnect || _busyCreateInvite || _busyLogout;

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  DateTime? _asDate(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return DateTime(d.year, d.month, d.day);
    }
    return null;
  }

  String _messageForCreateError(Object e) {
    if (e is CoupleInviteError) {
      return _mapError(e);
    }
    return '초대 코드 생성 중 오류가 발생했습니다: $e';
  }

  Widget _soloView(Map<String, dynamic>? data) {
    final inviteCode = data?['inviteCode'] as String?;
    final serverRelationshipStart = _asDate(data?['relationshipStart']);
    final effectiveRelationshipStart =
        _selectedRelationshipStart ?? serverRelationshipStart;

    return _PlainScaffold(
      title: 'Our Moment - SOLO',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '1) 사귄 날짜를 먼저 선택하세요.\n2) 초대 코드를 생성해 상대에게 전달하세요.\n3) 상대가 코드를 입력하면 자동으로 홈으로 이동합니다.',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          const SizedBox(height: 20),
          const Text(
            '사귄 날짜',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            effectiveRelationshipStart == null
                ? '선택되지 않음'
                : _formatDate(effectiveRelationshipStart),
            style: const TextStyle(fontSize: 18, color: Colors.black),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busyCreateInvite ? null : _pickRelationshipStart,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('사귄 날짜 선택'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_busyCreateInvite || effectiveRelationshipStart == null)
                ? null
                : () {
                    final selected = effectiveRelationshipStart;
                    if (selected == null) return;
                    _createInvite(selected);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: _busyCreateInvite
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('초대 코드 생성 후 대기 상태로 전환'),
          ),
          const SizedBox(height: 24),
          if (inviteCode != null && inviteCode.isNotEmpty) ...[
            const Text(
              '내 초대 코드',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
            ),
            const SizedBox(height: 8),
            SelectableText(
              inviteCode,
              style: const TextStyle(
                fontSize: 28,
                letterSpacing: 4,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _share(inviteCode),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.black),
              child: const Text('초대 링크 공유'),
            ),
            const SizedBox(height: 28),
          ],
          const Divider(color: Colors.black),
          const SizedBox(height: 20),
          const Text(
            '상대가 보낸 초대 코드 입력',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeCtrl,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: '예: ABC123',
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
            style: const TextStyle(color: Colors.black),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _busyConnect ? null : _accept,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: _busyConnect
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('초대 코드로 연결'),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _anyBusy ? null : _logout,
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingView(Map<String, dynamic>? data) {
    final inviteCode = data?['inviteCode'] as String?;
    final relationshipStart = _asDate(data?['relationshipStart']);

    return _PlainScaffold(
      title: 'Our Moment - PENDING',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '상대가 초대 코드를 입력하면 자동으로 홈으로 이동합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              const SizedBox(height: 20),
              if (relationshipStart != null)
                Text(
                  '사귄 날짜: ${_formatDate(relationshipStart)}',
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              if (relationshipStart != null) const SizedBox(height: 16),
              if (inviteCode != null && inviteCode.isNotEmpty) ...[
                const Text(
                  '내 초대 코드',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  inviteCode,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 4,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _share(inviteCode),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.black),
                  child: const Text('초대 링크 공유'),
                ),
                const SizedBox(height: 20),
              ],
              TextButton(
                onPressed: _anyBusy ? null : _logout,
                child: const Text(
                  '로그아웃',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: context.read<UserRepository>().watchUser(widget.uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return _PlainScaffold(
            title: 'Our Moment',
            body: Center(
              child: Text(
                '데이터를 불러오는 중 오류가 발생했습니다.\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const _PlainScaffold(
            title: 'Our Moment',
            body: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }
        final data = snap.data?.data();
        final status = ((data?['status'] as String?) ?? '').toUpperCase();
        if (status == UserRepository.statusPending ||
            widget.mode == PairingScreenMode.pending) {
          return _pendingView(data);
        }
        if (status == UserRepository.statusCoupled) {
          return const _PlainScaffold(
            title: 'Our Moment',
            body: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }
        return _soloView(data);
      },
    );
  }
}

class CoupledHomeScreen extends StatelessWidget {
  const CoupledHomeScreen({super.key, required this.uid, required this.coupleId});

  final String uid;
  final String coupleId;

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  int _daysSince(DateTime from) {
    final now = DateTime.now();
    final start = DateTime(from.year, from.month, from.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(start).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return _PlainScaffold(
      title: 'Our Moment - HOME',
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: context.read<CoupleRepository>().watchCouple(coupleId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                '홈 데이터를 불러오는 중 오류가 발생했습니다.\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black),
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }
          final data = snap.data?.data();
          final relationshipStart = data?['relationshipStart'] as Timestamp?;
          final members = List<String>.from(data?['memberIds'] as List? ?? []);
          final dday = relationshipStart == null
              ? null
              : _daysSince(relationshipStart.toDate());

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '연결 완료! 홈 화면입니다.',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'coupleId: $coupleId',
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '내 uid: $uid',
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '멤버 수: ${members.length}명',
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    relationshipStart == null
                        ? '사귄 날짜: 미설정'
                        : '사귄 날짜: ${_formatDate(relationshipStart.toDate())}',
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dday == null ? 'D+ 계산 불가' : 'D+$dday',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.read<AuthRepository>().signOut(),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlainScaffold extends StatelessWidget {
  const _PlainScaffold({required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: DefaultTextStyle(
        style: const TextStyle(color: Colors.black),
        child: body,
      ),
    );
  }
}
