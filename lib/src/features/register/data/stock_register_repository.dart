import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/stock_register.dart';

final stockRegisterRepositoryProvider = Provider((ref) {
  return StockRegisterRepository(ref.read(authRepositoryProvider));
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
}

class StockRegisterRepository {
  StockRegisterRepository(this._authRepository);

  final AuthRepository _authRepository;
  final _uuid = const Uuid();

  Future<List<StockRegister>> list(RegisterQuery query) async {
    final user = await _authRepository.currentUser();
    if (user == null) return [];
    final where = <String>['user_id = ?', 'is_deleted = 0'];
    final args = <Object?>[user.id];
    if (query.search.trim().isNotEmpty) {
      where.add('(item_name LIKE ? OR particulars LIKE ? OR remarks LIKE ?)');
      final term = '%${query.search.trim()}%';
      args.addAll([term, term, term]);
    }
    if (query.from != null) {
      where.add('entry_date >= ?');
      args.add(query.from!.toIso8601String());
    }
    if (query.to != null) {
      where.add('entry_date <= ?');
      args.add(query.to!.toIso8601String());
    }
    if (query.lowStockOnly) {
      where.add('closing_qty <= low_stock_threshold');
    }
    final rows = await AppDatabase.instance.db.query(
      'stock_registers',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'entry_date DESC, updated_at DESC',
      limit: query.limit,
      offset: query.offset,
    );
    return rows.map(StockRegister.fromMap).toList();
  }

  Future<StockRegister?> byId(String id) async {
    final rows = await AppDatabase.instance.db.query(
      'stock_registers',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : StockRegister.fromMap(rows.first);
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
    final user = await _authRepository.currentUser();
    if (user == null) throw StateError('User session expired');
    final now = DateTime.now().toIso8601String();
    final openingAmount = openingQty * openingRate;
    final receiptAmount = receiptQty * receiptRate;
    final totalQty = openingQty + receiptQty;
    final totalAmount = openingAmount + receiptAmount;
    final totalRate = totalQty == 0 ? 0 : totalAmount / totalQty;
    final issueAmount = issueQty * issueRate;
    final closingQty = totalQty - issueQty;
    final closingAmount = totalAmount - issueAmount;
    final row = {
      'id': id ?? _uuid.v4(),
      'user_id': user.id,
      'entry_date': entryDate.toIso8601String(),
      'month_label': DateFormat('MMM yyyy').format(entryDate),
      'item_name': itemName.trim(),
      'particulars': particulars.trim(),
      'opening_qty': openingQty,
      'opening_rate': openingRate,
      'opening_amount': openingAmount,
      'receipt_qty': receiptQty,
      'receipt_rate': receiptRate,
      'receipt_amount': receiptAmount,
      'total_qty': totalQty,
      'total_rate': totalRate,
      'total_amount': totalAmount,
      'issue_qty': issueQty,
      'issue_rate': issueRate,
      'issue_amount': issueAmount,
      'closing_qty': closingQty,
      'closing_amount': closingAmount,
      'low_stock_threshold': lowStockThreshold,
      'remarks': remarks?.trim(),
      'is_deleted': 0,
      'created_at': now,
      'updated_at': now,
    };
    await AppDatabase.instance.db.insert(
      'stock_registers',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _audit(user.id, id == null ? 'create' : 'update', row['id'] as String);
  }

  Future<void> duplicate(String id) async {
    final current = await byId(id);
    if (current == null) return;
    await save(
      entryDate: DateTime.now(),
      itemName: '${current.itemName} Copy',
      particulars: current.particulars,
      openingQty: current.openingQty,
      openingRate: current.openingRate,
      receiptQty: current.receiptQty,
      receiptRate: current.receiptRate,
      issueQty: current.issueQty,
      issueRate: current.issueRate,
      lowStockThreshold: current.lowStockThreshold,
      remarks: current.remarks,
    );
  }

  Future<void> delete(String id) async {
    final user = await _authRepository.currentUser();
    await AppDatabase.instance.db.update(
      'stock_registers',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _audit(user?.id, 'delete', id);
  }

  Future<void> _audit(String? userId, String action, String entityId) async {
    await AppDatabase.instance.db.insert('audit_logs', {
      'id': _uuid.v4(),
      'user_id': userId,
      'action': action,
      'entity': 'stock_registers',
      'entity_id': entityId,
      'metadata': '{}',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
