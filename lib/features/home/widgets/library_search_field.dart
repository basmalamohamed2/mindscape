import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/theme/app_colors.dart';

class LibrarySearchField extends StatelessWidget {
  const LibrarySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.inter(color: AppColors.paper, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search your maps',
        hintStyle: GoogleFonts.inter(color: AppColors.muted, fontSize: 13),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.muted,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.thread),
        ),
      ),
    );
  }
}
