import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/ph_time.dart';
import '../models/models.dart';
import '../tropa_id/tropa_id.dart';

/// Printed on the back of every card. Fill these in before issuing cards.
const tropaIssuer = TropaIssuer();

/// Builds the card data for [m]. Null when the member has no ID number yet (added offline and not
/// synced, since the server assigns it).
TropaMember? tropaMemberFrom(FamilyMember m) {
  final idNumber = m.idNumber;
  if (idNumber == null || idNumber.isEmpty) return null;

  // An ID issued today is valid for five years, counting this one.
  final today = phToday();
  final middle = (m.middlename ?? '').trim();
  final ext = (m.extension ?? '').trim();
  final photoUrl = (m.profilePictureUrl ?? '').trim();
  return TropaMember(
    firstName: m.firstname,
    middleInitial: middle.isEmpty ? '' : middle[0],
    lastName: [m.lastname, if (ext.isNotEmpty) ext].join(' '),
    idNumber: idNumber,
    memberType: m.isHouseholdLeader ? 'Household Leader' : 'Member',
    address: [m.purok, m.barangay, m.lgu].map((s) => s.trim()).where((s) => s.isNotEmpty).join(', '),
    birthDate: m.birthDate,
    dateIssued: today,
    validUntil: DateTime(today.year + 4, 12, 31),
    memberSince: (m.membershipDate ?? toPh(m.createdDate)).year,
    status: m.isArchived ? 'INACTIVE' : 'ACTIVE',
    photo: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
  );
}

/// A member's TROPA ID: tap to flip, and print both sides at card size.
class MemberIdView extends StatefulWidget {
  final FamilyMember member;

  const MemberIdView({super.key, required this.member});

  @override
  State<MemberIdView> createState() => _MemberIdViewState();
}

class _MemberIdViewState extends State<MemberIdView> {
  final _frontKey = GlobalKey();
  final _backKey = GlobalKey();
  bool _printing = false;

  @override
  Widget build(BuildContext context) {
    final card = tropaMemberFrom(widget.member);
    return Scaffold(
      appBar: AppBar(title: Text('TROPA ID · ${widget.member.fullName}')),
      body: card == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This member has no ID number yet. It is assigned once the member syncs to the server.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Stack(
              children: [
                // Copies used only for printing, parked off-screen. They must still be painted
                // (Offstage or Opacity 0 would skip painting, and the capture would fail).
                Positioned(
                  left: -4000,
                  top: 0,
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: 856,
                      child: Column(
                        children: [
                          TropaIdCapture(captureKey: _frontKey, child: TropaIdCardFront(member: card)),
                          TropaIdCapture(
                            captureKey: _backKey,
                            child: TropaIdCardBack(member: card, issuer: tropaIssuer),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(20),
                      children: [
                        TropaIdFlipCard(member: card, issuer: tropaIssuer),
                        const SizedBox(height: 12),
                        const Text('Tap the card to see the back', textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        Center(
                          child: FilledButton.icon(
                            onPressed: _printing ? null : _print,
                            icon: const Icon(Icons.print_outlined),
                            label: Text(_printing ? 'Preparing…' : 'Print ID'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Both sides as a two-page PDF at CR80 size (3.375 x 2.125 in), rendered at 300 dpi.
  Future<void> _print() async {
    setState(() => _printing = true);
    try {
      final front = await captureTropaIdPng(_frontKey, dpi: 300);
      final back = await captureTropaIdPng(_backKey, dpi: 300);
      const format = PdfPageFormat(3.375 * PdfPageFormat.inch, 2.125 * PdfPageFormat.inch);
      final doc = pw.Document();
      for (final side in [front, back]) {
        doc.addPage(pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(pw.MemoryImage(side), fit: pw.BoxFit.fill),
        ));
      }
      await Printing.layoutPdf(
        name: 'TROPA ID ${widget.member.idNumber}',
        format: format,
        onLayout: (_) => doc.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not print the ID: $e')));
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }
}
