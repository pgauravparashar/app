import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mostro/core/app_theme.dart';
import 'package:mostro/features/trades/models/trade_view.dart';
import 'package:mostro/features/trades/widgets/trade_step_block.dart';
import 'package:mostro/l10n/app_localizations.dart';

/// Mounts the step block the way the trade screen does: inside its 18-dp
/// gutter, in a scroll view, at [width] × 800 with [textScale].
Future<void> _pump(
  WidgetTester tester, {
  required TradeChip chip,
  required String Function(AppLocalizations) chipLabel,
  bool withStep = true,
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
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
              child: TradeStepBlock(
                stepLabel: withStep ? l10n.stepIndicator(3, 5) : null,
                chip: chip,
                chipLabel: chipLabel(l10n),
                title: TextSpan(text: l10n.tradeStepFiatBuyer),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // #712, DS-A11Y-4: at 320 dp, 2x text, German, the step label and the
  // status chip used to sit in one Row that could not give way; the
  // buyer's `DU BIST DRAN` overflowed it.
  group('the step block header at 320 dp, 2x text, German', () {
    for (final (chip, label) in <(TradeChip, String Function(AppLocalizations))>[
      (TradeChip.waiting, (l) => l.tradeChipWaiting),
      (TradeChip.active, (l) => l.tradeChipActive),
      (TradeChip.yourTurn, (l) => l.tradeChipYourTurn),
      (TradeChip.dispute, (l) => l.tradeChipDispute),
    ]) {
      testWidgets('does not overflow ($chip)', (tester) async {
        await _pump(tester, chip: chip, chipLabel: label);
        expect(tester.takeException(), isNull);
      });

      testWidgets('does not overflow without a step label ($chip)', (
        tester,
      ) async {
        await _pump(tester, chip: chip, chipLabel: label, withStep: false);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // The regular layout is unchanged: label on the left, chip on the right,
  // on one line.
  testWidgets('at 1x the chip stays on the label line, at the right', (
    tester,
  ) async {
    await _pump(
      tester,
      chip: TradeChip.yourTurn,
      chipLabel: (l) => l.tradeChipYourTurn,
      width: 390,
      textScale: 1.0,
      locale: const Locale('en'),
    );
    expect(tester.takeException(), isNull);

    final label = tester.getRect(find.text('STEP 3 OF 5'));
    final chip = tester.getRect(find.byType(TradeStatusChip));
    expect(chip.left, greaterThan(label.right));
    expect(chip.center.dy, moreOrLessEquals(label.center.dy, epsilon: 1));
    // Right-aligned inside the block's 16-dp padding and 1-dp border.
    final block = tester.getRect(find.byType(TradeStepBlock));
    expect(chip.right, moreOrLessEquals(block.right - 17, epsilon: 0.5));
  });
}
