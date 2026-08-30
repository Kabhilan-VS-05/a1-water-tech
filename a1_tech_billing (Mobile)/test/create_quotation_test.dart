import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:a1_tech_billing/screens/quotation/quotation_screen.dart';

void main() {
  testWidgets('CreateQuotationScreen renders correctly with all sections', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: CreateQuotationScreen(),
    ));

    // Wait for async operations to complete (like loading catalog)
    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.text('Make Quotation'), findsOneWidget);

    // Verify sections (ExpansionTiles) exist
    expect(find.text('TO (CUSTOMER)'), findsOneWidget);
    expect(find.text('PRODUCTS'), findsOneWidget);
    expect(find.text('OTHER CHARGE'), findsOneWidget);
    expect(find.text('TERMS & CONDITIONS'), findsOneWidget);

    // Verify Round Off checkbox exists
    expect(find.text('ROUND OFF AMOUNT'), findsOneWidget);

    // Verify Generate button exists
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Amount Due'), findsOneWidget);
  });
}
