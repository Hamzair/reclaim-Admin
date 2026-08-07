import 'package:flutter/material.dart';
import '../const/constants.dart';

class AdminLoader extends StatelessWidget {
  final String? message;
  const AdminLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: primaryColor),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(color: secondaryColor, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final String message;
  const AdminEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          color: secondaryColor,
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
      ),
    );
  }
}

class AdminLoadMoreBar extends StatelessWidget {
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final int loadedCount;

  const AdminLoadMoreBar({
    super.key,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    this.loadedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          loadedCount > 0 ? 'All $loadedCount items loaded' : 'End of list',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Center(
        child: isLoadingMore
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: primaryColor,
                ),
              )
            : ElevatedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more, size: 20),
                label: Text(
                  'Load more${loadedCount > 0 ? ' ($loadedCount loaded)' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
      ),
    );
  }
}
