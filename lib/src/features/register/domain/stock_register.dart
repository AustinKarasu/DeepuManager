class StockRegister {
  const StockRegister({
    required this.id,
    required this.userId,
    required this.entryDate,
    required this.monthLabel,
    required this.itemName,
    required this.particulars,
    required this.openingQty,
    required this.openingRate,
    required this.openingAmount,
    required this.receiptQty,
    required this.receiptRate,
    required this.receiptAmount,
    required this.totalQty,
    required this.totalRate,
    required this.totalAmount,
    required this.issueQty,
    required this.issueRate,
    required this.issueAmount,
    required this.closingQty,
    required this.closingAmount,
    required this.lowStockThreshold,
    required this.remarks,
  });

  final String id;
  final String userId;
  final DateTime entryDate;
  final String monthLabel;
  final String itemName;
  final String particulars;
  final double openingQty;
  final double openingRate;
  final double openingAmount;
  final double receiptQty;
  final double receiptRate;
  final double receiptAmount;
  final double totalQty;
  final double totalRate;
  final double totalAmount;
  final double issueQty;
  final double issueRate;
  final double issueAmount;
  final double closingQty;
  final double closingAmount;
  final double lowStockThreshold;
  final String? remarks;

  bool get isLowStock => closingQty <= lowStockThreshold;

  factory StockRegister.fromMap(Map<String, Object?> map) => StockRegister(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        entryDate: DateTime.parse(map['entry_date'] as String),
        monthLabel: map['month_label'] as String,
        itemName: map['item_name'] as String,
        particulars: map['particulars'] as String,
        openingQty: (map['opening_qty'] as num).toDouble(),
        openingRate: (map['opening_rate'] as num).toDouble(),
        openingAmount: (map['opening_amount'] as num).toDouble(),
        receiptQty: (map['receipt_qty'] as num).toDouble(),
        receiptRate: (map['receipt_rate'] as num).toDouble(),
        receiptAmount: (map['receipt_amount'] as num).toDouble(),
        totalQty: (map['total_qty'] as num).toDouble(),
        totalRate: (map['total_rate'] as num).toDouble(),
        totalAmount: (map['total_amount'] as num).toDouble(),
        issueQty: (map['issue_qty'] as num).toDouble(),
        issueRate: (map['issue_rate'] as num).toDouble(),
        issueAmount: (map['issue_amount'] as num).toDouble(),
        closingQty: (map['closing_qty'] as num).toDouble(),
        closingAmount: (map['closing_amount'] as num).toDouble(),
        lowStockThreshold: (map['low_stock_threshold'] as num).toDouble(),
        remarks: map['remarks'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'entry_date': entryDate.toIso8601String(),
        'month_label': monthLabel,
        'item_name': itemName,
        'particulars': particulars,
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
        'remarks': remarks,
      };
}
