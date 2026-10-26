import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/dues_math.dart';
import '../core/ph_time.dart';
import '../models/models.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Months already paid.
const _paidFill = PdfColors.grey200;

/// Months before a member's dues start, or members who aren't billed. Crossed with an X.
const _notBilledFill = PdfColors.grey500;

/// Long bond paper (8.5 x 13 in), portrait.
const longBond = PdfPageFormat(8.5 * PdfPageFormat.inch, 13 * PdfPageFormat.inch, marginAll: 28);

/// Paper sizes the sheet can be printed on, as offered in the preview.
const duesSheetFormats = {'Long (8.5 × 13 in)': longBond, 'A4': PdfPageFormat.a4};

/// The app's fonts, bundled so the sheet prints offline: Inter for text, Manrope for the title.
Future<({pw.ThemeData theme, pw.Font title})> _pdfFonts() async {
  Future<pw.Font> load(String name) async => pw.Font.ttf(await rootBundle.load('assets/fonts/$name.ttf'));
  final regular = await load('Inter-Regular');
  final bold = await load('Inter-Bold');
  return (theme: pw.ThemeData.withFont(base: regular, bold: bold), title: await load('Manrope-Bold'));
}

/// A collection sheet for [households] (one barangay, one or all puroks), as PDF bytes on [format]
/// (portrait): a row per
/// member with a box for each month of [year]. Paid months are marked and months not billed are
/// shaded, so only the boxes still to collect are blank.
Future<Uint8List> buildDuesSheet({
  required List<DuesHousehold> households,
  required String barangayLabel,
  String? purok,
  required int year,
  required List<DuesRate> rates,
  PdfPageFormat format = longBond,
}) async {
  final fonts = await _pdfFonts();
  final printedOn = formatPh(DateFormat('MMM d, yyyy h:mm a'), phNow());
  final members = households.fold<int>(0, (n, h) => n + h.members.length);

  const small = pw.TextStyle(fontSize: 8);
  const bold = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
  const pad = pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6);
  final border = pw.TableBorder.all(color: PdfColors.grey600, width: 0.5);
  // Shared by the repeated column header and every household's table, so the columns line up.
  final columnWidths = {
    0: const pw.FixedColumnWidth(20),
    1: const pw.FlexColumnWidth(),
    for (var m = 0; m < 12; m++) m + 2: const pw.FixedColumnWidth(26),
  };

  // Rows stretch every cell to the row's height, so text cells center themselves.
  pw.Widget cell(String text, {pw.TextStyle style = small, pw.Alignment align = pw.Alignment.centerLeft}) =>
      pw.Container(padding: pad, alignment: align, child: pw.Text(text, style: style));

  pw.Widget monthCell(DuesBalance? balance, int month) {
    final paidThrough = balance?.paidThroughMonth;
    if (balance == null || month < balance.startMonth) {
      // A shaded box crossed corner to corner, so nobody writes in it.
      return pw.Container(
        color: _notBilledFill,
        height: 22,
        child: pw.CustomPaint(
          painter: (canvas, size) => canvas
            ..setStrokeColor(PdfColors.grey800)
            ..setLineWidth(0.8)
            ..moveTo(0, 0)
            ..lineTo(size.x, size.y)
            ..moveTo(size.x, 0)
            ..lineTo(0, size.y)
            ..strokePath(),
        ),
      );
    }
    if (paidThrough != null && month <= paidThrough) {
      return pw.Container(
        color: _paidFill,
        height: 22,
        alignment: pw.Alignment.center,
        child: pw.Text('PAID', style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey700)),
      );
    }
    return pw.SizedBox(height: 22);
  }

  final columnHeader = pw.Table(
    border: border,
    columnWidths: columnWidths,
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          cell('#', style: bold),
          cell('Member', style: bold),
          for (final m in _months) cell(m, style: bold, align: pw.Alignment.center),
        ],
      ),
    ],
  );

  pw.TableRow memberRow(DuesMember member, int number) {
    final balance = balanceFor(member, rates);
    return pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.full,
      children: [
        cell('$number'),
        pw.Container(
          padding: pad,
          alignment: pw.Alignment.centerLeft,
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(member.fullName, style: small),
              if (balance == null)
                pw.Text(unbilledReason(member), style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
            ],
          ),
        ),
        for (var m = 0; m < 12; m++) monthCell(balance, year * 12 + m),
      ],
    );
  }

  final blocks = <pw.Widget>[];
  var n = 0;
  String? lastPurok;
  for (final h in households) {
    final purokHeading = purok == null && h.purok.trim().toUpperCase() != lastPurok;
    lastPurok = h.purok.trim().toUpperCase();
    // One block per household, never split across pages. A new purok's heading stays with its
    // first household.
    blocks.add(pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          if (purokHeading)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
              child: pw.Text(lastPurok.isEmpty ? 'NO PUROK' : 'PUROK  $lastPurok',
                  style: pw.TextStyle(font: fonts.title, fontSize: 10)),
            ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.grey600, width: 0.5),
                right: pw.BorderSide(color: PdfColors.grey600, width: 0.5),
              ),
            ),
            child: pw.Text(
              '${h.householdName}  ·  ${h.members.length} member${h.members.length == 1 ? '' : 's'}',
              style: bold,
            ),
          ),
          pw.Table(
            border: border,
            columnWidths: columnWidths,
            children: [
              for (final member in h.members) memberRow(member, ++n),
            ],
          ),
        ],
      ),
    ));
  }

  final doc = pw.Document(theme: fonts.theme);
  doc.addPage(
    pw.MultiPage(
      pageFormat: format.portrait,
      margin: const pw.EdgeInsets.all(28),
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text('Dues Collection Sheet  •  $year', style: pw.TextStyle(font: fonts.title, fontSize: 14)),
          pw.SizedBox(height: 2),
          pw.Text('$barangayLabel  •  ${purok == null ? 'All puroks' : 'Purok $purok'}',
              style: pw.TextStyle(font: fonts.title, fontSize: 10)),
          pw.SizedBox(height: 2),
          pw.Text(
            '${households.length} households, $members members  •  Printed $printedOn',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 2),
          pw.Text('PAID = already paid  •  X = not billed  •  blank = to collect',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
          pw.SizedBox(height: 6),
          columnHeader,
        ],
      ),
      footer: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ),
      build: (_) => blocks,
    ),
  );
  return doc.save();
}

/// Full-screen preview of a sheet from [buildDuesSheet], one whole page in view at a time like
/// paper, with a choice of paper size, print, save and share.
class DuesSheetPreview extends StatefulWidget {
  final String title;

  /// Builds the sheet on the chosen paper size.
  final Future<Uint8List> Function(PdfPageFormat format) build;

  const DuesSheetPreview({super.key, required this.title, required this.build});

  @override
  State<DuesSheetPreview> createState() => _DuesSheetPreviewState();
}

class _DuesSheetPreviewState extends State<DuesSheetPreview> {
  /// Room the preview takes besides the page: its action bar, and the margin around each page.
  static const _actionBarHeight = 56.0;
  static const _pageMargin = 16.0;

  PdfPageFormat _format = longBond;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: LayoutBuilder(builder: (context, constraints) {
        // Size each page to the height left over, so a whole page shows without scrolling.
        final pageHeight = constraints.maxHeight - _actionBarHeight - _pageMargin * 2;
        final pageWidth = pageHeight * _format.width / _format.height;
        return PdfPreview(
          build: widget.build,
          initialPageFormat: longBond,
          pageFormats: duesSheetFormats,
          onPageFormatChanged: (f) => setState(() => _format = f),
          canChangeOrientation: false,
          canDebug: false,
          maxPageWidth: pageWidth.clamp(200.0, constraints.maxWidth).toDouble(),
          previewPageMargin: const EdgeInsets.all(_pageMargin),
          actionBarTheme: const PdfActionBarTheme(height: _actionBarHeight),
          pdfFileName: '${widget.title.replaceAll(RegExp(r'[^A-Za-z0-9 -]'), '')}.pdf',
        );
      }),
    );
  }
}
