import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../services/user_repository.dart';

/// 설정 상단에서 진입 — 사진·이름·초대 코드 (Stateful: TextEditingController 생명주기 안전)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  bool _busy = false;
  bool _nameSeeded = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(String uid) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 92,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<UserRepository>().uploadProfilePhoto(
        uid,
        Uint8List.fromList(bytes),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveName(String uid) async {
    final t = _nameCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() => _busy = true);
    try {
      await context.read<UserRepository>().updateDisplayName(uid, t);
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: const Center(child: Text('—')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: StreamBuilder(
        stream: context.read<UserRepository>().watchUser(user.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final data = snap.data?.data();
          final name = data?['displayName'] as String? ?? '';
          final photoUrl = data?['photoUrl'] as String?;
          final code = data?['inviteCode'] as String?;

          if (!_nameSeeded && name.isNotEmpty) {
            _nameSeeded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_nameCtrl.text.isEmpty) _nameCtrl.text = name;
            });
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          backgroundImage:
                              photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 56,
                                  color: Theme.of(context).colorScheme.outline,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: IconButton.filledTonal(
                          onPressed: _busy
                              ? null
                              : () => _pickAndUploadPhoto(user.uid),
                          icon: const Icon(Icons.camera_alt_outlined, size: 20),
                          tooltip: l10n.profilePhotoPick,
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.profileNameHint,
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveName(user.uid),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : () => _saveName(user.uid),
                child: Text(l10n.profileSave),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.profileInviteCode,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (code != null && code.isNotEmpty)
                Card(
                  child: ListTile(
                    title: SelectableText(
                      code,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(letterSpacing: 3),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      tooltip: l10n.profileCopyCode,
                      onPressed: () {
                        unawaited(Clipboard.setData(ClipboardData(text: code)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.profileCopyCode)),
                        );
                      },
                    ),
                  ),
                )
              else
                const Text(
                  '초대 코드는 SOLO 화면에서 사귄 날짜를 선택한 뒤 생성할 수 있습니다.',
                  style: TextStyle(color: Colors.black87),
                ),
            ],
          );
        },
      ),
    );
  }
}
