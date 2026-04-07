import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoupleTodo {
  CoupleTodo({
    required this.id,
    required this.title,
    required this.note,
    required this.isDone,
    required this.likeCount,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.itemType,
    required this.category,
    required this.colorKey,
    required this.sortOrder,
    required this.hasExplicitSortOrder,
    this.dueAt,
  });

  final String id;
  final String title;
  final String note;
  final bool isDone;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueAt;
  final String createdBy;
  final String itemType;
  final String category;
  final String colorKey;
  final double sortOrder;
  final bool hasExplicitSortOrder;

  factory CoupleTodo.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    final created = m['createdAt'] as Timestamp?;
    final updated = m['updatedAt'] as Timestamp?;
    final due = m['dueAt'] as Timestamp?;
    final createdAt = created?.toDate() ?? DateTime.now();
    final rawSort = (m['sortOrder'] as num?)?.toDouble();
    return CoupleTodo(
      id: d.id,
      title: m['title'] as String? ?? '',
      note: m['note'] as String? ?? '',
      isDone: m['isDone'] == true,
      likeCount: (m['likeCount'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      updatedAt: updated?.toDate() ?? DateTime.now(),
      dueAt: due?.toDate(),
      createdBy: m['createdBy'] as String? ?? '',
      itemType: m['itemType'] as String? ?? 'todo',
      category: m['category'] as String? ?? '',
      colorKey: m['colorKey'] as String? ?? 'rose',
      sortOrder: rawSort ?? -createdAt.microsecondsSinceEpoch.toDouble(),
      hasExplicitSortOrder: rawSort != null,
    );
  }
}

class TodosRepository {
  TodosRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _todosCol(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('todos');

  DocumentReference<Map<String, dynamic>> _todoDoc(
    String coupleId,
    String todoId,
  ) => _todosCol(coupleId).doc(todoId);

  Stream<List<CoupleTodo>> watchTodos(String coupleId) {
    return _todosCol(coupleId)
        .snapshots()
        .map((s) {
          final list = s.docs.map(CoupleTodo.fromDoc).toList();
          list.sort((a, b) {
            final bySort = a.sortOrder.compareTo(b.sortOrder);
            if (bySort != 0) return bySort;
            return b.createdAt.compareTo(a.createdAt);
          });
          if (list.length > 300) {
            return list.sublist(0, 300);
          }
          return list;
        });
  }

  Stream<List<String>> watchCategories(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('todoCategories')
        .orderBy('name')
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map((d) => (d.data()['name'] as String? ?? '').trim())
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort(),
        );
  }

  Future<void> addCategory({
    required String coupleId,
    required String name,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('not_authenticated');
    final n = name.trim();
    if (n.isEmpty) return;
    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('todoCategories')
        .doc(n.toLowerCase())
        .set({
          'name': n.length > 30 ? n.substring(0, 30) : n,
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> addTodo({
    required String coupleId,
    required String title,
    required String note,
    required String itemType,
    required String category,
    required String colorKey,
    DateTime? dueAt,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('not_authenticated');
    final t = title.trim();
    if (t.isEmpty) return;
    await _todosCol(coupleId).add({
      'title': t.length > 120 ? t.substring(0, 120) : t,
      'note': note.trim().length > 1500
          ? note.trim().substring(0, 1500)
          : note.trim(),
      'isDone': false,
      'likeCount': 0,
      'dueAt': dueAt == null
          ? null
          : Timestamp.fromDate(DateTime(dueAt.year, dueAt.month, dueAt.day)),
      'itemType': itemType == 'memo' ? 'memo' : 'todo',
      'category': category.trim().length > 30
          ? category.trim().substring(0, 30)
          : category.trim(),
      'colorKey': colorKey,
      // 기본값은 최신 메모가 위에 오도록 음수 timestamp를 사용한다.
      'sortOrder': -DateTime.now().microsecondsSinceEpoch.toDouble(),
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTodo({
    required String coupleId,
    required String todoId,
    required String title,
    required String note,
    required String itemType,
    required String category,
    required String colorKey,
    DateTime? dueAt,
  }) async {
    final t = title.trim();
    if (t.isEmpty) return;
    await _todosCol(coupleId).doc(todoId).update({
      'title': t.length > 120 ? t.substring(0, 120) : t,
      'note': note.trim().length > 1500
          ? note.trim().substring(0, 1500)
          : note.trim(),
      'dueAt': dueAt == null
          ? null
          : Timestamp.fromDate(DateTime(dueAt.year, dueAt.month, dueAt.day)),
      'itemType': itemType == 'memo' ? 'memo' : 'todo',
      'category': category.trim().length > 30
          ? category.trim().substring(0, 30)
          : category.trim(),
      'colorKey': colorKey,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleDone({
    required String coupleId,
    required String todoId,
    required bool isDone,
  }) async {
    await _todosCol(coupleId).doc(todoId).update({
      'isDone': isDone,
      'likeCount': FieldValue.increment(0),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTodo({
    required String coupleId,
    required String todoId,
  }) async {
    final doc = _todoDoc(coupleId, todoId);
    final likes = await doc.collection('likes').get();
    final b = _db.batch();
    for (final d in likes.docs) {
      b.delete(d.reference);
    }
    b.delete(doc);
    await b.commit();
  }

  Future<void> reorderTodos({
    required String coupleId,
    required List<String> orderedTodoIds,
  }) async {
    if (orderedTodoIds.isEmpty) return;
    final batch = _db.batch();
    for (var i = 0; i < orderedTodoIds.length; i++) {
      final id = orderedTodoIds[i];
      batch.update(_todoDoc(coupleId, id), {
        'sortOrder': i.toDouble(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Stream<bool> watchLiked(String coupleId, String todoId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(false);
    return _todoDoc(
      coupleId,
      todoId,
    ).collection('likes').doc(uid).snapshots().map((s) => s.exists);
  }

  Future<void> toggleLike({
    required String coupleId,
    required String todoId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final todo = _todoDoc(coupleId, todoId);
    final likeRef = todo.collection('likes').doc(uid);
    await _db.runTransaction((txn) async {
      final likeSnap = await txn.get(likeRef);
      final todoSnap = await txn.get(todo);
      if (!todoSnap.exists) return;
      final count = (todoSnap.data()?['likeCount'] as num?)?.toInt() ?? 0;
      if (likeSnap.exists) {
        txn.delete(likeRef);
        txn.update(todo, {
          'likeCount': count > 0 ? count - 1 : 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        txn.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        txn.update(todo, {
          'likeCount': count + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
