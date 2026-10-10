import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xaneo/providers/theme_provider.dart';
import 'package:xaneo/styles/app_styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selectable font families are bundled', () async {
    final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json'))
        as List<dynamic>;
    final families = manifest.map((entry) => entry['family']).toSet();
    expect(families, containsAll(<String>['Inter', 'Onest', 'Geist']));
  });

  testWidgets('XNX font reaches interface text styles', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = ThemeProvider();
    for (final family in <String>['Onest', 'Geist']) {
      await provider.importXnx(
          '{ colors = { bg = "#141414"; text = "#ffffff"; }; typography = { font-family = "$family"; }; }');
      await tester.pumpWidget(ChangeNotifierProvider<ThemeProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: provider.themeData,
          home: Scaffold(
            body: Builder(builder: (context) => Text(
                  'Оформление',
                  style: AppStyles.titleLarge(context),
                )),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final element = tester.element(find.text('Оформление'));
      final label = tester.widget<Text>(find.text('Оформление'));
      expect(DefaultTextStyle.of(element).style.merge(label.style).fontFamily,
          family);
    }
    provider.dispose();
  });
}
