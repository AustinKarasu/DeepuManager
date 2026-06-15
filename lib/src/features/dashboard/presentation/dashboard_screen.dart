import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/update/update_service.dart';
import '../../register/data/stock_register_repository.dart';
import '../../register/domain/stock_register.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _search = '';
  bool _lowOnly = false;
  bool _checkedUpdate = false;
  List<StockRegister> _items = const [];
  bool _loading = true;
  Object? _error;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRegisters();
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted) _checkUpdate();
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final totalStock = items.fold<double>(0, (sum, e) => sum + e.closingQty);
    final value = items.fold<double>(0, (sum, e) => sum + e.closingAmount);
    final low = items.where((e) => e.isLowStock).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deepu Manager'),
        actions: [
          IconButton(
            tooltip: 'Clear search',
            onPressed: () {
              setState(() {
                _search = '';
                _lowOnly = false;
              });
              _loadRegisters();
            },
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reports') context.go('/reports');
              if (value == 'settings') context.go('/profile');
              if (value == 'about') context.go('/about');
              if (value == 'update') _checkUpdate(force: true);
              if (value == 'low') {
                setState(() => _lowOnly = true);
                _loadRegisters();
              }
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) {
              _search = value;
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 300), _loadRegisters);
            },
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
                onSelected: (_) {
                  setState(() => _lowOnly = false);
                  _loadRegisters();
                },
              ),
              FilterChip(
                label: const Text('Low Stock'),
                selected: _lowOnly,
                onSelected: (_) {
                  setState(() => _lowOnly = true);
                  _loadRegisters();
                },
              ),
              FilterChip(
                label: const Text('High Value'),
                selected: false,
                onSelected: (_) => context.go('/reports'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          if (_loading) const SizedBox(height: 12),
          if (_error != null)
            Card(
              child: ListTile(
                leading: Icon(Icons.cloud_off_outlined, color: Theme.of(context).colorScheme.error),
                title: const Text('Could not load stock right now'),
                subtitle: Text(_error.toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: 'Try again',
                  onPressed: _loadRegisters,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
          _Metric(title: 'Total Stock', value: totalStock.toStringAsFixed(0), icon: Icons.inventory_2_outlined),
          _Metric(title: 'Total Items', value: items.length.toString(), icon: Icons.category_outlined),
          _Metric(title: 'Inventory Value', value: value.toStringAsFixed(2), icon: Icons.currency_rupee),
          _Metric(title: 'Low Stock Alerts', value: low.toString(), icon: Icons.warning_amber_outlined),
          const SizedBox(height: 16),
          Text('Recent Activities', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (!_loading && items.isEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('No stock rows yet'),
                subtitle: const Text('Tap + to add your first stock entry.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/registers/new'),
              ),
            ),
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
      ),
    );
  }

  Future<void> _loadRegisters() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(stockRegisterRepositoryProvider);
      final result = await repo
          .list(RegisterQuery(search: _search, lowStockOnly: _lowOnly, limit: 30))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _items = result;
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
