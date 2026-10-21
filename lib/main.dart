import 'package:flutter/material.dart';

void main() => runApp(const LudoApp());

class LudoApp extends StatelessWidget {
  const LudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ludo',
      theme: ThemeData(useMaterial3: true),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E6),
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CustomPaint(painter: BoardPainter()),
            ),
          ),
        ),
      ),
    );
  }
}

const kRed = Color(0xFFE53935);
const kGreen = Color(0xFF43A047);
const kYellow = Color(0xFFFDD835);
const kBlue = Color(0xFF1E88E5);

class BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / 15;
    Rect cell(int col, int row) => Rect.fromLTWH(col * c, row * c, c, c);

    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black54
      ..strokeWidth = 1;

    canvas.drawRect(Offset.zero & size, fill..color = Colors.white);

    void home(int col, int row, Color color) {
      canvas.drawRect(
        Rect.fromLTWH(col * c, row * c, 6 * c, 6 * c),
        fill..color = color,
      );
      canvas.drawRect(
        Rect.fromLTWH((col + 1) * c, (row + 1) * c, 4 * c, 4 * c),
        fill..color = Colors.white,
      );
      for (final p in [
        [col + 2, row + 2],
        [col + 4, row + 2],
        [col + 2, row + 4],
        [col + 4, row + 4],
      ]) {
        canvas.drawCircle(
          Offset(p[0] * c, p[1] * c),
          c * 0.42,
          fill..color = color,
        );
      }
    }

    home(0, 0, kRed);
    home(9, 0, kGreen);
    home(9, 9, kYellow);
    home(0, 9, kBlue);

    for (int r = 0; r < 15; r++) {
      for (int col = 0; col < 15; col++) {
        final inCross = (col >= 6 && col <= 8) || (r >= 6 && r <= 8);
        final inCenter = col >= 6 && col <= 8 && r >= 6 && r <= 8;
        if (inCross && !inCenter) {
          canvas.drawRect(cell(col, r), line);
        }
      }
    }

    void lane(Color color, List<List<int>> cells) {
      for (final p in cells) {
        canvas.drawRect(cell(p[0], p[1]), fill..color = color);
        canvas.drawRect(cell(p[0], p[1]), line);
      }
    }

    lane(kRed, [for (int i = 1; i <= 5; i++) [i, 7]]);
    lane(kGreen, [for (int i = 1; i <= 5; i++) [7, i]]);
    lane(kYellow, [for (int i = 9; i <= 13; i++) [i, 7]]);
    lane(kBlue, [for (int i = 9; i <= 13; i++) [7, i]]);

    lane(kRed, [[1, 6]]);
    lane(kGreen, [[8, 1]]);
    lane(kYellow, [[13, 8]]);
    lane(kBlue, [[6, 13]]);

    final tl = Offset(6 * c, 6 * c);
    final tr = Offset(9 * c, 6 * c);
    final bl = Offset(6 * c, 9 * c);
    final br = Offset(9 * c, 9 * c);
    final mid = Offset(7.5 * c, 7.5 * c);

    void tri(Offset a, Offset b, Color color) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(mid.dx, mid.dy)
        ..close();
      canvas.drawPath(path, fill..color = color);
    }

    tri(tl, bl, kRed);
    tri(tl, tr, kGreen);
    tri(tr, br, kYellow);
    tri(bl, br, kBlue);

    canvas.drawRect(Offset.zero & size, line..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
