import 'package:flutter_test/flutter_test.dart';

import 'package:a1_tech_billing/main.dart';

void main() {
  testWidgets('Billing app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const A1BillingApp());
    await tester.pumpAndSettle();

    expect(find.text('A1 Water Tech'), findsOneWidget);
    expect(find.text('Admin Billing System'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
