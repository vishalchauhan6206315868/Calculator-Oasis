import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calculator_app/calculator_engine.dart';
import 'package:calculator_app/main.dart';
import 'package:calculator_app/splash_screen.dart';

void main() {
  group('CalculatorEngine Unit Tests', () {
    test('Addition & Subtraction', () {
      expect(CalculatorEngine.evaluate('15 + 25'), equals('40'));
      expect(CalculatorEngine.evaluate('100 − 35'), equals('65'));
      expect(CalculatorEngine.evaluate('2.5 + 3.75'), equals('6.25'));
    });

    test('Multiplication & Division', () {
      expect(CalculatorEngine.evaluate('7 × 8'), equals('56'));
      expect(CalculatorEngine.evaluate('144 ÷ 12'), equals('12'));
      expect(CalculatorEngine.evaluate('7 ÷ 2'), equals('3.5'));
    });

    test('BODMAS Operator Precedence', () {
      // Multiplication before addition: 2 + (3 * 4) = 14
      expect(CalculatorEngine.evaluate('2 + 3 × 4'), equals('14'));
      // Division before subtraction: 20 - (10 / 2) = 15
      expect(CalculatorEngine.evaluate('20 − 10 ÷ 2'), equals('15'));
    });

    test('Division by Zero Error Handling', () {
      expect(CalculatorEngine.evaluate('10 ÷ 0'), equals('Error'));
      expect(CalculatorEngine.evaluate('5 ÷ 0.0'), equals('Error'));
    });

    test('Negative numbers and leading minus', () {
      expect(CalculatorEngine.evaluate('−5 + 10'), equals('5'));
      expect(CalculatorEngine.evaluate('−10 − 5'), equals('-15'));
    });
  });

  group('Calculator UI Widget Tests', () {
    Finder btn(String label) => find.byKey(Key('btn_$label'));
    Finder resultText() => find.byKey(const Key('result_display'));
    Finder expressionText() => find.byKey(const Key('expression_display'));

    testWidgets('Splash Screen flow: Splash -> CalculatorScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const CalculatorApp());

      // 1. Splash screen displays branding
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Fast • Precise • Reliable'), findsOneWidget);

      // 2. Fast forward 2.6s for Splash timer to navigate
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // 3. CalculatorScreen is now active
      expect(find.byType(CalculatorScreen), findsOneWidget);
      expect(find.byKey(const Key('result_display')), findsOneWidget);
    });

    testWidgets('Basic Calculation UI Flow: 25 + 75 = 100', (WidgetTester tester) async {
      await tester.pumpWidget(const CalculatorApp(startAtCalculator: true));

      // Tap 2, 5
      await tester.tap(btn('2'));
      await tester.pump();
      await tester.tap(btn('5'));
      await tester.pump();

      // Tap +
      await tester.tap(btn('+'));
      await tester.pump();

      // Tap 7, 5
      await tester.tap(btn('7'));
      await tester.pump();
      await tester.tap(btn('5'));
      await tester.pump();

      // Tap =
      await tester.tap(btn('='));
      await tester.pump();

      expect(tester.widget<Text>(resultText()).data, equals('100'));
    });

    testWidgets('Division by zero displays Error', (WidgetTester tester) async {
      await tester.pumpWidget(const CalculatorApp(startAtCalculator: true));

      await tester.tap(btn('8'));
      await tester.pump();
      await tester.tap(btn('÷'));
      await tester.pump();
      await tester.tap(btn('0'));
      await tester.pump();
      await tester.tap(btn('='));
      await tester.pump();

      expect(tester.widget<Text>(resultText()).data, equals('Error'));
    });

    testWidgets('Backspace and Clear buttons test', (WidgetTester tester) async {
      await tester.pumpWidget(const CalculatorApp(startAtCalculator: true));

      // Type 1, 2, 3
      await tester.tap(btn('1'));
      await tester.pump();
      await tester.tap(btn('2'));
      await tester.pump();
      await tester.tap(btn('3'));
      await tester.pump();
      expect(tester.widget<Text>(expressionText()).data, equals('123'));

      // Tap Backspace
      await tester.tap(btn('⌫'));
      await tester.pump();
      expect(tester.widget<Text>(expressionText()).data, equals('12'));

      // Tap Clear
      await tester.tap(btn('C'));
      await tester.pump();
      expect(tester.widget<Text>(expressionText()).data, equals('0'));
      expect(tester.widget<Text>(resultText()).data, equals('0'));
    });

    testWidgets('Rapid repeated operator taps do not crash (replaces operator)',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CalculatorApp(startAtCalculator: true));

      await tester.tap(btn('9'));
      await tester.pump();

      // Rapidly tap multiple operators
      await tester.tap(btn('+'));
      await tester.pump();
      await tester.tap(btn('×'));
      await tester.pump();
      await tester.tap(btn('−'));
      await tester.pump();

      // The expression should have replaced operators with '−'
      expect(tester.widget<Text>(expressionText()).data, equals('9−'));

      // Now tap 4 and =
      await tester.tap(btn('4'));
      await tester.pump();
      await tester.tap(btn('='));
      await tester.pump();

      expect(tester.widget<Text>(resultText()).data, equals('5'));
    });
  });
}
