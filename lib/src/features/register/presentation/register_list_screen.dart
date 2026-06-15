import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/stock_register_repository.dart';

class RegisterListScreen extends ConsumerStatefulWidget {
  const RegisterListScreen({super.key});

  @override
  ConsumerState<RegisterListScreen> createState() => _RegisterListScreenState();
}

class _RegisterListScreenState extends ConsumerState<RegisterListScreen> {
  String _search = '';
  bool _lowOnly = false;
  bool _sortByName = false;

  @override
  Widget build(BuildContext context) {
    final query = RegisterQuery(search: _search, lowStockOnly: _lowOnly, limit: 100);
    final registers = ref.watch(stockRegistersProvider(query));
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Registers')),
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
              onChanged: (value) => setState(() => _search = value),
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
                  onSelected: (v) => setState(() => _lowOnly = v),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Show all',
                  onPressed: () => setState(() {
                    _search = '';
                    _lowOnly = false;
                  }),
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
          Expanded(
            child: registers.when(
              data: (items) {
                final visible = [...items];
                if (_sortByName) {
                  visible.sort((a, b) => a.itemName.compareTo(b.itemName));
                }
                return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (_, index) {
                  final item = visible[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.itemName),
                      subtitle: Text('${item.particulars}\nClosing: ${item.closingQty.toStringAsFixed(2)}'),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          final repo = ref.read(stockRegisterRepositoryProvider);
                          if (value == 'edit') context.go('/registers/${item.id}');
                          if (value == 'copy') await repo.duplicate(item.id);
                          if (value == 'delete') await repo.delete(item.id);
                          ref.invalidate(stockRegistersProvider);
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
              );
              },
              loading: () => ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _LoadingRow(),
                  _LoadingRow(),
                  _LoadingRow(),
                  _LoadingRow(),
                ],
              ),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
        title: Container(height: 14, color: Theme.of(context).colorScheme.surfaceContainerHighest),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(height: 12, color: Theme.of(context).colorScheme.surfaceContainerHighest),
        ),
      ),
    );
  }
}
