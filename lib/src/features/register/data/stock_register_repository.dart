import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../domain/stock_register.dart';

final stockRegisterRepositoryProvider = Provider((ref) {
  return StockRegisterRepository(ref.read(apiClientProvider));
});

final stockRegistersProvider = FutureProvider.autoDispose
    .family<List<StockRegister>, RegisterQuery>((ref, query) {
  return ref.read(stockRegisterRepositoryProvider).list(query);
});

class RegisterQuery {
  const RegisterQuery({
    this.search = '',
    this.from,
    this.to,
    this.lowStockOnly = false,
    this.limit = 50,
    this.offset = 0,
  });

  final String search;
  final DateTime? from;
  final DateTime? to;
  final bool lowStockOnly;
  final int limit;
  final int offset;

  Map<String, Object?> toQuery() => {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (from != null) 'from': from!.toIso8601String(),
        if (to != null) 'to': to!.toIso8601String(),
        if (lowStockOnly) 'lowStockOnly': 'true',
        'limit': limit,
        'offset': offset,
      };
}

class StockRegisterRepository {
  StockRegisterRepository(this._api);

  final ApiClient _api;
  final _uuid = const Uuid();

  Future<List<StockRegister>> list(RegisterQuery query) async {
    final response = await _api.get<List<dynamic>>(
      '/stock-registers',
      query: query.toQuery(),
    );
    final rows = response.data ?? [];
    return rows
        .cast<Map<String, dynamic>>()
        .map(StockRegister.fromApi)
        .toList();
  }

  Future<StockRegister?> byId(String id) async {
    final response = await _api.get<Map<String, dynamic>>('/stock-registers/$id');
    final data = response.data;
    return data == null ? null : StockRegister.fromApi(data);
  }

  Future<void> save({
    String? id,
    required DateTime entryDate,
    required String itemName,
    required String particulars,
    required double openingQty,
    required double openingRate,
    required double receiptQty,
    required double receiptRate,
    required double issueQty,
    required double issueRate,
    required double lowStockThreshold,
    String? remarks,
  }) async {
    final openingAmount = openingQty * openingRate;
    final receiptAmount = receiptQty * receiptRate;
    final totalQty = openingQty + receiptQty;
    final totalAmount = openingAmount + receiptAmount;
    final totalRate = totalQty == 0 ? 0 : totalAmount / totalQty;
    final issueAmount = issueQty * issueRate;
    final closingQty = totalQty - issueQty;
    final closingAmount = totalAmount - issueAmount;
    final payload = {
      'id': id ?? _uuid.v4(),
      'entryDate': entryDate.toIso8601String(),
      'monthLabel': DateFormat('MMM yyyy').format(entryDate),
      'itemName': itemName.trim(),
      'particulars': particulars.trim(),
      'openingQty': openingQty,
      'openingRate': openingRate,
      'openingAmount': openingAmount,
      'receiptQty': receiptQty,
      'receiptRate': receiptRate,
      'receiptAmount': receiptAmount,
      'totalQty': totalQty,
      'totalRate': totalRate,
      'totalAmount': totalAmount,
      'issueQty': issueQty,
      'issueRate': issueRate,
      'issueAmount': issueAmount,
      'closingQty': closingQty,
      'closingAmount': closingAmount,
      'lowStockThreshold': lowStockThreshold,
      'remarks': remarks?.trim(),
    };
    if (id == null) {
      await _api.post('/stock-registers', payload);
    } else {
      await _api.put('/stock-registers/$id', payload);
    }
  }

  Future<void> duplicate(String id) async {
    await _api.post('/stock-registers/$id/duplicate', {});
  }

  Future<void> delete(String id) async {
    await _api.delete('/stock-registers/$id');
  }
}
