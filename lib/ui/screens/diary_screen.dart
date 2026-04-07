import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../services/moments_repository.dart';
import '../../services/user_repository.dart';
import '../../state/app_settings.dart';
import '../../state/main_shell_controller.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _captionCtrl = TextEditingController();
  final List<Uint8List> _photos = [];
  bool _busy = false;
  bool _showOfflineGuide = false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final list = await picker.pickMultiImage(maxWidth: 4096, imageQuality: 95);
    if (list.isEmpty) return;
    final cap = MomentsRepository.kMaxPhotosPerMoment - _photos.length;
    if (cap <= 0) return;
    final take = list.length > cap ? cap : list.length;
    final pickedBytes = <Uint8List>[];
    for (var i = 0; i < take; i++) {
      final b = await list[i].readAsBytes();
      if (!mounted) return;
      pickedBytes.add(Uint8List.fromList(b));
    }
    if (pickedBytes.isEmpty || !mounted) return;
    setState(() => _photos.addAll(pickedBytes));
  }

  void _removeAt(int i) {
    setState(() => _photos.removeAt(i));
  }

  Future<void> _publish(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final caption = _captionCtrl.text.trim();
    if (_photos.isEmpty && caption.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.diaryNeedCaptionOrPhoto)));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final userRepo = context.read<UserRepository>();
    final momentsRepo = context.read<MomentsRepository>();
    final settings = context.read<AppSettings>();
    final nav = context.read<MainShellController>();

    final coupleId = await userRepo.getCoupleId(user.uid);
    if (coupleId == null || coupleId.isEmpty) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.feedConnectFirst)));
      return;
    }

    setState(() {
      _busy = true;
      _showOfflineGuide = false;
    });
    try {
      await momentsRepo.createMoment(
        coupleId: coupleId,
        caption: caption,
        imageBytesList: _photos.isEmpty ? null : _photos,
        isPremium: settings.isPremium,
      );
      if (!mounted) return;
      _captionCtrl.clear();
      setState(() => _photos.clear());
      messenger.showSnackBar(SnackBar(content: Text(l10n.diaryPostedSuccess)));
      nav.goHome();
    } on MomentsQuotaException {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.diaryQuotaExceeded)));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final isOffline =
          e.code == 'network-request-failed' || e.code == 'unavailable';
      if (isOffline) {
        setState(() => _showOfflineGuide = true);
        return;
      }
      final msg = e.code == 'permission-denied'
          ? l10n.diaryFirestorePermissionDenied
          : (e.message ?? e.code);
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _showOfflineGuide = true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.diaryTitle)),
      body: _showOfflineGuide
          ? _UploadOfflineView(onRetry: _busy ? null : () => _publish(context))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  l10n.diaryIntroBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                if (_photos.isEmpty)
                  Container(
                    height: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: scheme.outline,
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _photos[i],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Material(
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  color: Colors.white,
                                  onPressed: _busy ? null : () => _removeAt(i),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickPhotos,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l10n.diaryPickPhotos),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _captionCtrl,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: InputDecoration(hintText: l10n.diaryCaptionHint),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _publish(context),
                  icon: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(l10n.diaryPublish),
                ),
              ],
            ),
    );
  }
}

class _UploadOfflineView extends StatelessWidget {
  const _UploadOfflineView({required this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 42,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              '연결이 끊겼습니다',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '인터넷 연결 후 다시 시도해 주세요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
