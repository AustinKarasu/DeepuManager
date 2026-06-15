import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stock register calculation contract', () {
    const openingQty = 10.0;
    const openingRate = 5.0;
    const receiptQty = 5.0;
    const receiptRate = 8.0;
    const issueQty = 3.0;
    const issueRate = 6.0;

    const openingAmount = openingQty * openingRate;
    const receiptAmount = receiptQty * receiptRate;
    const totalQty = openingQty + receiptQty;
    const totalAmount = openingAmount + receiptAmount;
    const closingQty = totalQty - issueQty;
    const closingAmount = totalAmount - (issueQty * issueRate);

    expect(openingAmount, 50);
    expect(receiptAmount, 40);
    expect(totalQty, 15);
    expect(totalAmount, 90);
    expect(closingQty, 12);
    expect(closingAmount, 72);
  });
}
