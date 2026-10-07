import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mostro/core/app_theme.dart';
import 'package:mostro/features/order/widgets/invoice_widgets.dart';
import 'package:mostro/l10n/app_localizations.dart';

/// Mounts the view as the bond screens do: the body under an app bar, at
/// [width] × 800 with [textScale].
Future<void> _pump(
  WidgetTester tester, {
  required String Function(AppLocalizations) title,
  required String Function(AppLocalizations) body,
  double width = 320,
  double textScale = 2.0,
  Locale locale = const Locale('de'),
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildDarkTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            appBar: AppBar(title: const Text('Mostro')),
            body: InvoiceTimeUpView(
              title: title(l10n),
              body: body(l10n),
              actionLabel: l10n.invoiceBackToBook,
              onAction: () {},
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // #712, DS-A11Y-4: the view laid its content between two Spacers in a
  // Column that could not scroll, so at 2x it overflowed the height. Since
  // #710 only the bond screens show it.
  group('the time-up view at 320 dp, 2x text, German', () {
    for (final (name, title, body)
        in <(
          String,
          String Function(AppLocalizations),
          String Function(AppLocalizations),
        )>[
          ('bond, taker', (l) => l.bondExpiredTitle, (l) => l.bondExpiredBody),
          (
            'bond, maker',
            (l) => l.bondExpiredTitle,
            (l) => l.bondExpiredBodyMaker,
          ),
          (
            'invoice',
            (l) => l.invoiceTimeUpTitle,
            (l) => l.invoiceTimeUpBody,
          ),
          (
            'hold invoice',
            (l) => l.invoiceExpiredTitle,
            (l) => l.invoiceExpiredBody,
          ),
        ]) {
      testWidgets('does not overflow and reaches its button ($name)', (
        tester,
      ) async {
        await _pump(tester, title: title, body: body);
        expect(tester.takeException(), isNull);

        final back =
            lookupAppLocalizations(const Locale('de')).invoiceBackToBook;
        await tester.scrollUntilVisible(
          find.text(back),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(back).hitTestable(), findsOneWidget);
      });
    }
  });

  // The regular layout is unchanged: the message in the middle, the button
  // at the bottom of the screen.
  testWidgets('at 1x the button stays at the bottom of the screen', (
    tester,
  ) async {
    await _pump(
      tester,
      title: (l) => l.bondExpiredTitle,
      body: (l) => l.bondExpiredBody,
      width: 390,
      textScale: 1.0,
      locale: const Locale('en'),
    );
    expect(tester.takeException(), isNull);

    final button = tester.getRect(find.byType(InvoicePrimaryButton));
    // 800 high, minus the 18-dp gutter (no system inset in tests).
    expect(button.bottom, moreOrLessEquals(800 - kInvoiceGutter, epsilon: 1));
  });
}
