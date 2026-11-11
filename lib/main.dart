import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'calculator_engine.dart';
import 'splash_screen.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  final bool startAtCalculator;

  const CalculatorApp({super.key, this.startAtCalculator = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9500), // Iconic calculator orange
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF17171C),
      ),
      home: startAtCalculator
          ? const CalculatorScreen()
          : const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/calculator': (context) => const CalculatorScreen(),
      },
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '0';
  bool _isCalculated = false;

  final ScrollController _scrollController = ScrollController();

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Handle number input (0-9, 00)
  void _onNumberTap(String number) {
    HapticFeedback.lightImpact();

    setState(() {
      if (_isCalculated) {
        // If result was just calculated, start fresh with new number
        _expression = number;
        _isCalculated = false;
      } else {
        // Prevent leading redundant zeros like "00" or "05"
        if (_expression == '0' && number != '.') {
          _expression = number;
        } else {
          _expression += number;
        }
      }

      // Compute live preview
      _computeLiveResult();
    });

    _scrollToEnd();
  }

  // Handle decimal point (.)
  void _onDecimalTap() {
    HapticFeedback.lightImpact();

    setState(() {
      if (_isCalculated) {
        _expression = '0.';
        _isCalculated = false;
        _computeLiveResult();
        return;
      }

      if (_expression.isEmpty) {
        _expression = '0.';
        return;
      }

      // Check current active number segment to prevent multiple dots
      final tokens = _expression.split(RegExp(r'[+\−×÷%]'));
      final lastToken = tokens.isNotEmpty ? tokens.last : '';

      if (!lastToken.contains('.')) {
        if (_isOperator(_expression[_expression.length - 1])) {
          _expression += '0.';
        } else {
          _expression += '.';
        }
      }
    });

    _scrollToEnd();
  }

  // Handle operators (+, −, ×, ÷, %)
  void _onOperatorTap(String op) {
    HapticFeedback.mediumImpact();

    setState(() {
      if (_isCalculated) {
        // Continue from evaluated result
        if (_result != 'Error') {
          _expression = _result + op;
        } else {
          _expression = '';
        }
        _isCalculated = false;
        return;
      }

      if (_expression.isEmpty) {
        // Allow unary minus at start
        if (op == '−') {
          _expression = '−';
        }
        return;
      }

      final lastChar = _expression[_expression.length - 1];

      if (_isOperator(lastChar)) {
        // Replace previous operator on rapid/repeated tap (Crash Prevention)
        _expression = _expression.substring(0, _expression.length - 1) + op;
      } else {
        _expression += op;
      }

      // If user typed an operator, keep live preview current
      _computeLiveResult();
    });

    _scrollToEnd();
  }

  // Clear / Reset (C)
  void _onClearTap() {
    HapticFeedback.mediumImpact();
    setState(() {
      _expression = '';
      _result = '0';
      _isCalculated = false;
    });
  }

  // Backspace (⌫)
  void _onBackspaceTap() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isCalculated) {
        _expression = '';
        _result = '0';
        _isCalculated = false;
        return;
      }

      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
        if (_expression.isEmpty) {
          _result = '0';
        } else {
          _computeLiveResult();
        }
      }
    });
  }

  // Equals (=)
  void _onEqualsTap() {
    HapticFeedback.heavyImpact();

    if (_expression.isEmpty) return;

    final evalResult = CalculatorEngine.evaluate(_expression);

    setState(() {
      _result = evalResult;
      _isCalculated = true;
    });
  }

  void _computeLiveResult() {
    if (_expression.isEmpty) {
      _result = '0';
      return;
    }

    // Only compute live result if expression has at least one operator followed by a number
    if (RegExp(r'[+\−×÷%]\d').hasMatch(_expression)) {
      final res = CalculatorEngine.evaluate(_expression);
      if (res != 'Error') {
        _result = res;
      }
    }
  }

  bool _isOperator(String ch) {
    return ch == '+' || ch == '−' || ch == '×' || ch == '÷' || ch == '%';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.calculate_rounded,
                  color: Color(0xFFFF9500),
                );
              },
            ),
          ),
        ),
        title: const Text(
          'Calculator',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Copy Result',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _result));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Result copied to clipboard!'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display Area (Dual-line expression & result)
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Top: Input Expression with horizontal scroll
                    SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        _expression.isEmpty ? '0' : _expression,
                        key: const Key('expression_display'),
                        style: TextStyle(
                          fontSize: _isCalculated ? 26 : 36,
                          fontWeight: FontWeight.w400,
                          color: _isCalculated
                              ? Colors.grey.shade500
                              : Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Bottom: Evaluated Result Display
                    Text(
                      _result,
                      key: const Key('result_display'),
                      style: TextStyle(
                        fontSize: _result == 'Error' ? 42 : 56,
                        fontWeight: FontWeight.bold,
                        color: _result == 'Error'
                            ? Colors.redAccent
                            : _isCalculated
                                ? const Color(0xFFFF9500)
                                : Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Button Grid Area (4x5 responsive layout)
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildButtonRow(['C', '⌫', '%', '÷']),
                    _buildButtonRow(['7', '8', '9', '×']),
                    _buildButtonRow(['4', '5', '6', '−']),
                    _buildButtonRow(['1', '2', '3', '+']),
                    _buildButtonRow(['00', '0', '.', '=']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<String> labels) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: labels.map((label) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: _buildCalculatorButton(label),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalculatorButton(String label) {
    final bool isOp = label == '+' || label == '−' || label == '×' || label == '÷';
    final bool isEquals = label == '=';
    final bool isAction = label == 'C' || label == '⌫' || label == '%';

    Color bgColor;
    Color textColor;

    if (isEquals) {
      bgColor = const Color(0xFFFF9500); // Highlighted orange
      textColor = Colors.white;
    } else if (isOp) {
      bgColor = const Color(0xFF2C2C34);
      textColor = const Color(0xFFFF9500);
    } else if (isAction) {
      bgColor = const Color(0xFF2C2C34);
      textColor = const Color(0xFF00E676);
    } else {
      // Numbers (0-9, 00, .)
      bgColor = const Color(0xFF212228);
      textColor = Colors.white;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        key: Key('btn_$label'),
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (label == 'C') {
            _onClearTap();
          } else if (label == '⌫') {
            _onBackspaceTap();
          } else if (label == '=') {
            _onEqualsTap();
          } else if (label == '.') {
            _onDecimalTap();
          } else if (isOp || label == '%') {
            _onOperatorTap(label);
          } else {
            _onNumberTap(label);
          }
        },
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
