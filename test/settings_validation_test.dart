import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:celly_viewer/main.dart';
import 'package:celly_viewer/settings_page.dart';
import 'package:celly_viewer/settings_model.dart';
import 'package:celly_viewer/settings_service.dart';

class TestSettingsService extends SettingsService {
  bool saveCalled = false;
  AppSettings? saved;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    saveCalled = true;
    saved = settings;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('invalid rule number does not crash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    final ruleField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Rule',
    );
    expect(ruleField, findsOneWidget);

    await tester.enterText(ruleField, '1000000');
    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    final TextField fieldWidget = tester.widget(ruleField);
    expect(fieldWidget.controller?.text, '0');
  });

  testWidgets('invalid minLines value not saved', (WidgetTester tester) async {
    final service = TestSettingsService();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          initialSettings: AppSettings(),
          settingsService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final minLinesField = find.widgetWithText(
      TextFormField,
      'Minimum Unique Lines (MinLines)',
    );
    await tester.enterText(minLinesField, 'abc');
    final formState = tester.state<FormState>(find.byType(Form));
    expect(formState.validate(), isFalse);
    expect(service.saveCalled, isFalse);
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('invalid width value not saved', (WidgetTester tester) async {
    final service = TestSettingsService();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          initialSettings: AppSettings(),
          settingsService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final widthField = find.widgetWithText(TextFormField, 'Width (max 2000)');
    await tester.enterText(widthField, 'abc');
    final formState = tester.state<FormState>(find.byType(Form));
    expect(formState.validate(), isFalse);
    expect(service.saveCalled, isFalse);
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
