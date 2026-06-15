import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../domain/stock_register.dart';

class SpreadsheetEditor extends StatelessWidget {
  const SpreadsheetEditor({required this.rows, super.key});
  final List<StockRegister> rows;

  @override
  Widget build(BuildContext context) {
    return SfDataGrid(
      source: _Source(rows),
      allowEditing: true,
      navigationMode: GridNavigationMode.cell,
      selectionMode: SelectionMode.single,
      columnWidthMode: ColumnWidthMode.auto,
      columns: [
        GridColumn(columnName: 'date', label: const Center(child: Text('Month & Date'))),
        GridColumn(columnName: 'item', label: const Center(child: Text('Item'))),
        GridColumn(columnName: 'particulars', label: const Center(child: Text('Particulars'))),
        GridColumn(columnName: 'opening', label: const Center(child: Text('Opening'))),
        GridColumn(columnName: 'receipt', label: const Center(child: Text('Receipt'))),
        GridColumn(columnName: 'issue', label: const Center(child: Text('Issue'))),
        GridColumn(columnName: 'closing', label: const Center(child: Text('Closing'))),
        GridColumn(columnName: 'remarks', label: const Center(child: Text('Remarks'))),
      ],
    );
  }
}

class _Source extends DataGridSource {
  _Source(List<StockRegister> rows)
      : _rows = rows
            .map((e) => DataGridRow(cells: [
                  DataGridCell(columnName: 'date', value: e.monthLabel),
                  DataGridCell(columnName: 'item', value: e.itemName),
                  DataGridCell(columnName: 'particulars', value: e.particulars),
                  DataGridCell(columnName: 'opening', value: e.openingQty),
                  DataGridCell(columnName: 'receipt', value: e.receiptQty),
                  DataGridCell(columnName: 'issue', value: e.issueQty),
                  DataGridCell(columnName: 'closing', value: e.closingQty),
                  DataGridCell(columnName: 'remarks', value: e.remarks ?? ''),
                ]))
            .toList();

  final List<DataGridRow> _rows;

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text(cell.value.toString(), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
    );
  }
}
