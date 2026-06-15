import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/stock_register_repository.dart';

class RegisterEditorScreen extends ConsumerStatefulWidget {
  const RegisterEditorScreen({this.registerId, super.key});
  final String? registerId;

  @override
  ConsumerState<RegisterEditorScreen> createState() => _RegisterEditorScreenState();
}

class _RegisterEditorScreenState extends ConsumerState<RegisterEditorScreen> {
  final _item = TextEditingController();
  final _particulars = TextEditingController();
  final _openingQty = TextEditingController(text: '0');
  final _openingRate = TextEditingController(text: '0');
  final _receiptQty = TextEditingController(text: '0');
  final _receiptRate = TextEditingController(text: '0');
  final _issueQty = TextEditingController(text: '0');
  final _issueRate = TextEditingController(text: '0');
  final _threshold = TextEditingController(text: '0');
  final _remarks = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    if (!_loaded && widget.registerId != null) _load();
    return Scaffold(
      appBar: AppBar(title: Text(widget.registerId == null ? 'Add Stock Row' : 'Edit Stock Row')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Month & Date'),
            subtitle: Text(_date.toLocal().toString().split(' ').first),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: _pickDate,
            ),
          ),
          _field(_item, 'Name of Article / Item', helper: 'Example: Cement, Steel, Safety Helmet'),
          _field(
            _particulars,
            'What happened in this row?',
            helper: 'Write goods received, goods issued, supplier, bill number, or purpose.',
          ),
          const SizedBox(height: 12),
          _section('Opening Balance', _openingQty, _openingRate),
          _section('Receipt', _receiptQty, _receiptRate),
          _section('Issue', _issueQty, _issueRate),
          _field(_threshold, 'Low Stock Alert Quantity', helper: 'App marks this item low when closing quantity is at or below this number.', number: true),
          _field(_remarks, 'Remarks', helper: 'Optional note for checking or approval.'),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Stock Row'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? helper,
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : null,
        decoration: InputDecoration(labelText: label, helperText: helper),
      ),
    );
  }

  Widget _section(String title, TextEditingController qty, TextEditingController rate) {
    final amount = _num(qty) * _num(rate);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_plainTitle(title), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _field(qty, 'Quantity', helper: 'How many units?', number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(rate, 'Rate', helper: 'Price per unit', number: true)),
              ],
            ),
            Text('Amount: ${amount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  String _plainTitle(String title) {
    if (title == 'Opening Balance') return 'Opening Balance - stock before this entry';
    if (title == 'Receipt') return 'Receipt - stock received';
    if (title == 'Issue') return 'Issue - stock given out';
    return title;
  }

  Future<void> _load() async {
    _loaded = true;
    final item = await ref.read(stockRegisterRepositoryProvider).byId(widget.registerId!);
    if (!mounted || item == null) return;
    setState(() {
      _date = item.entryDate;
      _item.text = item.itemName;
      _particulars.text = item.particulars;
      _openingQty.text = item.openingQty.toString();
      _openingRate.text = item.openingRate.toString();
      _receiptQty.text = item.receiptQty.toString();
      _receiptRate.text = item.receiptRate.toString();
      _issueQty.text = item.issueQty.toString();
      _issueRate.text = item.issueRate.toString();
      _threshold.text = item.lowStockThreshold.toString();
      _remarks.text = item.remarks ?? '';
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _save() async {
    await ref.read(stockRegisterRepositoryProvider).save(
          id: widget.registerId,
          entryDate: _date,
          itemName: _item.text,
          particulars: _particulars.text,
          openingQty: _num(_openingQty),
          openingRate: _num(_openingRate),
          receiptQty: _num(_receiptQty),
          receiptRate: _num(_receiptRate),
          issueQty: _num(_issueQty),
          issueRate: _num(_issueRate),
          lowStockThreshold: _num(_threshold),
          remarks: _remarks.text,
        );
    ref.invalidate(stockRegistersProvider);
    if (mounted) context.go('/registers');
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
}
