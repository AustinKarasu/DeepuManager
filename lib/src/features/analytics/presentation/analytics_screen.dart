import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../register/data/stock_register_repository.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registers = ref.watch(stockRegistersProvider(const RegisterQuery(limit: 300)));
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: registers.when(
        data: (items) {
          final value = items.fold<double>(0, (sum, e) => sum + e.closingAmount);
          final totalStock = items.fold<double>(0, (sum, e) => sum + e.closingQty);
          final received = items.fold<double>(0, (sum, e) => sum + e.receiptQty);
          final issued = items.fold<double>(0, (sum, e) => sum + e.issueQty);
          final low = items.where((e) => e.isLowStock).length;
          final chart = items
              .take(8)
              .map((e) => _Point(e.monthLabel, e.closingAmount))
              .toList()
              .reversed
              .toList();
          final topItems = [...items]..sort((a, b) => b.closingAmount.compareTo(a.closingAmount));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Metric(title: 'Inventory Value', value: value.toStringAsFixed(2), icon: Icons.currency_rupee),
                  _Metric(title: 'Total Stock', value: totalStock.toStringAsFixed(0), icon: Icons.inventory_2_outlined),
                  _Metric(title: 'Received', value: received.toStringAsFixed(0), icon: Icons.south_west),
                  _Metric(title: 'Issued', value: issued.toStringAsFixed(0), icon: Icons.north_east),
                ],
              ),
              const SizedBox(height: 16),
              _Panel(
                title: 'Inventory Value Trend',
                trailing: '${items.length} rows',
                child: SizedBox(
                  height: 250,
                  child: SfCartesianChart(
                    primaryXAxis: const CategoryAxis(),
                    primaryYAxis: const NumericAxis(),
                    series: <CartesianSeries<_Point, String>>[
                      ColumnSeries<_Point, String>(
                        dataSource: chart,
                        xValueMapper: (p, _) => p.label,
                        yValueMapper: (p, _) => p.value,
                        borderRadius: BorderRadius.circular(6),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              _Panel(
                title: 'Stock Health',
                trailing: '$low low stock',
                child: SizedBox(
                  height: 220,
                  child: SfCircularChart(
                    legend: const Legend(isVisible: true),
                    series: <CircularSeries<_Point, String>>[
                      DoughnutSeries<_Point, String>(
                        dataSource: [
                          _Point('Healthy', (items.length - low).toDouble()),
                          _Point('Low Stock', low.toDouble()),
                        ],
                        xValueMapper: (p, _) => p.label,
                        yValueMapper: (p, _) => p.value,
                        dataLabelSettings: const DataLabelSettings(isVisible: true),
                      ),
                    ],
                  ),
                ),
              ),
              _Panel(
                title: 'Highest Value Items',
                child: Column(
                  children: [
                    for (final item in topItems.take(5))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.itemName, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('Closing qty ${item.closingQty.toStringAsFixed(2)}'),
                        trailing: Text(item.closingAmount.toStringAsFixed(2)),
                      ),
                    if (topItems.isEmpty) const Text('Add stock rows to see item performance.'),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const _LoadingAnalytics(),
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
    return SizedBox(
      width: MediaQuery.of(context).size.width > 520 ? 240 : double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (trailing != null) Chip(label: Text(trailing!)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _LoadingAnalytics extends StatelessWidget {
  const _LoadingAnalytics();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < 4; i++)
          Card(
            child: SizedBox(
              height: i == 0 ? 72 : 180,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _Point {
  const _Point(this.label, this.value);
  final String label;
  final double value;
}
