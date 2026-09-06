import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

class CanvasNode {
  const CanvasNode({
    required this.id,
    required this.text,
    required this.color,
    required this.position,
    this.parentId,
    this.imageUrl,
    this.dueDate,
    this.isCompleted = false,
  });

  final String id;
  final String text;
  final Color color;
  final Offset position;
  final String? parentId;
  final String? imageUrl;
  final DateTime? dueDate;
  final bool isCompleted;

  bool get isRoot => parentId == null;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isTask => dueDate != null;

  CanvasNode copyWith({
    String? text,
    Color? color,
    Offset? position,
    String? parentId,
    bool clearParent = false,
    String? imageUrl,
    bool clearImage = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isCompleted,
  }) {
    return CanvasNode(
      id: id,
      text: text ?? this.text,
      color: color ?? this.color,
      position: position ?? this.position,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory CanvasNode.fromMap(Map<String, dynamic> map) {
    final positionMap = map['position'] as Map<String, dynamic>? ?? const {};
    final dueTimestamp = map['dueDate'];

    return CanvasNode(
      id: map['id'] as String,
      text: (map['text'] as String?) ?? '',
      color: _colorFromHex(map['color'] as String?),
      parentId: map['parent'] as String?,
      imageUrl: map['imageUrl'] as String?,
      dueDate: dueTimestamp is Timestamp ? dueTimestamp.toDate() : null,
      isCompleted: (map['isCompleted'] as bool?) ?? false,
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
      if (hasImage) 'imageUrl': imageUrl,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      if (dueDate != null) 'isCompleted': isCompleted,
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
