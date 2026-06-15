import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../register/data/stock_register_repository.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registers = ref.watch(stockRegistersProvider(const RegisterQuery()));
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: registers.when(
        data: (items) {
          final value = items.fold<double>(0, (sum, e) => sum + e.closingAmount);
          final chart = items.take(6).map((e) => _Point(e.monthLabel, e.closingAmount)).toList();
          final total = items.length;
          final low = items.where((e) => e.isLowStock).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Panel(
                title: 'Inventory Value over time',
                trailing: '${value.toStringAsFixed(2)} total',
                child: SizedBox(
                  height: 240,
                  child: SfCartesianChart(
                    primaryXAxis: const CategoryAxis(),
                    series: <CartesianSeries<_Point, String>>[
                      ColumnSeries<_Point, String>(
                        dataSource: chart,
                        xValueMapper: (p, _) => p.label,
                        yValueMapper: (p, _) => p.value,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              _Panel(
                title: 'Category Distribution',
                child: SizedBox(
                  height: 220,
                  child: SfCircularChart(
                    series: <CircularSeries<_Point, String>>[
                      DoughnutSeries<_Point, String>(
                        dataSource: [
                          _Point('Healthy Stock', (total - low).toDouble()),
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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
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
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
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

class _Point {
  const _Point(this.label, this.value);
  final String label;
  final double value;
}
