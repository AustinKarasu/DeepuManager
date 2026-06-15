import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../register/data/stock_register_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registers = ref.watch(stockRegistersProvider(const RegisterQuery()));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deepu Manager'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/registers/new'),
        child: const Icon(Icons.add),
      ),
      body: registers.when(
        data: (items) {
          final totalStock = items.fold<double>(0, (sum, e) => sum + e.closingQty);
          final value = items.fold<double>(0, (sum, e) => sum + e.closingAmount);
          final low = items.where((e) => e.isLowStock).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search registers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                ),
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 8,
                children: [
                  FilterChip(label: Text('All Stock'), selected: true, onSelected: null),
                  FilterChip(label: Text('Low Stock'), selected: false, onSelected: null),
                  FilterChip(label: Text('High Value'), selected: false, onSelected: null),
                ],
              ),
              const SizedBox(height: 18),
              _Metric(title: 'Total Stock', value: totalStock.toStringAsFixed(0), icon: Icons.inventory_2_outlined),
              _Metric(title: 'Total Items', value: items.length.toString(), icon: Icons.category_outlined),
              _Metric(title: 'Inventory Value', value: value.toStringAsFixed(2), icon: Icons.currency_rupee),
              _Metric(title: 'Low Stock Alerts', value: low.toString(), icon: Icons.warning_amber_outlined),
              const SizedBox(height: 16),
              Text('Recent Activities', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final item in items.take(8))
                Card(
                  child: ListTile(
                    title: Text(item.itemName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(item.particulars, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/registers/${item.id}'),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
    );
  }
}
