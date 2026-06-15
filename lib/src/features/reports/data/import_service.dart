import 'dart:io';

import 'package:excel/excel.dart';

class ImportValidationResult {
  const ImportValidationResult({required this.rows, required this.errors});
  final List<Map<String, Object?>> rows;
  int get validRows => rows.length;
  final List<String> errors;
}

class ImportService {
  Future<ImportValidationResult> validateXlsx(File file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return const ImportValidationResult(rows: [], errors: ['Selected file is empty']);
    }
    final book = Excel.decodeBytes(bytes);
    if (book.tables.isEmpty) {
      return const ImportValidationResult(rows: [], errors: ['Workbook has no sheets']);
    }
    final sheet = book.tables.values.first;
    final errors = <String>[];
    final rows = <Map<String, Object?>>[];
    for (var i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.every((cell) => cell?.value == null)) continue;
      final item = row.length > 1 ? row[1]?.value.toString().trim() : '';
      if (item == null || item.isEmpty) {
        errors.add('Row ${i + 1}: item name is required');
        continue;
      }
      rows.add({
        'entry_date': row.isNotEmpty ? row[0]?.value.toString() : null,
        'item_name': item,
        'particulars': row.length > 2 ? row[2]?.value.toString() : item,
        'opening_qty': _number(row, 3),
        'opening_rate': _number(row, 4),
        'receipt_qty': _number(row, 5),
        'receipt_rate': _number(row, 6),
        'issue_qty': _number(row, 7),
        'issue_rate': _number(row, 8),
        'remarks': row.length > 9 ? row[9]?.value.toString() : '',
      });
    }
    return ImportValidationResult(rows: rows, errors: errors);
  }

  double _number(List<Data?> row, int index) {
    if (index >= row.length) return 0;
    final value = row[index]?.value;
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }
}
