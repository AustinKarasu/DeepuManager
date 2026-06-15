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
    _SheetColumn('Month\n& Date', 74),
    _SheetColumn('Particulars of Goods\nReceived & Issued', 170),
    _SheetColumn('Qty', 56),
    _SheetColumn('Rate', 58),
    _SheetColumn('Amount', 72),
    _SheetColumn('Qty', 56),
    _SheetColumn('Rate', 58),
    _SheetColumn('Amount', 72),
    _SheetColumn('Qty', 56),
    _SheetColumn('Rate', 58),
    _SheetColumn('Amount', 72),
    _SheetColumn('Qty', 56),
    _SheetColumn('Rate', 58),
    _SheetColumn('Amount', 72),
    _SheetColumn('Qty', 56),
    _SheetColumn('Amount', 76),
    _SheetColumn('Remarks', 130),
  ];

  double get _sheetWidth => _columns.fold(0, (sum, column) => sum + column.width);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Traditional Stock Register Sheet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton.filled(
              tooltip: 'Add row',
              onPressed: onAdd,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Swipe sideways to view every column. Tap any row to edit it.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: rows.isEmpty
              ? _EmptySheet(onAdd: onAdd)
              : DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: _sheetWidth,
                          child: Column(
                            children: [
                              const _ArticleHeader(),
                              const _GroupHeader(columns: _columns),
                              const _HeaderRow(columns: _columns),
                              Expanded(
                                child: ListView.builder(
                                  itemExtent: 44,
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

class _ArticleHeader extends StatelessWidget {
  const _ArticleHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 38,
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: Text(
        'NAME OF ARTICLE',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.columns});

  final List<_SheetColumn> columns;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _GroupCell('Month & Date', columns[0].width, scheme),
        _GroupCell('Particulars of Goods Received & Issued', columns[1].width, scheme),
        _GroupCell('Opening Balance (A)', columns[2].width + columns[3].width + columns[4].width, scheme),
        _GroupCell('Receipt (B)', columns[5].width + columns[6].width + columns[7].width, scheme),
        _GroupCell('Total (A+B)', columns[8].width + columns[9].width + columns[10].width, scheme),
        _GroupCell('Issue', columns[11].width + columns[12].width + columns[13].width, scheme),
        _GroupCell('Closing Balance', columns[14].width + columns[15].width, scheme),
        _GroupCell('Remarks', columns[16].width, scheme),
      ],
    );
  }
}

class _GroupCell extends StatelessWidget {
  const _GroupCell(this.text, this.width, this.scheme);
  final String text;
  final double width;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        border: Border(
          right: BorderSide(color: scheme.outlineVariant),
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
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
    return Material(
      color: odd ? Theme.of(context).colorScheme.surfaceContainerLowest : Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
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
      height: header ? 42 : 44,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: header ? scheme.surfaceContainerHigh : null,
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
        textAlign: header ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          color: scheme.onSurface,
          fontWeight: header ? FontWeight.w800 : FontWeight.w500,
          fontSize: header ? 10 : 11.5,
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
          const _ArticleHeader(),
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
