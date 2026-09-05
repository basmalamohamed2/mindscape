import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/features/canvas/logic/canvas_controller.dart';
import 'package:mindspace/features/canvas/widgets/canvas_node_widget.dart';
import 'package:mindspace/features/canvas/widgets/connections_painter.dart';
import 'package:mindspace/features/canvas/widgets/node_edit_sheet.dart';

class CanvasScreen extends ConsumerStatefulWidget {
  const CanvasScreen({super.key, required this.mapId, required this.title});

  final String mapId;
  final String title;

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  Size _viewportSize = const Size(390, 700);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(canvasControllerProvider(widget.mapId));
    final controller = ref.read(
      canvasControllerProvider(widget.mapId).notifier,
    );

    ref.listen(canvasControllerProvider(widget.mapId), (previous, next) {
      final justSelected =
          next.selectedNodeId != null &&
          previous?.selectedNodeId != next.selectedNodeId;
      if (justSelected && next.selectedNode != null) {
        NodeEditSheet.show(
          context,
          mapId: widget.mapId,
          node: next.selectedNode!,
        ).whenComplete(() => controller.selectNode(null));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.paper),
        title: Text(
          widget.title,
          style: GoogleFonts.inter(color: AppColors.paper),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _viewportSize = constraints.biggest;
          return _buildBody(context, state, controller);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.spark,
        foregroundColor: AppColors.sparkText,
        onPressed: () => controller.addNode(
          position:
              Offset(_viewportSize.width / 2, _viewportSize.height / 2) +
              const Offset(40, -40),
          parentId: state.nodes.isEmpty ? null : state.nodes.last.id,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CanvasState state,
    CanvasController controller,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.spark),
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Text(
          'Could not load this map.\n${state.error}',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: AppColors.muted),
        ),
      );
    }

    if (state.nodes.isEmpty) {
      return Center(
        child: TextButton.icon(
          onPressed: () => controller.addNode(
            position: Offset(_viewportSize.width / 2, _viewportSize.height / 2),
          ),
          icon: const Icon(
            Icons.auto_awesome_outlined,
            color: AppColors.thread,
          ),
          label: Text(
            'Add your first idea',
            style: GoogleFonts.inter(color: AppColors.thread),
          ),
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(800),
      child: SizedBox(
        width: _viewportSize.width,
        height: _viewportSize.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: ConnectionsPainter(state.nodes)),
            ),
            for (final node in state.nodes)
              CanvasNodeWidget(
                key: ValueKey(node.id),
                node: node,
                isSelected: node.id == state.selectedNodeId,
                onTap: () => controller.selectNode(node.id),
                onDragUpdate: (pos) =>
                    controller.updateNodePosition(node.id, pos),
                onDragEnd: (pos) => controller.commitNodePosition(node.id, pos),
              ),
          ],
        ),
      ),
    );
  }
}
