import 'package:flutter/material.dart';
import 'package:flutter_calendar_heatmap/src/datetime.dart';
import 'package:intl/intl.dart' as intl;

class HeatMap extends StatelessWidget {
  HeatMap({
    super.key,
    required this.data,
    this.aspectRatio = 2.3,
    this.colors,
    this.textStyle,
    this.strokeColor,
    this.itemSize = 14,
    this.itemPadding = 4,
  });

  final double aspectRatio;
  final Map<DateTime, int> data;

  List<Color>? colors;
  final TextStyle? textStyle;
  final Color? strokeColor;
  final double itemSize;
  final double itemPadding;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: CustomPaint(
        painter: HeatMapPainter(
          data: data,
          colors: colors ??
              [
                Colors.green.shade200,
                Colors.green.shade400,
                Colors.green.shade600,
                Colors.green.shade800,
              ],
          strokeColor: strokeColor ?? Colors.red.shade100,
          textStyle: textStyle ??
              TextStyle(
                color: Colors.black.withOpacity(0.9),
                fontSize: 12,
              ),
          itemPadding: itemPadding,
          itemSize: itemSize,
        ),
      ),
    );
  }
}

class HeatMapPainter extends CustomPainter {
  HeatMapPainter({
    required this.data,
    required this.colors,
    required this.textStyle,
    required this.strokeColor,
    required this.itemSize,
    required this.itemPadding,
    this.dayFormat = 'E',
    this.startingDay = 0,
  });

  final Map<DateTime, int> data;
  final List<Color> colors;
  final TextStyle textStyle;
  final Color strokeColor;
  final double itemSize;
  final double itemPadding;
  static const int rows = 7;
  static const int totalColumns = 0;
  final String dayFormat;

  /// Accepts 0 - 6 (Sun - Sat). Invalid or missing will start on Sunday
  final int startingDay;
  List<bool> hasDrawnMonth = [];

  @override
  void paint(Canvas canvas, Size size) {
    int cols =
        (totalColumns > 0 ? totalColumns : _calculateColumns(size.width)) + 1;
    hasDrawnMonth = List.filled(cols, false);

    double heatMapWidth = _calculateHeatMapWidth(cols + 2);
    double startX = _calculateStartX(size.width, heatMapWidth);

    Paint strokePaint = createStrokePaint();
    int totalItems = rows * (cols - 1);
    // Draw heatmap cells
    for (int i = 0; i < totalItems; i++) {
      var dateAtIndex = _calculateDateForIndex((cols - 1), i);

      var value = data[dateAtIndex] ?? 0;
      var paint = Paint()
        ..color = _getColorForValue(value)
        ..style = PaintingStyle.fill;

      _drawCell(canvas, paint, i, startX, strokePaint, dateAtIndex);
    }
    final startingDayOfWeek =
        (startingDay >= 0) && (startingDay <= 6) ? startingDay : 0;
    // Draw day of week column
    for (int i = 0; i < rows; i++) {
      DateTime date = DateTime.now().add(
          Duration(days: (7 - DateTime.now().day) + startingDayOfWeek + i));
      TextSpan span = TextSpan(
        text: intl.DateFormat(dayFormat).format(date),
        style: textStyle,
      );
      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      double xPos =
          startX + (cols - 1) * (itemSize + itemPadding) + itemPadding;
      double yPos = i * (itemSize + itemPadding) + (itemSize - tp.height) / 2;
      tp.paint(canvas, Offset(xPos, yPos));
    }
  }

  void _drawCell(Canvas canvas, Paint paint, int index, double startX,
      Paint strokePaint, DateTime dateAtIndex) {
    var col = index ~/ rows;
    var row = index % rows;
    final rect = _calculateCellRect(startX, col, row);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );

    if (dateAtIndex.isToday) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        strokePaint,
      );
    }

    if (dateAtIndex.day == 1 && !hasDrawnMonth[col]) {
      hasDrawnMonth[col] = true;
      _drawMonthText(canvas, dateAtIndex, col, startX);
    }
  }

  Rect _calculateCellRect(double startX, int col, int row) {
    double left = startX + col * (itemSize + itemPadding);
    double top = row * (itemSize + itemPadding);
    return Rect.fromLTWH(left, top, itemSize, itemSize);
  }

  double _calculateHeatMapWidth(int cols) {
    return cols * (itemSize + itemPadding) - itemPadding;
  }

  double _calculateStartX(double totalWidth, double heatMapWidth) {
    return (totalWidth - heatMapWidth) / 2;
  }

  Paint createStrokePaint() {
    return Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
  }

  void _drawMonthText(Canvas canvas, DateTime date, int col, double startX) {
    String monthText = intl.DateFormat('MMM yy').format(date);

    TextPainter textPainter = TextPainter(
      text: TextSpan(text: monthText, style: textStyle),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    double xPosition = _calculateTextXPosition(col, startX, textPainter.width);
    Offset textPosition = Offset(
      xPosition,
      (rows * itemSize) + (rows * itemPadding) + itemPadding,
    );

    textPainter.paint(canvas, textPosition);
  }

  double _calculateTextXPosition(int col, double startX, double textWidth) {
    double colRightBoundary =
        startX + col * (itemSize + itemPadding) + itemSize + itemPadding;
    return colRightBoundary - textWidth - itemPadding;
  }

  DateTime _calculateDateForIndex(int cols, int index) {
    DateTime startOfCurrentWeek = DateTime.now()
        .subtract(Duration(days: DateTime.now().weekday))
        .add(Duration(
            days: (startingDay >= 0) && (startingDay <= 6) ? startingDay : 0));
    DateTime startDate =
        startOfCurrentWeek.subtract(Duration(days: (cols - 1) * 7));

    int weeksPassed = index ~/ 7;
    int dayOfWeek = index % 7;

    return startDate.add(Duration(days: weeksPassed * 7 + dayOfWeek)).midnight;
  }

  Color _getColorForValue(int value) {
    if (value >= colors.length) {
      return colors.last;
    } else {
      return colors[value % colors.length];
    }
  }

  int _calculateColumns(double width) {
    return (width + itemPadding) ~/ (itemSize + itemPadding);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
