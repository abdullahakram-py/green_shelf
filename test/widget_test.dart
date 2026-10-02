import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_shelf/app/app.dart';

void main() {
  testWidgets('GreenShelfApp renders root shell test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GreenShelfApp(),
      ),
    );

    // Initial frame builds
    expect(find.byType(GreenShelfApp), findsOneWidget);
  });
}
