import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mindspace/core/utils/generate_id.dart';
import 'package:mindspace/features/canvas/logic/provider/canvas_repository.dart';
import 'package:mindspace/features/canvas/logic/provider/node_media_repository.dart';
import 'package:mindspace/models/canvas_node_model.dart';

final nodeImageUploadProvider = StateProvider<String?>((ref) => null);

class CanvasState {
  const CanvasState({
    this.nodes = const [],
    this.selectedNodeId,
    this.isLoading = true,
    this.isSyncing = false,
    this.error,
  });

  final List<CanvasNode> nodes;
  final String? selectedNodeId;
  final bool isLoading;
  final bool isSyncing;
  final Object? error;

  CanvasNode? get selectedNode {
    if (selectedNodeId == null) return null;
    for (final node in nodes) {
      if (node.id == selectedNodeId) return node;
    }
    return null;
  }

  CanvasState copyWith({
    List<CanvasNode>? nodes,
    String? selectedNodeId,
    bool clearSelection = false,
    bool? isLoading,
    bool? isSyncing,
    Object? error,
    bool clearError = false,
  }) {
    return CanvasState(
      nodes: nodes ?? this.nodes,
      selectedNodeId: clearSelection
          ? null
          : (selectedNodeId ?? this.selectedNodeId),
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CanvasController extends StateNotifier<CanvasState> {
  CanvasController(this._ref, this._mapId) : super(const CanvasState()) {
    _subscribe();
  }

  final Ref _ref;
  final String _mapId;
  StreamSubscription<List<CanvasNode>>? _subscription;
  StreamSubscription<bool>? _syncStatusSubscription;

  final Map<String, Timer> _positionDebounce = {};

  CanvasRepository get _repository => _ref.read(canvasRepositoryProvider);

  void _subscribe() {
    _subscription = _repository
        .watchNodes(_mapId)
        .listen(
          (remoteNodes) {
            final merged = _mergeWithLocalDrags(remoteNodes);
            state = state.copyWith(
              nodes: merged,
              isLoading: false,
              clearError: true,
            );
          },
          onError: (error) {
            state = state.copyWith(isLoading: false, error: error);
          },
        );

    _syncStatusSubscription = _repository
        .watchSyncStatus(_mapId)
        .listen((isSyncing) => state = state.copyWith(isSyncing: isSyncing));
  }

  List<CanvasNode> _mergeWithLocalDrags(List<CanvasNode> remoteNodes) {
    if (_positionDebounce.isEmpty) return remoteNodes;

    final localById = {for (final n in state.nodes) n.id: n};
    return [
      for (final remote in remoteNodes)
        if (_positionDebounce.containsKey(remote.id) &&
            localById.containsKey(remote.id))
          remote.copyWith(position: localById[remote.id]!.position)
        else
          remote,
    ];
  }

  @override
  void dispose() {
    for (final timer in _positionDebounce.values) {
      timer.cancel();
    }
    _subscription?.cancel();
    _syncStatusSubscription?.cancel();
    super.dispose();
  }

  void selectNode(String? id) {
    state = state.copyWith(selectedNodeId: id, clearSelection: id == null);
  }

  void addNode({required Offset position, String? parentId}) {
    final node = CanvasNode(
      id: generateId(),
      text: 'New idea',
      color: const Color(0xFF6DE1D2),
      position: position,
      parentId: parentId,
    );

    state = state.copyWith(
      nodes: [...state.nodes, node],
      selectedNodeId: node.id,
    );
    _repository.createNode(_mapId, node);
  }

  void updateNodePosition(String id, Offset position) {
    state = state.copyWith(
      nodes: _replace(id, (n) => n.copyWith(position: position)),
    );

    _positionDebounce[id]?.cancel();
    _positionDebounce[id] = Timer(const Duration(milliseconds: 400), () {
      _positionDebounce.remove(id);
      _repository.updateNodeFields(_mapId, id, {
        'position': {'x': position.dx, 'y': position.dy},
      });
    });
  }

  void commitNodePosition(String id, Offset position) {
    _positionDebounce.remove(id)?.cancel();
    state = state.copyWith(
      nodes: _replace(id, (n) => n.copyWith(position: position)),
    );
    _repository.updateNodeFields(_mapId, id, {
      'position': {'x': position.dx, 'y': position.dy},
    });
  }

  void updateNodeText(String id, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      nodes: _replace(id, (n) => n.copyWith(text: trimmed)),
    );
    _repository.updateNodeFields(_mapId, id, {'text': trimmed});
  }

  void updateNodeColor(String id, Color color) {
    state = state.copyWith(
      nodes: _replace(id, (n) => n.copyWith(color: color)),
    );
    _repository.updateNodeFields(_mapId, id, {
      'color': '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    });
  }

  Future<void> attachImage(String nodeId, String filePath) async {
    _ref.read(nodeImageUploadProvider.notifier).state = nodeId;
    try {
      final url = await _ref
          .read(nodeMediaRepositoryProvider)
          .uploadNodeImage(mapId: _mapId, nodeId: nodeId, filePath: filePath);
      state = state.copyWith(
        nodes: _replace(nodeId, (n) => n.copyWith(imageUrl: url)),
      );
      await _repository.updateNodeFields(_mapId, nodeId, {'imageUrl': url});
    } catch (error, stackTrace) {
      state = state.copyWith(error: error);
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _ref.read(nodeImageUploadProvider.notifier).state = null;
    }
  }

  Future<void> removeImage(String nodeId) async {
    state = state.copyWith(
      nodes: _replace(nodeId, (n) => n.copyWith(clearImage: true)),
    );
    await _repository.updateNodeFields(_mapId, nodeId, {
      'imageUrl': FieldValue.delete(),
    });
    unawaited(
      _ref
          .read(nodeMediaRepositoryProvider)
          .deleteNodeImage(mapId: _mapId, nodeId: nodeId)
          .catchError((_) {}),
    );
  }

  void deleteNode(String id) {
    CanvasNode? target;
    for (final node in state.nodes) {
      if (node.id == id) {
        target = node;
        break;
      }
    }
    if (target == null) return;

    if (target.isRoot) {
      final directChildren = state.nodes
          .where((n) => n.parentId == id)
          .toList();
      if (directChildren.isNotEmpty) {
        final newRootId = directChildren.first.id;
        final updates = <String, Map<String, dynamic>>{
          newRootId: {'parent': FieldValue.delete()},
        };
        for (final child in directChildren.skip(1)) {
          updates[child.id] = {'parent': newRootId};
        }

        final remaining = <CanvasNode>[];
        for (final node in state.nodes) {
          if (node.id == id) continue;
          if (node.id == newRootId) {
            remaining.add(node.copyWith(clearParent: true));
          } else if (node.parentId == id) {
            remaining.add(node.copyWith(parentId: newRootId));
          } else {
            remaining.add(node);
          }
        }

        state = state.copyWith(
          nodes: remaining,
          clearSelection: state.selectedNodeId == id,
        );
        _repository.applyBatch(
          mapId: _mapId,
          deletions: [id],
          updates: updates,
        );
        _cleanupImage(id, target.hasImage);
        return;
      }
    }

    final toRemove = <String>{id};
    var grew = true;
    while (grew) {
      grew = false;
      for (final node in state.nodes) {
        if (node.parentId != null &&
            toRemove.contains(node.parentId) &&
            !toRemove.contains(node.id)) {
          toRemove.add(node.id);
          grew = true;
        }
      }
    }

    final imagesToClean = <String>{
      for (final node in state.nodes)
        if (toRemove.contains(node.id) && node.hasImage) node.id,
    };

    final remaining = state.nodes
        .where((n) => !toRemove.contains(n.id))
        .toList();
    final clearSelection = toRemove.contains(state.selectedNodeId);
    state = state.copyWith(nodes: remaining, clearSelection: clearSelection);
    _repository.applyBatch(mapId: _mapId, deletions: toRemove.toList());

    for (final removedId in imagesToClean) {
      _cleanupImage(removedId, true);
    }
  }

  void _cleanupImage(String nodeId, bool hadImage) {
    if (!hadImage) return;
    unawaited(
      _ref
          .read(nodeMediaRepositoryProvider)
          .deleteNodeImage(mapId: _mapId, nodeId: nodeId)
          .catchError((_) {}),
    );
  }

  List<CanvasNode> _replace(String id, CanvasNode Function(CanvasNode) update) {
    return [
      for (final node in state.nodes)
        if (node.id == id) update(node) else node,
    ];
  }
}

final canvasControllerProvider =
    StateNotifierProvider.family<CanvasController, CanvasState, String>(
      (ref, mapId) => CanvasController(ref, mapId),
    );
