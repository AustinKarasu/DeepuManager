import 'dart:io';
import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../../register/domain/stock_register.dart';

class ExportService {
  Future<File> exportXlsx(List<StockRegister> rows) async {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Stock Register';
    final title = sheet.getRangeByName('A1:S1');
    title.merge();
    title.setText('Deepu Manager Stock Register');
    title.cellStyle.bold = true;
    title.cellStyle.fontSize = 18;
    title.cellStyle.hAlign = HAlignType.center;
    sheet.getRangeByName('A2:S2').merge();
    sheet.getRangeByName('A2').setText(
      'Generated: ${DateFormat.yMMMd().add_jm().format(DateTime.now())}',
    );

    final headers = [
      'Month & Date',
      'Particulars',
      'Opening Qty',
      'Opening Rate',
      'Opening Amount',
      'Receipt Qty',
      'Receipt Rate',
      'Receipt Amount',
      'Total Qty',
      'Total Rate',
      'Total Amount',
      'Issue Qty',
      'Issue Rate',
      'Issue Amount',
      'Closing Qty',
      'Closing Amount',
      'Remarks',
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(4, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#EAF1FF';
      cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
    }
    for (var r = 0; r < rows.length; r++) {
      final item = rows[r];
      final values = [
        DateFormat('MMM dd, yyyy').format(item.entryDate),
        item.particulars,
        item.openingQty,
        item.openingRate,
        item.openingAmount,
        item.receiptQty,
        item.receiptRate,
        item.receiptAmount,
        item.totalQty,
        item.totalRate,
        item.totalAmount,
        item.issueQty,
        item.issueRate,
        item.issueAmount,
        item.closingQty,
        item.closingAmount,
        item.remarks ?? '',
      ];
      for (var c = 0; c < values.length; c++) {
        final cell = sheet.getRangeByIndex(r + 5, c + 1);
        final value = values[c];
        if (value is num) {
          cell.setNumber(value.toDouble());
        } else {
          cell.setText(value.toString());
        }
        cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
      }
    }
    final signatureRow = rows.length + 8;
    sheet.getRangeByIndex(signatureRow, 1).setText('Prepared By');
    sheet.getRangeByIndex(signatureRow, 8).setText('Checked By');
    sheet.getRangeByIndex(signatureRow, 14).setText('Authorized Signature');
    for (var i = 1; i <= headers.length; i++) {
      sheet.autoFitColumn(i);
    }
    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return _write('Deepu_Manager_Stock_Register.xlsx', bytes);
  }

  Future<File> exportPdf(List<StockRegister> rows) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final grid = PdfGrid();
    grid.columns.add(count: 6);
    grid.headers.add(1);
    grid.headers[0].cells[0].value = 'Date';
    grid.headers[0].cells[1].value = 'Item';
    grid.headers[0].cells[2].value = 'Receipt';
    grid.headers[0].cells[3].value = 'Issue';
    grid.headers[0].cells[4].value = 'Closing';
    grid.headers[0].cells[5].value = 'Remarks';
    for (final row in rows) {
      final pdfRow = grid.rows.add();
      pdfRow.cells[0].value = DateFormat.yMd().format(row.entryDate);
      pdfRow.cells[1].value = row.itemName;
      pdfRow.cells[2].value = row.receiptQty.toStringAsFixed(2);
      pdfRow.cells[3].value = row.issueQty.toStringAsFixed(2);
      pdfRow.cells[4].value = row.closingQty.toStringAsFixed(2);
      pdfRow.cells[5].value = row.remarks ?? '';
    }
    page.graphics.drawString(
      'Deepu Manager Inventory Report',
      PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
      bounds: const Rect.fromLTWH(0, 0, 500, 30),
    );
    page.graphics.drawString(
      'CONFIDENTIAL',
      PdfStandardFont(PdfFontFamily.helvetica, 44),
      brush: PdfSolidBrush(PdfColor(230, 230, 230)),
      bounds: const Rect.fromLTWH(70, 250, 430, 80),
    );
    grid.draw(page: page, bounds: const Rect.fromLTWH(0, 50, 0, 0));
    final bytes = document.saveSync();
    document.dispose();
    return _write('Deepu_Manager_Report.pdf', bytes);
  }

  Future<File> _write(String name, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    return file.writeAsBytes(bytes, flush: true);
  }
}
