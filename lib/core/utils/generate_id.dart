String generateId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final rand = (now * 2654435761) % 1000000;
  return 'node_${now}_$rand';
}
