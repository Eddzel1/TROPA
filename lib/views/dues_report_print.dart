import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/dues_math.dart';
import '../core/ph_time.dart';
import '../models/models.dart';
import '../providers/dues_provider.dart';
import 'dues_sheet_print.dart';

/// Column heading for a fund with its percentage, e.g. "Mortuary 60%", shared by the Funds tab
/// and its printed report.
String fundHeading(DuesFund fund, Map<DuesFund, double> percents) {
  final name = switch (fund) {
    DuesFund.purokOperations => 'Purok Operational Cost',
    DuesFund.federationOperations => 'TROPA Federation Operational Cost',
    _ => fund.label,
  };
  return '$name ${percentLabel(percents[fund] ?? 0)}';
}

/// The Dues Fund Allocation Report as PDF bytes on [format] (portrait): one row per purok with
/// what it collected in [periodLabel] and how that divides into the funds, then a total row.
/// [percents] labels the fund columns; [changes] are months within the period where the split
/// changed, noted under the table. Ends with signature lines for the treasurer's records.
Future<Uint8List> buildDuesAllocationReport({
  required String periodLabel,
  required String placeLabel,
  required List<DuesFundsRow> rows,
  required Map<DuesFund, double> funds,
  required double total,
  required Map<DuesFund, double> percents,
  required List<int> changes,
  PdfPageFormat format = longBond,
}) async {
  final fonts = await pdfFonts();
  final peso = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
  final printedOn = formatPh(DateFormat('MMM d, yyyy h:mm a'), phNow());

  const small = pw.TextStyle(fontSize: 8);
  const bold = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
  const pad = pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4);

  pw.Widget cell(String text, {pw.TextStyle style = small, bool right = false}) => pw.Padding(
        padding: pad,
        child: pw.Text(text, style: style, textAlign: right ? pw.TextAlign.right : pw.TextAlign.left),
      );

  final table = pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
    columnWidths: {
      0: const pw.FlexColumnWidth(1.6),
      1: const pw.FlexColumnWidth(1.8),
      2: const pw.FlexColumnWidth(1.4),
      for (var i = 0; i < DuesFund.values.length; i++) i + 3: const pw.FlexColumnWidth(1.5),
      DuesFund.values.length + 3: const pw.FlexColumnWidth(1.5),
    },
    children: [
      // Repeated at the top of every page of a long report.
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          cell('LGU', style: bold),
          cell('Barangay', style: bold),
          cell('Purok', style: bold),
          for (final f in DuesFund.values) cell(fundHeading(f, percents), style: bold, right: true),
          cell('Total', style: bold, right: true),
        ],
      ),
      for (final r in rows)
        pw.TableRow(children: [
          cell(r.lgu),
          cell(r.barangay),
          cell(r.purok.isEmpty ? '—' : r.purok),
          for (final f in DuesFund.values) cell(peso.format(r.funds[f]), right: true),
          cell(peso.format(r.total), style: bold, right: true),
        ]),
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          cell('Total', style: bold),
          cell(''),
          cell(''),
          for (final f in DuesFund.values) cell(peso.format(funds[f]), style: bold, right: true),
          cell(peso.format(total), style: bold, right: true),
        ],
      ),
    ],
  );

  pw.Widget signature(String role) => pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 36),
            pw.Container(height: 0.6, color: PdfColors.grey800),
            pw.SizedBox(height: 3),
            pw.Text(role, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ],
        ),
      );

  final doc = pw.Document(theme: fonts.theme);
  doc.addPage(
    pw.MultiPage(
      pageFormat: format.portrait,
      margin: const pw.EdgeInsets.all(28),
      footer: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ),
      build: (_) => [
        pw.Text('Dues Fund Allocation Report', style: pw.TextStyle(font: fonts.title, fontSize: 16)),
        pw.SizedBox(height: 4),
        pw.Text('$placeLabel  •  $periodLabel', style: pw.TextStyle(font: fonts.title, fontSize: 11)),
        pw.SizedBox(height: 2),
        pw.Text(
          '${rows.length} purok${rows.length == 1 ? '' : 's'} with collections  •  Voided receipts excluded  '
          '•  Printed $printedOn',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 12),
        table,
        if (changes.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            'The split changed in ${changes.map(monthLabel).join(', ')}. Each payment is divided with the split in '
            'force when it was paid; the column headings show the current split.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
        pw.SizedBox(height: 28),
        pw.Row(children: [signature('Prepared by (Treasurer)'), pw.SizedBox(width: 40), signature('Noted by')]),
      ],
    ),
  );
  return doc.save();
}
