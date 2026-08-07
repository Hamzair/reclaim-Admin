import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple, non-buggy Firestore page loader.
/// - First page: [refresh]
/// - Next pages: [loadMore] using startAfterDocument
/// - Does not re-fetch previous pages
class FirestorePaginator {
  FirestorePaginator({
    required this.query,
    this.pageSize = 20,
  });

  final Query query;
  final int pageSize;

  DocumentSnapshot? _lastDoc;
  bool hasMore = true;
  bool isLoading = false;
  bool isLoadingMore = false;

  /// Resets and loads the first page.
  Future<List<QueryDocumentSnapshot>> refresh() async {
    if (isLoading) return const [];
    isLoading = true;
    _lastDoc = null;
    hasMore = true;
    try {
      final snap = await query.limit(pageSize).get();
      if (snap.docs.isNotEmpty) {
        _lastDoc = snap.docs.last;
      }
      hasMore = snap.docs.length >= pageSize;
      return snap.docs;
    } finally {
      isLoading = false;
    }
  }

  /// Appends the next page. Returns only the new docs (not the full list).
  Future<List<QueryDocumentSnapshot>> loadMore() async {
    if (!hasMore || isLoadingMore || isLoading || _lastDoc == null) {
      return const [];
    }
    isLoadingMore = true;
    try {
      final snap = await query
          .startAfterDocument(_lastDoc!)
          .limit(pageSize)
          .get();
      if (snap.docs.isNotEmpty) {
        _lastDoc = snap.docs.last;
      }
      hasMore = snap.docs.length >= pageSize;
      return snap.docs;
    } finally {
      isLoadingMore = false;
    }
  }
}
