import 'package:flutter_test/flutter_test.dart';
import 'package:gara_app/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GaraApp());
    expect(find.text('GARA'), findsOneWidget);
  });
}
