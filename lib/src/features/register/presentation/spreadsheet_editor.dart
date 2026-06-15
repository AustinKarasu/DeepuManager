import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  static const _columns = <_SheetColumn>[
    _SheetColumn('Month & Date', 110),
    _SheetColumn('Particulars of Goods Received & Issued', 220),
    _SheetColumn('Opening Qty', 92),
    _SheetColumn('Opening Rate', 98),
    _SheetColumn('Opening Amount', 118),
    _SheetColumn('Receipt Qty', 92),
    _SheetColumn('Receipt Rate', 98),
    _SheetColumn('Receipt Amount', 118),
    _SheetColumn('Total Qty', 86),
    _SheetColumn('Total Rate', 92),
    _SheetColumn('Total Amount', 110),
    _SheetColumn('Issue Qty', 86),
    _SheetColumn('Issue Rate', 92),
    _SheetColumn('Issue Amount', 110),
    _SheetColumn('Closing Qty', 96),
    _SheetColumn('Closing Amount', 124),
    _SheetColumn('Remarks', 160),
  ];

  double get _sheetWidth => _columns.fold(0, (sum, column) => sum + column.width);

  @override
  Widget build(BuildContext context) {
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
              : DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: _sheetWidth,
                        child: Column(
                          children: [
                            const _HeaderRow(columns: _columns),
                            Expanded(
                              child: ListView.builder(
                                itemCount: rows.length,
                                itemBuilder: (context, index) {
                                  final row = rows[index];
                                  return _DataRow(
                                    columns: _columns,
                                    values: _values(row),
                                    onTap: () => onEdit(row),
                                    odd: index.isOdd,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  List<String> _values(StockRegister row) {
    return [
      '${DateFormat.MMM().format(row.entryDate)} ${row.entryDate.day}',
      row.particulars,
      _n(row.openingQty),
      _n(row.openingRate),
      _n(row.openingAmount),
      _n(row.receiptQty),
      _n(row.receiptRate),
      _n(row.receiptAmount),
      _n(row.totalQty),
      _n(row.totalRate),
      _n(row.totalAmount),
      _n(row.issueQty),
      _n(row.issueRate),
      _n(row.issueAmount),
      _n(row.closingQty),
      _n(row.closingAmount),
      row.remarks ?? '',
    ];
  }

  String _n(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.columns});

  final List<_SheetColumn> columns;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final column in columns)
          _Cell(
            text: column.title,
            width: column.width,
            header: true,
          ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.columns,
    required this.values,
    required this.onTap,
    required this.odd,
  });

  final List<_SheetColumn> columns;
  final List<String> values;
  final VoidCallback onTap;
  final bool odd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ColoredBox(
        color: odd
            ? Theme.of(context).colorScheme.surfaceContainerLow
            : Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            for (var i = 0; i < columns.length; i++)
              _Cell(
                text: values[i],
                width: columns[i].width,
              ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.text,
    required this.width,
    this.header = false,
  });

  final String text;
  final double width;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: header ? 54 : 44,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: header ? scheme.primaryContainer : null,
        border: Border(
          right: BorderSide(color: scheme.outlineVariant),
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: header ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: header ? scheme.onPrimaryContainer : scheme.onSurface,
          fontWeight: header ? FontWeight.w800 : FontWeight.w500,
          fontSize: header ? 11 : 12,
        ),
      ),
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
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Row(
              children: [
                Expanded(child: Text('Month & Date')),
                Expanded(flex: 2, child: Text('Particulars')),
                Expanded(child: Text('Opening')),
                Expanded(child: Text('Receipt')),
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

class _SheetColumn {
  const _SheetColumn(this.title, this.width);
  final String title;
  final double width;
}
