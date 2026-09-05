import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({super.key, required this.isSearch});

  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          Icon(
            isSearch ? Icons.search_off_rounded : Icons.star_outline_rounded,
            color: AppColors.muted,
            size: 32,
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              isSearch ? 'No maps match your search' : 'No maps yet',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.paper,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? 'Try a different title.'
                : 'Tap the + button to start your first mind map.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
