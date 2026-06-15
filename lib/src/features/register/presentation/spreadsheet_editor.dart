import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../domain/stock_register.dart';

class SpreadsheetEditor extends StatelessWidget {
  const SpreadsheetEditor({
    required this.rows,
    required this.onAdd,
    required this.onEdit,
    super.key,
  });
  final List<StockRegister> rows;
  final VoidCallback onAdd;
  final ValueChanged<StockRegister> onEdit;

  @override
  Widget build(BuildContext context) {
    final source = _Source(rows);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Stock Register Sheet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Row'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: rows.isEmpty
              ? _EmptySheet(onAdd: onAdd)
              : SfDataGrid(
                  source: source,
                  onCellTap: (details) {
                    final rowIndex = details.rowColumnIndex.rowIndex - 1;
                    if (rowIndex >= 0 && rowIndex < rows.length) {
                      onEdit(rows[rowIndex]);
                    }
                  },
                  navigationMode: GridNavigationMode.cell,
                  selectionMode: SelectionMode.single,
                  columnWidthMode: ColumnWidthMode.auto,
                  frozenColumnsCount: 2,
                  columns: [
                    _column('date', 'Month & Date'),
                    _column('particulars', 'Particulars of Goods Received & Issued'),
                    _column('openingQty', 'Opening Qty'),
                    _column('openingRate', 'Opening Rate'),
                    _column('openingAmount', 'Opening Amount'),
                    _column('receiptQty', 'Receipt Qty'),
                    _column('receiptRate', 'Receipt Rate'),
                    _column('receiptAmount', 'Receipt Amount'),
                    _column('totalQty', 'Total Qty'),
                    _column('totalRate', 'Total Rate'),
                    _column('totalAmount', 'Total Amount'),
                    _column('issueQty', 'Issue Qty'),
                    _column('issueRate', 'Issue Rate'),
                    _column('issueAmount', 'Issue Amount'),
                    _column('closingQty', 'Closing Qty'),
                    _column('closingAmount', 'Closing Amount'),
                    _column('remarks', 'Remarks'),
                  ],
                ),
        ),
      ],
    );
  }

  GridColumn _column(String name, String label) {
    return GridColumn(
      columnName: name,
      label: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _Source extends DataGridSource {
  _Source(List<StockRegister> rows)
      : _rows = rows
            .map((e) => DataGridRow(cells: [
                  DataGridCell(columnName: 'date', value: '${e.monthLabel}\n${e.entryDate.day}'),
                  DataGridCell(columnName: 'particulars', value: e.particulars),
                  DataGridCell(columnName: 'openingQty', value: e.openingQty),
                  DataGridCell(columnName: 'openingRate', value: e.openingRate),
                  DataGridCell(columnName: 'openingAmount', value: e.openingAmount),
                  DataGridCell(columnName: 'receiptQty', value: e.receiptQty),
                  DataGridCell(columnName: 'receiptRate', value: e.receiptRate),
                  DataGridCell(columnName: 'receiptAmount', value: e.receiptAmount),
                  DataGridCell(columnName: 'totalQty', value: e.totalQty),
                  DataGridCell(columnName: 'totalRate', value: e.totalRate),
                  DataGridCell(columnName: 'totalAmount', value: e.totalAmount),
                  DataGridCell(columnName: 'issueQty', value: e.issueQty),
                  DataGridCell(columnName: 'issueRate', value: e.issueRate),
                  DataGridCell(columnName: 'issueAmount', value: e.issueAmount),
                  DataGridCell(columnName: 'closingQty', value: e.closingQty),
                  DataGridCell(columnName: 'closingAmount', value: e.closingAmount),
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

class _EmptySheet extends StatelessWidget {
  const _EmptySheet({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Row(
              children: [
                Expanded(child: Text('Month & Date')),
                Expanded(flex: 2, child: Text('Particulars')),
                Expanded(child: Text('Opening')),
                Expanded(child: Text('Receipt')),
                Expanded(child: Text('Total')),
                Expanded(child: Text('Issue')),
                Expanded(child: Text('Closing')),
                Expanded(child: Text('Remarks')),
              ],
            ),
          ),
          const Spacer(),
          const Icon(Icons.table_chart_outlined, size: 42, color: Colors.blueGrey),
          const SizedBox(height: 8),
          const Text('No stock rows yet'),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Create First Row'),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
