import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/design_system.dart';
import '../data/db.dart';
import '../services/voter_snapshot.dart';
import '../core/ph_time.dart';

/// One-line status of the offline voter list, e.g. "Offline voter list: 200,833 voters · updated Oct 14".
class VoterSnapshotStatusLine extends ConsumerWidget {
  const VoterSnapshotStatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(voterSnapshotStatusProvider).value;
    final muted = TropaColors.textMedium(context);
    final count = status.count == null ? null : NumberFormat('#,###').format(status.count);
    final updated = parsePh(status.version);
    final updatedText = updated == null ? '' : ' · updated ${formatPh(DateFormat('MMM d, y'), updated)}';

    final (icon, color, text, canRetry) = switch (status.phase) {
      VoterSnapshotPhase.ready => (Icons.offline_pin_outlined, TropaColors.secondaryOf(context), 'Offline voter list: $count voters$updatedText', false),
      VoterSnapshotPhase.downloading => (Icons.downloading, muted, 'Downloading offline voter list…', false),
      VoterSnapshotPhase.installing =>
        (Icons.downloading, muted, 'Installing offline voter list… ${((status.progress ?? 0) * 100).round()}%', false),
      VoterSnapshotPhase.notInstalled =>
        (Icons.cloud_outlined, TropaColors.offline, 'Offline voter list not downloaded yet; searches need internet', true),
      VoterSnapshotPhase.error => (
          Icons.error_outline,
          TropaColors.offline,
          count == null ? 'Could not download the offline voter list' : 'Offline voter list: $count voters$updatedText (update failed)',
          true,
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(text, style: TropaText.meta(muted)),
        if (canRetry) ...[
          const SizedBox(width: 4),
          TextButton(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact, textStyle: GoogleFonts.inter(fontSize: 12)),
            onPressed: () => ensureVoterSnapshot(ref.read(localDbProvider), Supabase.instance.client),
            child: const Text('Try again'),
          ),
        ],
      ],
    );
  }
}
