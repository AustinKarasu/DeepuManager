import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stock register calculation contract', () {
    const openingQty = 10.0;
    const openingRate = 5.0;
    const receiptQty = 5.0;
    const receiptRate = 8.0;
    const issueQty = 3.0;
    const issueRate = 6.0;

    final openingAmount = openingQty * openingRate;
    final receiptAmount = receiptQty * receiptRate;
    final totalQty = openingQty + receiptQty;
    final totalAmount = openingAmount + receiptAmount;
    final closingQty = totalQty - issueQty;
    final closingAmount = totalAmount - (issueQty * issueRate);

    expect(openingAmount, 50);
    expect(receiptAmount, 40);
    expect(totalQty, 15);
    expect(totalAmount, 90);
    expect(closingQty, 12);
    expect(closingAmount, 72);
  });
}
