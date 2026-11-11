class CalculatorEngine {
  /// Evaluates a math expression string and returns the formatted result or 'Error'
  static String evaluate(String expression) {
    if (expression.trim().isEmpty) return '';

    try {
      // 1. Sanitize expression: replace display symbols with standard operators
      String sanitized = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-')
          .replaceAll(' ', '');

      // Remove trailing operators if any before evaluation (e.g., "5 + " -> "5")
      while (sanitized.isNotEmpty &&
          _isOperatorChar(sanitized[sanitized.length - 1])) {
        sanitized = sanitized.substring(0, sanitized.length - 1);
      }

      if (sanitized.isEmpty) return '';

      // Check for division by zero pattern before or during evaluation
      if (RegExp(r'/0(?!\d|\.)').hasMatch(sanitized) ||
          RegExp(r'/0\.0*($|[^1-9])').hasMatch(sanitized)) {
        return 'Error';
      }

      final result = _parseAndCompute(sanitized);

      if (result.isNaN || result.isInfinite) {
        return 'Error';
      }

      return _formatResult(result);
    } catch (_) {
      return 'Error';
    }
  }

  static bool _isOperatorChar(String ch) {
    return ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == '%';
  }

  /// Shunting-yard algorithm based evaluation with BODMAS precedence
  static double _parseAndCompute(String expr) {
    List<double> values = [];
    List<String> ops = [];

    int i = 0;
    bool expectUnary = true; // True at start or after an operator

    while (i < expr.length) {
      String ch = expr[i];

      // Handle numbers & decimals
      if (_isDigit(ch) || ch == '.') {
        StringBuffer numBuffer = StringBuffer();
        while (i < expr.length && (_isDigit(expr[i]) || expr[i] == '.')) {
          numBuffer.write(expr[i]);
          i++;
        }
        double val = double.parse(numBuffer.toString());
        values.add(val);
        expectUnary = false;
        continue;
      }

      // Handle unary minus (negative numbers like "-5")
      if (expectUnary && ch == '-') {
        StringBuffer numBuffer = StringBuffer('-');
        i++;
        while (i < expr.length && (_isDigit(expr[i]) || expr[i] == '.')) {
          numBuffer.write(expr[i]);
          i++;
        }
        double val = double.parse(numBuffer.toString());
        values.add(val);
        expectUnary = false;
        continue;
      }

      // Handle operators
      if (_isOperatorChar(ch)) {
        while (ops.isNotEmpty && _hasPrecedence(ch, ops.last)) {
          _applyTopOp(values, ops);
        }
        ops.add(ch);
        expectUnary = true;
        i++;
        continue;
      }

      i++;
    }

    // Process remaining operators
    while (ops.isNotEmpty) {
      _applyTopOp(values, ops);
    }

    return values.isNotEmpty ? values.last : 0.0;
  }

  static bool _isDigit(String s) {
    return s.codeUnitAt(0) >= 48 && s.codeUnitAt(0) <= 57;
  }

  /// Returns true if op2 has higher or same precedence as op1
  static bool _hasPrecedence(String op1, String op2) {
    int p1 = _getPrecedence(op1);
    int p2 = _getPrecedence(op2);
    return p2 >= p1;
  }

  static int _getPrecedence(String op) {
    if (op == '+' || op == '-') return 1;
    if (op == '*' || op == '/' || op == '%') return 2;
    return 0;
  }

  static void _applyTopOp(List<double> values, List<String> ops) {
    if (values.length < 2 || ops.isEmpty) return;

    double b = values.removeLast();
    double a = values.removeLast();
    String op = ops.removeLast();

    switch (op) {
      case '+':
        values.add(a + b);
        break;
      case '-':
        values.add(a - b);
        break;
      case '*':
        values.add(a * b);
        break;
      case '/':
        if (b == 0) {
          throw Exception('Division by zero');
        }
        values.add(a / b);
        break;
      case '%':
        if (b == 0) throw Exception('Modulo by zero');
        values.add(a % b);
        break;
    }
  }

  /// Formats the numeric result cleanly
  static String _formatResult(double val) {
    if (val.abs() >= 1e12 || (val.abs() > 0 && val.abs() < 1e-6)) {
      return val.toStringAsExponential(4);
    }

    // Check if whole number
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }

    // Format up to 8 decimal places and remove trailing zeros
    String str = val.toStringAsFixed(8);
    if (str.contains('.')) {
      str = str.replaceAll(RegExp(r'0+$'), '');
      str = str.replaceAll(RegExp(r'\.$'), '');
    }
    return str;
  }
}

