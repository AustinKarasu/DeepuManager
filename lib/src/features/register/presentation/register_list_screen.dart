import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/share/share_service.dart';
import '../../reports/data/export_service.dart';
import '../data/stock_register_repository.dart';
import '../domain/stock_register.dart';
import 'spreadsheet_editor.dart';

class RegisterListScreen extends ConsumerStatefulWidget {
  const RegisterListScreen({super.key});

  @override
  ConsumerState<RegisterListScreen> createState() => _RegisterListScreenState();
}

class _RegisterListScreenState extends ConsumerState<RegisterListScreen> {
  final _searchController = TextEditingController();
  final List<StockRegister> _items = [];
  Timer? _searchDebounce;
  String _search = '';
  bool _lowOnly = false;
  bool _sortByName = false;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = [..._items];
    if (_sortByName) visible.sort((a, b) => a.itemName.compareTo(b.itemName));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Registers'),
        actions: [
          IconButton(
            tooltip: 'Open sheet',
            onPressed: () => _openSheet(visible),
            icon: const Icon(Icons.grid_on_outlined),
          ),
          IconButton(
            tooltip: 'Share Excel',
            onPressed: visible.isEmpty ? null : () => _export(visible, share: true),
            icon: const Icon(Icons.ios_share_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'xlsx') _export(visible);
              if (value == 'refresh') _load();
              if (value == 'clear') _clearFilters();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'xlsx', child: Text('Save Excel Sheet')),
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              PopupMenuItem(value: 'clear', child: Text('Clear Filters')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/registers/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _search = value;
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 300), _load);
              },
              decoration: const InputDecoration(
                hintText: 'Search by date, item, quantity...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Low Stock'),
                  selected: _lowOnly,
                  onSelected: (v) {
                    setState(() => _lowOnly = v);
                    _load();
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Show all',
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_list_off),
                ),
                IconButton(
                  tooltip: 'Sort by name',
                  onPressed: () => setState(() => _sortByName = !_sortByName),
                  icon: const Icon(Icons.sort_by_alpha),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: _error != null
                ? _ErrorState(error: _error!, onRetry: _load)
                : visible.isEmpty && !_loading
                    ? _EmptyState(onAdd: () => context.go('/registers/new'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (_, index) {
                          final item = visible[index];
                          return Card(
                            child: ListTile(
                              title: Text(item.itemName, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                '${item.particulars}\nClosing: ${item.closingQty.toStringAsFixed(2)} | Value: ${item.closingAmount.toStringAsFixed(2)}',
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  final repo = ref.read(stockRegisterRepositoryProvider);
                                  if (value == 'edit') context.go('/registers/${item.id}');
                                  if (value == 'copy') await repo.duplicate(item.id);
                                  if (value == 'delete') await repo.delete(item.id);
                                  if (value == 'copy' || value == 'delete') await _load();
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'copy', child: Text('Duplicate')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                              onTap: () => context.go('/registers/${item.id}'),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: visible.length,
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await ref
          .read(stockRegisterRepositoryProvider)
          .list(RegisterQuery(search: _search, lowStockOnly: _lowOnly, limit: 100))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(rows);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _search = '';
      _lowOnly = false;
    });
    _load();
  }

  Future<void> _export(List<StockRegister> rows, {bool share = false}) async {
    try {
      final file = await ExportService().exportXlsx(rows);
      if (share) {
        await ShareService.instance.shareFile(file, text: 'Deepu Manager stock register sheet');
        return;
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excel Sheet Saved'),
          content: SelectableText(file.path),
          actions: [
            TextButton(
              onPressed: () => ShareService.instance.shareFile(file),
              child: const Text('Share'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await OpenFilex.open(file.path);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export Excel: $error')),
      );
    }
  }

  Future<void> _openSheet(List<StockRegister> rows) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Stock Register Sheet'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                tooltip: 'Share Excel',
                onPressed: rows.isEmpty ? null : () => _export(rows, share: true),
                icon: const Icon(Icons.ios_share_outlined),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: SpreadsheetEditor(
              rows: rows,
              onAdd: () {
                Navigator.pop(context);
                context.go('/registers/new');
              },
              onEdit: (row) {
                Navigator.pop(context);
                context.go('/registers/${row.id}');
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 42, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 10),
            const Text('Registers could not load'),
            const SizedBox(height: 6),
            Text(error.toString(), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 46),
            const SizedBox(height: 10),
            const Text('No registers found'),
            const SizedBox(height: 6),
            const Text('Add the first stock row or clear filters.', textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('New Entry')),
          ],
        ),
      ),
    );
  }
}
