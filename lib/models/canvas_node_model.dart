import 'dart:ui';

class CanvasNode {
  const CanvasNode({
    required this.id,
    required this.text,
    required this.color,
    required this.position,
    this.parentId,
  });

  final String id;
  final String text;
  final Color color;
  final Offset position;
  final String? parentId;

  bool get isRoot => parentId == null;

  CanvasNode copyWith({
    String? text,
    Color? color,
    Offset? position,
    String? parentId,
    bool clearParent = false,
  }) {
    return CanvasNode(
      id: id,
      text: text ?? this.text,
      color: color ?? this.color,
      position: position ?? this.position,
      parentId: clearParent ? null : (parentId ?? this.parentId),
    );
  }

  factory CanvasNode.fromMap(Map<String, dynamic> map) {
    final positionMap = map['position'] as Map<String, dynamic>? ?? const {};
    return CanvasNode(
      id: map['id'] as String,
      text: (map['text'] as String?) ?? '',
      color: _colorFromHex(map['color'] as String?),
      parentId: map['parent'] as String?,
      position: Offset(
        (positionMap['x'] as num?)?.toDouble() ?? 0,
        (positionMap['y'] as num?)?.toDouble() ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'color': _colorToHex(color),
      if (parentId != null) 'parent': parentId,
      'position': {'x': position.dx, 'y': position.dy},
    };
  }

  static Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFFFB84D);
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0xFFFFB84D;
    return Color(cleaned.length == 6 ? (0xFF000000 | value) : value);
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}