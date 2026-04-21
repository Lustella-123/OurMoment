import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_repository.dart';
import '../../services/couple_repository.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  DateTime? _relationshipStartDate;
  String? _createdCode;
  final _codeCtrl = TextEditingController();
  bool _busyCreate = false;
  bool _busyConnect = false;
  bool _busyLogout = false;

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
        return '자신이 만든 코드는 입력할 수 없습니다.';
      case CoupleInviteError.alreadyCoupled:
        return '이미 커플 연결이 완료된 상태입니다.';
      case CoupleInviteError.partnerNotPending:
        return '상대가 대기 상태가 아니거나 코드가 만료되었습니다.';
      case CoupleInviteError.relationshipStartRequired:
        return '상대가 사귄 날짜를 설정하지 않아 연결할 수 없습니다.';
      case CoupleInviteError.notAuthenticated:
        return '로그인이 필요합니다.';
    }
  }

  Future<void> _pickRelationshipStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _relationshipStartDate ?? now,
      firstDate: DateTime(1990, 1, 1),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _relationshipStartDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _createCode() async {
    final selectedDate = _relationshipStartDate;
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사귄 날짜를 먼저 선택해 주세요.')),
      );
      return;
    }
    setState(() => _busyCreate = true);
    try {
      final code = await context.read<CoupleRepository>().createInviteCode(
            relationshipStartDate: selectedDate,
          );
      if (!mounted) return;
      setState(() => _createdCode = code);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busyCreate = false);
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
        SnackBar(content: Text('연결 중 오류가 발생했습니다.\n$e')),
      );
    } finally {
      if (mounted) setState(() => _busyConnect = false);
    }
  }

  Future<void> _logout() async {
    if (_busyCreate || _busyConnect || _busyLogout) return;
    setState(() => _busyLogout = true);
    try {
      await context.read<AuthRepository>().signOut();
    } finally {
      if (mounted) setState(() => _busyLogout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _relationshipStartDate == null
        ? '선택되지 않음'
        : '${_relationshipStartDate!.year}-${_relationshipStartDate!.month.toString().padLeft(2, '0')}-${_relationshipStartDate!.day.toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('초대 코드 연결'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '1) 코드 생성 전 사귄 날짜를 먼저 선택하세요.',
            style: TextStyle(color: Colors.black),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busyCreate ? null : _pickRelationshipStartDate,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.black),
            child: Text('사귄 날짜 선택: $dateText'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _busyCreate ? null : _createCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: _busyCreate
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('초대 코드 생성'),
          ),
          if (_createdCode != null) ...[
            const SizedBox(height: 12),
            SelectableText(
              '생성된 코드: $_createdCode',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 40),
          const Divider(color: Colors.black12),
          const SizedBox(height: 16),
          const Text(
            '2) 상대가 보낸 초대 코드를 입력해 연결하세요.',
            style: TextStyle(color: Colors.black),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              hintText: '초대 코드 6자리',
              hintStyle: TextStyle(color: Colors.black54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black26),
              ),
            ),
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
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('코드로 연결하기'),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _busyLogout ? null : _logout,
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
