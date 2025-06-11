import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:celly_viewer/main.dart';
import 'package:celly_viewer/settings_page.dart';
import 'package:celly_viewer/settings_model.dart';
import 'package:celly_viewer/settings_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('main page loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CellularAutomataPage), findsOneWidget);
  });

  testWidgets('settings page loads', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SettingsPage(
        initialSettings: AppSettings(),
        settingsService: SettingsService(),
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
