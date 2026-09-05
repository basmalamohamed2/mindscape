import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/connectivity/offline_banner.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/features/auth/logic/auth_controller.dart';
import 'package:mindspace/features/canvas/screens/canvas_screen.dart';
import 'package:mindspace/features/home/logic/home_controller.dart';
import 'package:mindspace/features/home/logic/provider/mind_map_repository.dart';
import 'package:mindspace/features/home/widgets/create_map_dialog.dart';
import 'package:mindspace/features/home/widgets/library_empty_state.dart';
import 'package:mindspace/features/home/widgets/library_search_field.dart';
import 'package:mindspace/features/home/widgets/mind_map_card.dart';
import 'package:mindspace/models/mind_map_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapsAsync = ref.watch(userMindMapsProvider);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your maps',
                          style: GoogleFonts.fraunces(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppColors.paper,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sign out',
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.muted,
                            size: 20,
                          ),
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LibrarySearchField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: mapsAsync.when(
                        data: (maps) => _MapList(maps: maps, query: _query),
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(AppColors.spark),
                          ),
                        ),
                        error: (error, _) => Center(
                          child: Text(
                            'Could not load your maps.\n$error',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: AppColors.muted),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.spark,
        foregroundColor: AppColors.sparkText,
        onPressed: _createMap,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createMap() async {
    final id = await CreateMapDialog.show(context);
    if (id == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CanvasScreen(mapId: id, title: 'Untitled map'),
      ),
    );
  }
}

class _MapList extends ConsumerWidget {
  const _MapList({required this.maps, required this.query});

  final List<MindMap> maps;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = query.isEmpty
        ? maps
        : maps.where((m) => m.title.toLowerCase().contains(query)).toList();

    if (filtered.isEmpty) {
      return LibraryEmptyState(isSearch: query.isNotEmpty);
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final map = filtered[index];
        return MindMapCard(
          mindMap: map,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CanvasScreen(mapId: map.id, title: map.title),
            ),
          ),
          onDelete: () =>
              ref.read(homeControllerProvider.notifier).deleteMindMap(map.id),
        );
      },
    );
  }
}
