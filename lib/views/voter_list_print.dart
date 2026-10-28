import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/ph_time.dart';
import '../models/models.dart';
import 'dues_sheet_print.dart';

/// Most voters a Tropa Finder printout lists.
const voterPrintLimit = 5000;

/// How a `voters.status` value reads on screen and on paper.
String formatVoterStatus(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '—';
  final upper = raw.trim().toUpperCase();
  if (upper == 'MEMBER' || upper == 'MEMBERS' || upper == 'COOP' || upper == 'COOPERATIVE') {
    return 'MEMBER';
  }
  return raw.trim();
}

/// The Tropa Finder results as PDF bytes on [format] (portrait): a numbered row per voter with
/// purok, status, PC and HHL, plus barangay when the list spans more than one. [filtersLabel]
/// describes the search; [truncated] notes that only the first [voterPrintLimit] matches are listed.
/// Rows are kept to one line where possible so long lists take as few pages as they can.
Future<Uint8List> buildVoterList({
  required List<Voter> voters,
  required String filtersLabel,
  bool truncated = false,
  PdfPageFormat format = longBond,
}) async {
  final fonts = await pdfFonts();
  final printedOn = formatPh(DateFormat('MMM d, yyyy h:mm a'), phNow());

  const small = pw.TextStyle(fontSize: 7);
  const bold = pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold);
  const pad = pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2);
  final border = pw.TableBorder.all(color: PdfColors.grey600, width: 0.5);

  // A one-barangay list names its barangay in the header instead of on every row.
  final showBarangay = {for (final v in voters) v.barangay.trim().toUpperCase()}.length > 1;
  final columns = <({String header, pw.TableColumnWidth width, String? Function(Voter v) value})>[
    (header: 'Name', width: const pw.FlexColumnWidth(3.4), value: (v) => v.fullName),
    (header: 'Purok', width: const pw.FlexColumnWidth(0.9), value: (v) => v.purok),
    if (showBarangay) (header: 'Barangay', width: const pw.FlexColumnWidth(1.4), value: (v) => v.barangay),
    (header: 'Status', width: const pw.FixedColumnWidth(36), value: (v) => formatVoterStatus(v.status)),
    (header: 'PC', width: const pw.FlexColumnWidth(2.8), value: (v) => v.pc),
    (header: 'HHL', width: const pw.FlexColumnWidth(3.2), value: (v) => v.hhl),
  ];
  // Shared by the repeated column header and the body, so the columns line up.
  final columnWidths = {
    0: const pw.FixedColumnWidth(26),
    for (var i = 0; i < columns.length; i++) i + 1: columns[i].width,
  };

  pw.Widget cell(String? text, {pw.TextStyle style = small}) => pw.Container(
      padding: pad,
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(text == null || text.trim().isEmpty ? '—' : text.trim(), style: style));

  final columnHeader = pw.Table(
    border: border,
    columnWidths: columnWidths,
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          cell('#', style: bold),
          for (final c in columns) cell(c.header, style: bold),
        ],
      ),
    ],
  );

  final doc = pw.Document(theme: fonts.theme);
  doc.addPage(
    pw.MultiPage(
      pageFormat: format.portrait,
      margin: const pw.EdgeInsets.all(24),
      // The default stops at 20 pages; a full [voterPrintLimit] list runs to about 130.
      maxPages: 400,
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text('Tropa Finder — Voter List', style: pw.TextStyle(font: fonts.title, fontSize: 14)),
          pw.SizedBox(height: 2),
          pw.Text(filtersLabel, style: pw.TextStyle(font: fonts.title, fontSize: 10)),
          pw.SizedBox(height: 2),
          pw.Text(
            '${voters.length} voter${voters.length == 1 ? '' : 's'}'
            '${truncated ? ' (first $voterPrintLimit matches only; narrow the filters for the rest)' : ''}'
            '  •  Printed $printedOn',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 6),
          columnHeader,
        ],
      ),
      footer: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ),
      build: (_) => [
        if (voters.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 24),
            child: pw.Center(child: pw.Text('No voters match these filters.', style: small)),
          ),
        pw.Table(
          border: border,
          columnWidths: columnWidths,
          children: [
            for (var i = 0; i < voters.length; i++)
              pw.TableRow(
                children: [
                  cell('${i + 1}'),
                  for (final c in columns) cell(c.value(voters[i])),
                ],
              ),
          ],
        ),
      ],
    ),
  );
  return doc.save();
}
