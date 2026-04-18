import 'package:flutter_test/flutter_test.dart';

import 'package:a1_tech_billing/main.dart';

void main() {
  testWidgets('Billing app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BillingApp(initError: 'test'));
    await tester.pumpAndSettle();

    expect(find.text('A1 Water Tech Admin'), findsOneWidget);
    expect(find.text('Admin Email'), findsOneWidget);
    expect(find.text('Login to Dashboard'), findsOneWidget);
  });
}
