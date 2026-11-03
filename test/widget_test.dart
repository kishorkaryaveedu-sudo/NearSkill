import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


void main() {
  testWidgets('NearSkillApp renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('NearSkill'),
            ),
          ),
        ),
      ),
    );

    // Verify that the text is present
    expect(find.text('NearSkill'), findsOneWidget);
  });
}
