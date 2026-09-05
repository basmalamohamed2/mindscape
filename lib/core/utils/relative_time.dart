String relativeTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);

  if (difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays == 1) return 'yesterday';
  if (difference.inDays < 7) return '${difference.inDays}d ago';

  final weeks = (difference.inDays / 7).floor();
  if (weeks < 5) return '${weeks}w ago';

  final months = (difference.inDays / 30).floor();
  return months <= 1 ? '1mo ago' : '${months}mo ago';
}
