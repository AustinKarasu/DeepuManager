import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/update/update_service.dart';
import '../../register/data/stock_register_repository.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _search = '';
  bool _lowOnly = false;
  bool _checkedUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  @override
  Widget build(BuildContext context) {
    final registers = ref.watch(stockRegistersProvider(RegisterQuery(search: _search, lowStockOnly: _lowOnly, limit: 30)));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deepu Manager'),
        actions: [
          IconButton(
            tooltip: 'Clear search',
            onPressed: () => setState(() {
              _search = '';
              _lowOnly = false;
            }),
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reports') context.go('/reports');
              if (value == 'settings') context.go('/profile');
              if (value == 'about') context.go('/about');
              if (value == 'update') _checkUpdate(force: true);
              if (value == 'low') setState(() => _lowOnly = true);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reports', child: Text('Reports')),
              PopupMenuItem(value: 'settings', child: Text('Profile Settings')),
              PopupMenuItem(value: 'update', child: Text('Check for Updates')),
              PopupMenuItem(value: 'about', child: Text('About')),
              PopupMenuItem(value: 'low', child: Text('Show Low Stock')),
            ],
          ),
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
                onChanged: (value) => setState(() => _search = value),
                decoration: InputDecoration(
                  hintText: 'Search registers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All Stock'),
                    selected: !_lowOnly,
                    onSelected: (_) => setState(() => _lowOnly = false),
                  ),
                  FilterChip(
                    label: const Text('Low Stock'),
                    selected: _lowOnly,
                    onSelected: (_) => setState(() => _lowOnly = true),
                  ),
                  FilterChip(
                    label: const Text('High Value'),
                    selected: false,
                    onSelected: (_) => context.go('/reports'),
                  ),
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
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < 4; i)
              const Card(child: SizedBox(height: 76, child: Center(child: CircularProgressIndicator()))),
          ],
        ),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Future<void> _checkUpdate({bool force = false}) async {
    if (_checkedUpdate && !force) return;
    _checkedUpdate = true;
    try {
      final update = await UpdateService().check();
      if (!mounted) return;
      if (update == null) {
        if (force) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are using the latest version.')),
          );
        }
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Update ${update.version} available'),
          content: Text(update.notes),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                messenger.showSnackBar(const SnackBar(content: Text('Downloading update...')));
                final file = await UpdateService().download(update);
                await UpdateService().openInstaller(file);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (force && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not check for updates right now.')),
        );
      }
    }
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
