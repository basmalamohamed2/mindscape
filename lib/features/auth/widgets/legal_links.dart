import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindspace/core/constants/app_links.dart';
import 'package:mindspace/core/theme/app_colors.dart';
import 'package:mindspace/core/utils/open_url.dart';

class LegalLinks extends StatefulWidget {
  const LegalLinks({super.key});

  @override
  State<LegalLinks> createState() => _LegalLinksState();
}

class _LegalLinksState extends State<LegalLinks> {
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = () => openExternalUrl(termsUrl);
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = () => openExternalUrl(privacyPolicyUrl);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.jetBrainsMono(
      fontSize: 10.5,
      color: AppColors.muted,
      height: 1.6,
    );
    final link = base.copyWith(
      color: AppColors.thread,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.thread,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'By continuing you agree to the\n'),
          TextSpan(text: 'Terms', style: link, recognizer: _terms),
          const TextSpan(text: ' & '),
          TextSpan(text: 'Privacy Policy', style: link, recognizer: _privacy),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
