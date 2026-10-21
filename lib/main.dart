import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const LudoApp());

const kRed = Color(0xFFE53935);
const kGreen = Color(0xFF43A047);
const kYellow = Color(0xFFFDD835);
const kBlue = Color(0xFF1E88E5);
const kColors = [kRed, kGreen, kYellow, kBlue];
const kNames = ['Red', 'Green', 'Yellow', 'Blue'];

// 52 cells of the main track (col, row), clockwise, starting at Red start.
const List<List<int>> kTrack = [
  [1, 6], [2, 6], [3, 6], [4, 6], [5, 6],
  [6, 5], [6, 4], [6, 3], [6, 2], [6, 1], [6, 0],
  [7, 0], [8, 0],
  [8, 1], [8, 2], [8, 3], [8, 4], [8, 5],
  [9, 6], [10, 6], [11, 6], [12, 6], [13, 6], [14, 6],
  [14, 7], [14, 8],
  [13, 8], [12, 8], [11, 8], [10, 8], [9, 8],
  [8, 9], [8, 10], [8, 11], [8, 12], [8, 13], [8, 14],
  [7, 14], [6, 14],
  [6, 13], [6, 12], [6, 11], [6, 10], [6, 9],
  [5, 8], [4, 8], [3, 8], [2, 8], [1, 8], [0, 8],
  [0, 7], [0, 6],
];

// Home lanes (5 cells each) for Red, Green, Yellow, Blue.
const List<List<List<int>>> kLanes = [
  [[1, 7], [2, 7], [3, 7], [4, 7], [5, 7]],
  [[7, 1], [7, 2], [7, 3], [7, 4], [7, 5]],
  [[13, 7], [12, 7], [11, 7], [10, 7], [9, 7]],
  [[7, 13], [7, 12], [7, 11], [7, 10], [7, 9]],
];

const List<int> kStart = [0, 13, 26, 39];
const Set<int> kSafe = {0, 13, 26, 39, 8, 21, 34, 47};
const List<List<int>> kYard = [
  [0, 0],
  [9, 0],
  [9, 9],
  [0, 9],
];

// Position of a token in grid units (center of the token).
Offset gridPos(int player, int token, int progress) {
  if (progress < 0) {
    final ox = kYard[player][0];
    final oy = kYard[player][1];
    final x = ox + (token % 2 == 0 ? 2 : 4);
    final y = oy + (token < 2 ? 2 : 4);
    return Offset(x.toDouble(), y.toDouble());
  }
  if (progress <= 50) {
    final t = kTrack[(kStart[player] + progress) % 52];
    return Offset(t[0] + 0.5, t[1] + 0.5);
  }
  if (progress <= 55) {
    final l = kLanes[player][progress - 51];
    return Offset(l[0] + 0.5, l[1] + 0.5);
  }
  // Finished: park inside own triangle in the center.
  final d = token * 0.1 - 0.15;
  switch (player) {
    case 0:
      return Offset(6.9, 7.5 + d);
    case 1:
      return Offset(7.5 + d, 6.9);
    case 2:
      return Offset(8.1, 7.5 + d);
    default:
      return Offset(7.5 + d, 8.1);
  }
}

class LudoApp extends StatelessWidget {
  const LudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ludoverse',
      theme: ThemeData(useMaterial3: true),
      home: const MenuScreen(),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  void _start(BuildContext context, List<int> players, Set<int> ai) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(players: players, ai: ai),
      ),
    );
  }

  Widget _btn(BuildContext context, String text, List<int> p, Set<int> ai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: 260,
        height: 54,
        child: FilledButton(
          onPressed: () => _start(context, p, ai),
          child: Text(text, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E6),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ludoverse',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            _btn(context, 'Play vs Computer', [0, 2], {2}),
            _btn(context, '2 Players', [0, 2], {}),
            _btn(context, '3 Players', [0, 1, 2], {}),
            _btn(context, '4 Players', [0, 1, 2, 3], {}),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final List<int> players;
  final Set<int> ai;
  const GameScreen({super.key, required this.players, required this.ai});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<List<int>> pos = List.generate(4, (_) => List.filled(4, -1));
  final Random rnd = Random();
  int turnIdx = 0;
  int dice = 0;
  bool rolled = false;
  bool over = false;
  String msg = '';

  int get cur => widget.players[turnIdx];
  bool get curIsAi => widget.ai.contains(cur);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTurn());
  }

  void _startTurn() {
    if (!mounted || over) return;
    setState(() {
      msg = curIsAi ? 'Computer is playing...' : 'Tap the dice to roll';
    });
    if (curIsAi) {
      Future.delayed(const Duration(milliseconds: 800), _roll);
    }
  }

  bool _legal(int t) {
    final p = pos[cur][t];
    if (p == -1) return dice == 6;
    return p + dice <= 56;
  }

  List<int> _movable() {
    if (!rolled) return [];
    return [
      for (int t = 0; t < 4; t++)
        if (_legal(t)) t
    ];
  }

  void _roll() {
    if (!mounted || over || rolled) return;
    setState(() {
      dice = rnd.nextInt(6) + 1;
      rolled = true;
    });
    final moves = _movable();
    if (moves.isEmpty) {
      setState(() => msg = 'No move possible');
      Future.delayed(const Duration(milliseconds: 1000), _passTurn);
    } else if (curIsAi) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !over) _move(_aiPick(moves));
      });
    } else if (moves.length == 1) {
      setState(() => msg = 'Moving...');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !over) _move(moves.first);
      });
    } else {
      setState(() => msg = 'Tap a glowing token to move');
    }
  }

  void _passTurn() {
    if (!mounted || over) return;
    setState(() {
      rolled = false;
      turnIdx = (turnIdx + 1) % widget.players.length;
    });
    _startTurn();
  }

  bool _wouldCapture(int p, int newProgress) {
    if (newProgress > 50) return false;
    final g = (kStart[p] + newProgress) % 52;
    if (kSafe.contains(g)) return false;
    for (final q in widget.players) {
      if (q == p) continue;
      for (int t = 0; t < 4; t++) {
        final qp = pos[q][t];
        if (qp >= 0 && qp <= 50 && (kStart[q] + qp) % 52 == g) return true;
      }
    }
    return false;
  }

  int _aiPick(List<int> moves) {
    int best = moves.first;
    double bestScore = -1;
    for (final t in moves) {
      final old = pos[cur][t];
      final nw = old == -1 ? 0 : old + dice;
      double score = nw.toDouble();
      if (old == -1) score += 30;
      if (nw == 56) score += 50;
      if (_wouldCapture(cur, nw)) score += 60;
      if (nw <= 50 && kSafe.contains((kStart[cur] + nw) % 52)) score += 5;
      if (score > bestScore) {
        bestScore = score;
        best = t;
      }
    }
    return best;
  }

  void _move(int t) {
    if (!rolled || over) return;
    final p = cur;
    final old = pos[p][t];
    final nw = old == -1 ? 0 : old + dice;
    bool captured = false;

    if (_wouldCapture(p, nw)) {
      final g = (kStart[p] + nw) % 52;
      for (final q in widget.players) {
        if (q == p) continue;
        for (int k = 0; k < 4; k++) {
          final qp = pos[q][k];
          if (qp >= 0 && qp <= 50 && (kStart[q] + qp) % 52 == g) {
            pos[q][k] = -1;
            captured = true;
          }
        }
      }
    }
    pos[p][t] = nw;

    if (pos[p].every((x) => x == 56)) {
      setState(() {
        over = true;
        rolled = false;
      });
      _showWinner(p);
      return;
    }

    final extra = dice == 6 || captured || nw == 56;
    setState(() {
      rolled = false;
      if (!extra) {
        turnIdx = (turnIdx + 1) % widget.players.length;
      }
    });
    _startTurn();
  }

  void _showWinner(int p) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('${kNames[p]} wins!'),
        content: const Text('Congratulations!'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Menu'),
          ),
        ],
      ),
    );
  }

  void _onTap(Offset o, double size) {
    if (!rolled || curIsAi || over) return;
    final c = size / 15;
    for (final t in _movable()) {
      final g = gridPos(cur, t, pos[cur][t]);
      final center = Offset(g.dx * c, g.dy * c);
      if ((center - o).distance < c * 0.9) {
        _move(t);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = kColors[cur];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E6),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              "${kNames[cur]}'s turn${curIsAi ? ' (Computer)' : ''}",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color == kYellow ? Colors.amber.shade800 : color,
              ),
            ),
            const SizedBox(height: 4),
            Text(msg, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (ctx, cons) {
                    final s = cons.maxWidth;
                    return GestureDetector(
                      onTapUp: (d) => _onTap(d.localPosition, s),
                      child: CustomPaint(
                        size: Size(s, s),
                        painter: BoardPainter(
                          pos: pos,
                          players: widget.players,
                          current: cur,
                          movable: _movable(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                if (!rolled && !curIsAi && !over) _roll();
              },
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color, width: 5),
                ),
                alignment: Alignment.center,
                child: Text(
                  dice == 0 ? 'ROLL' : '$dice',
                  style: TextStyle(
                    fontSize: dice == 0 ? 20 : 46,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  final List<List<int>> pos;
  final List<int> players;
  final int current;
  final List<int> movable;

  BoardPainter({
    required this.pos,
    required this.players,
    required this.current,
    required this.movable,
  });

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
          fill..color = color.withOpacity(0.35),
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

    for (int i = 0; i < 4; i++) {
      lane(kColors[i], kLanes[i]);
      lane(kColors[i], [kTrack[kStart[i]]]);
    }

    // Safe star cells (small dot)
    for (final g in kSafe) {
      if (g == 0 || g == 13 || g == 26 || g == 39) continue;
      final t = kTrack[g];
      canvas.drawCircle(
        Offset((t[0] + 0.5) * c, (t[1] + 0.5) * c),
        c * 0.18,
        fill..color = Colors.black38,
      );
    }

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

    // Tokens
    final used = <String, int>{};
    for (final p in players) {
      for (int t = 0; t < 4; t++) {
        final g = gridPos(p, t, pos[p][t]);
        final key = '${g.dx.toStringAsFixed(1)}_${g.dy.toStringAsFixed(1)}';
        final k = used[key] ?? 0;
        used[key] = k + 1;
        final center = Offset(g.dx * c + k * c * 0.14, g.dy * c - k * c * 0.14);

        final isMovable = p == current && movable.contains(t);
        if (isMovable) {
          canvas.drawCircle(
            center,
            c * 0.55,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.black,
          );
        }
        canvas.drawCircle(center, c * 0.38, fill..color = kColors[p]);
        canvas.drawCircle(
          center,
          c * 0.38,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white,
        );
        canvas.drawCircle(
          center,
          c * 0.38,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.black87,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
