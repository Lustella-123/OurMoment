import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourmoment/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../services/todos_repository.dart';
import '../../services/user_repository.dart';
import '../../state/app_settings.dart';
import '../../widgets/network_retry_banner.dart';

class MemoScreen extends StatefulWidget {
  const MemoScreen({super.key});

  @override
  State<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> {
  String _selectedCategory = 'all';
  int _reloadTick = 0;
  bool _openingEditor = false;

  static const _cardColors = <String, Color>{
    'rose': Color(0x26FF8FA3),
    'orange': Color(0x26FFB86B),
    'yellow': Color(0x26FFE082),
    'green': Color(0x2691E7B3),
    'blue': Color(0x268EC5FF),
    'purple': Color(0x26C8A4FF),
    'mint': Color(0x268DE9D1),
  };

  Color _cardColor(String key) => _cardColors[key] ?? _cardColors['rose']!;

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final isMono = context.watch<AppSettings>().themePalette.id == 'mono_white';
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: context.read<UserRepository>().watchUser(user.uid),
      builder: (context, userSnap) {
        if (userSnap.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.memoTitle)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '메모 정보를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        if (!userSnap.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.memoTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final data = userSnap.data?.data();
        final coupleId = data?['coupleId'] as String?;
        final myName = ((data?['displayName'] as String?) ?? '').trim();
        return Scaffold(
          appBar: AppBar(title: Text(l10n.memoTitle)),
          floatingActionButton: (coupleId == null || coupleId.isEmpty)
              ? const SizedBox.shrink()
              : FloatingActionButton(
                  onPressed: _openingEditor
                      ? null
                      : () => _openEditor(context, coupleId: coupleId),
                  child: const Icon(Icons.edit),
                ),
          body: Column(
            children: [
              NetworkRetryBanner(onRetry: () => setState(() => _reloadTick++)),
              Expanded(
                child: (coupleId == null || coupleId.isEmpty)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.memoNoCouple,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : StreamBuilder<List<String>>(
                        key: ValueKey('memo-cat-$_reloadTick'),
                        stream: context.read<TodosRepository>().watchCategories(
                          coupleId,
                        ),
                        builder: (context, catSnap) {
                          if (catSnap.hasError) {
                            return const Center(
                              child: Text('카테고리를 불러오지 못했어요.'),
                            );
                          }
                          if (!catSnap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final categories = catSnap.data ?? const <String>[];
                          final effectiveSelected =
                              _selectedCategory == 'all' ||
                                  categories.contains(_selectedCategory)
                              ? _selectedCategory
                              : 'all';
                          return Column(
                            children: [
                              SizedBox(
                                height: 52,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    10,
                                    16,
                                    8,
                                  ),
                                  children: [
                                    _CategoryChip(
                                      label: '전체',
                                      selected: effectiveSelected == 'all',
                                      onTap: () => setState(
                                        () => _selectedCategory = 'all',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    for (final c in categories) ...[
                                      _CategoryChip(
                                        label: c,
                                        selected: effectiveSelected == c,
                                        onTap: () => setState(
                                          () => _selectedCategory = c,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    _CategoryChip(
                                      label: '+ 카테고리',
                                      selected: false,
                                      onTap: () =>
                                          _openAddCategoryDialog(coupleId),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: StreamBuilder<List<CoupleTodo>>(
                                  stream: context
                                      .read<TodosRepository>()
                                      .watchTodos(coupleId),
                                  builder: (context, snap) {
                                    if (snap.hasError) {
                                      return const Center(
                                        child: Text(
                                          '메모를 불러오지 못했어요. 다시 시도해 주세요.',
                                        ),
                                      );
                                    }
                                    if (!snap.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    var list = snap.data!;
                                    if (effectiveSelected != 'all') {
                                      list = list
                                          .where(
                                            (e) =>
                                                e.category == effectiveSelected,
                                          )
                                          .toList();
                                    }
                                    list.sort(
                                      (a, b) =>
                                          a.sortOrder.compareTo(b.sortOrder),
                                    );
                                    if (list.isEmpty) {
                                      return Center(
                                        child: Text(
                                          '아직 메모가 없어요.\n오른쪽 아래 버튼으로 추가해 주세요.',
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }
                                    return ReorderableListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        8,
                                        14,
                                        14,
                                      ),
                                      buildDefaultDragHandles: false,
                                      itemCount: list.length,
                                      onReorder: (oldIndex, newIndex) async {
                                        if (oldIndex < newIndex) {
                                          newIndex -= 1;
                                        }
                                        if (oldIndex == newIndex) return;
                                        final moving = list.removeAt(oldIndex);
                                        list.insert(newIndex, moving);
                                        final orderedIds = [
                                          for (final t in list) t.id,
                                        ];
                                        try {
                                          await context
                                              .read<TodosRepository>()
                                              .reorderTodos(
                                                coupleId: coupleId,
                                                orderedTodoIds: orderedIds,
                                              );
                                        } catch (e) {
                                          _showError(e);
                                        }
                                      },
                                      itemBuilder: (_, i) {
                                        final t = list[i];
                                        final mine = t.createdBy == user.uid;
                                        return Padding(
                                          key: ValueKey(t.id),
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: _MemoBoardCard(
                                            todo: t,
                                            mine: mine,
                                            name: mine
                                                ? (myName.isEmpty
                                                      ? '나'
                                                      : myName)
                                                : '상대',
                                            color: _cardColor(t.colorKey),
                                            isMono: isMono,
                                            onTap: mine
                                                ? () => _openEditor(
                                                    context,
                                                    coupleId: coupleId,
                                                    current: t,
                                                  )
                                                : null,
                                            onToggleDone:
                                                mine && t.itemType == 'todo'
                                                ? (v) async {
                                                    try {
                                                      await context
                                                          .read<
                                                            TodosRepository
                                                          >()
                                                          .toggleDone(
                                                            coupleId: coupleId,
                                                            todoId: t.id,
                                                            isDone: v,
                                                          );
                                                    } catch (e) {
                                                      _showError(e);
                                                    }
                                                  }
                                                : null,
                                            onDelete: mine
                                                ? () async {
                                                    try {
                                                      await context
                                                          .read<
                                                            TodosRepository
                                                          >()
                                                          .deleteTodo(
                                                            coupleId: coupleId,
                                                            todoId: t.id,
                                                          );
                                                    } catch (e) {
                                                      _showError(e);
                                                    }
                                                  }
                                                : null,
                                            onDragHandle:
                                                ReorderableDragStartListener(
                                                  index: i,
                                                  child: Icon(
                                                    Icons
                                                        .drag_indicator_rounded,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.outline,
                                                  ),
                                                ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddCategoryDialog(String coupleId) async {
    final repo = context.read<TodosRepository>();
    final ctrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('카테고리 추가'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: '카테고리 이름'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('추가'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      try {
        await repo.addCategory(coupleId: coupleId, name: ctrl.text);
      } catch (e) {
        _showError(e);
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _openEditor(
    BuildContext context, {
    required String coupleId,
    CoupleTodo? current,
  }) async {
    if (_openingEditor) return;
    if (mounted) setState(() => _openingEditor = true);
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<TodosRepository>();
    final titleCtrl = TextEditingController(text: current?.title ?? '');
    final noteCtrl = TextEditingController(text: current?.note ?? '');
    var itemType = current?.itemType ?? 'todo';
    var category = current?.category ?? '';
    var colorKey = current?.colorKey ?? 'rose';
    DateTime? due = current?.dueAt;
    var saving = false;
    try {
      final categories = await repo.watchCategories(coupleId).first;
      if (!context.mounted) {
        return;
      }
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) {
            final theme = Theme.of(ctx);
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      current == null
                          ? l10n.memoCreateTitle
                          : l10n.memoEditTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'todo', label: Text('할일')),
                        ButtonSegment(value: 'memo', label: Text('메모')),
                      ],
                      selected: {itemType},
                      onSelectionChanged: (s) =>
                          setModal(() => itemType = s.first),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      // Flutter SDK 버전 간(initialValue/value) API 차이를 흡수하기 위해 value 사용.
                      // ignore: deprecated_member_use
                      value: category.isEmpty ? null : category,
                      hint: const Text('카테고리 선택 (선택)'),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModal(() => category = v ?? ''),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _cardColors.entries
                          .map(
                            (e) => InkWell(
                              onTap: () => setModal(() => colorKey = e.key),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: e.value.withValues(alpha: 0.9),
                                  border: Border.all(
                                    color: colorKey == e.key
                                        ? theme.colorScheme.onSurface
                                        : Colors.transparent,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleCtrl,
                      maxLength: 120,
                      decoration: InputDecoration(
                        labelText: l10n.memoFieldTitle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 6,
                      maxLength: 1500,
                      decoration: InputDecoration(
                        labelText: l10n.memoFieldNote,
                      ),
                    ),
                    if (itemType == 'todo') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: due ?? now,
                                firstDate: DateTime(now.year - 2),
                                lastDate: DateTime(now.year + 5),
                              );
                              if (picked != null) setModal(() => due = picked);
                            },
                            icon: const Icon(Icons.event),
                            label: Text(
                              due == null
                                  ? l10n.memoPickDueDate
                                  : DateFormat.yMMMd(
                                      Localizations.localeOf(ctx).toString(),
                                    ).format(due!),
                            ),
                          ),
                          if (due != null)
                            IconButton(
                              onPressed: () => setModal(() => due = null),
                              icon: const Icon(Icons.close),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) return;
                              setModal(() => saving = true);
                              try {
                                if (current == null) {
                                  await repo.addTodo(
                                    coupleId: coupleId,
                                    title: title,
                                    note: noteCtrl.text,
                                    itemType: itemType,
                                    category: category,
                                    colorKey: colorKey,
                                    dueAt: itemType == 'todo' ? due : null,
                                  );
                                } else {
                                  await repo.updateTodo(
                                    coupleId: coupleId,
                                    todoId: current.id,
                                    title: title,
                                    note: noteCtrl.text,
                                    itemType: itemType,
                                    category: category,
                                    colorKey: colorKey,
                                    dueAt: itemType == 'todo' ? due : null,
                                  );
                                }
                                if (!ctx.mounted) return;
                                FocusScope.of(ctx).unfocus();
                                Navigator.of(ctx).pop(true);
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(
                                    ctx,
                                  ).showSnackBar(SnackBar(content: Text('$e')));
                                  setModal(() => saving = false);
                                }
                              }
                            },
                      child: Text(
                        current == null ? l10n.memoAdd : l10n.profileSave,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      titleCtrl.dispose();
      noteCtrl.dispose();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _openingEditor = false);
        });
      }
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _MemoBoardCard extends StatelessWidget {
  const _MemoBoardCard({
    required this.todo,
    required this.mine,
    required this.name,
    required this.color,
    required this.isMono,
    required this.onTap,
    required this.onToggleDone,
    required this.onDelete,
    required this.onDragHandle,
  });

  final CoupleTodo todo;
  final bool mine;
  final String name;
  final Color color;
  final bool isMono;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleDone;
  final Future<void> Function()? onDelete;
  final Widget onDragHandle;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isMono ? Colors.white : color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isMono
              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.28)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (todo.category.isNotEmpty)
                    Text(
                      todo.category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  const SizedBox(width: 6),
                  onDragHandle,
                ],
              ),
              const SizedBox(height: 8),
              if (todo.itemType == 'todo')
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: todo.isDone,
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: onToggleDone == null
                            ? null
                            : (v) => onToggleDone!(v == true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        todo.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              decoration: todo.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  todo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (todo.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    todo.note,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    DateFormat('yyyy. M. d HH:mm').format(todo.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (onDelete != null)
                    InkWell(
                      onTap: onDelete,
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return card;
  }
}
