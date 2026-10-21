import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

void main() => runApp(const LudoApp());

const kRed = Color(0xFFE0533A);
const kGreen = Color(0xFF5CC460);
const kYellow = Color(0xFFF2C744);
const kBlue = Color(0xFF3E8EF7);
const kColors = [kRed, kGreen, kYellow, kBlue];
const kNames = ['Red', 'Green', 'Yellow', 'Blue'];

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

// ---------------- Sound (generated in code, no files needed) ----------------

Uint8List _wav(List<double> s, {int rate = 22050}) {
  final n = s.length;
  final data = ByteData(44 + n * 2);
  void str(int o, String t) {
    for (int i = 0; i < t.length; i++) {
      data.setUint8(o + i, t.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + n * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, n * 2, Endian.little);
  for (int i = 0; i < n; i++) {
    final v = (max(-1.0, min(1.0, s[i])) * 32767).round();
    data.setInt16(44 + i * 2, v, Endian.little);
  }
  return data.buffer.asUint8List();
}

List<double> _tone(double f, double sec, {double vol = 0.5, double endF = 0}) {
  const rate = 22050;
  final n = (rate * sec).round();
  final out = <double>[];
  double phase = 0;
  for (int i = 0; i < n; i++) {
    final t = i / n;
    final freq = endF > 0 ? f + (endF - f) * t : f;
    phase += 2 * pi * freq / rate;
    out.add(sin(phase) * vol * (1 - t));
  }
  return out;
}

List<double> _rattle() {
  const rate = 22050;
  final r = Random(7);
  final out = <double>[];
  for (int k = 0; k < 7; k++) {
    final n = (rate * 0.035).round();
    for (int i = 0; i < n; i++) {
      out.add((r.nextDouble() * 2 - 1) * 0.5 * (1 - i / n));
    }
    out.addAll(List.filled((rate * 0.03).round(), 0.0));
  }
  return out;
}

class Sfx {
  static final Map<String, Uint8List> _cache = {};
  static AudioPlayer? _player;

  static Uint8List _get(String k) {
    return _cache.putIfAbsent(k, () {
      switch (k) {
        case 'roll':
          return _wav(_rattle());
        case 'move':
          return _wav(_tone(700, 0.09, vol: 0.5, endF: 900));
        case 'capture':
          return _wav(_tone(600, 0.3, vol: 0.6, endF: 150));
        case 'win':
          return _wav([
            ..._tone(523, 0.15),
            ..._tone(659, 0.15),
            ..._tone(784, 0.15),
            ..._tone(1047, 0.4),
          ]);
        default:
          return _wav(_tone(800, 0.05));
      }
    });
  }

  static Future<void> play(String k) async {
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.play(BytesSource(_get(k)));
    } catch (_) {}
  }
}

// ---------------- App ----------------

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

const _bgDecoration = BoxDecoration(
  gradient: RadialGradient(
    center: Alignment(0, -0.3),
    radius: 1.1,
    colors: [Color(0xFF5A2A78), Color(0xFF1E0A2E)],
  ),
);

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
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF2C744),
            foregroundColor: Colors.black87,
          ),
          onPressed: () => _start(context, p, ai),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: _bgDecoration,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ludoverse',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              _btn(context, 'Play vs Computer', [0, 2], {2}),
              _btn(context, '2 Players', [0, 2], {}),
              _btn(context, '3 Players', [0, 1, 2], {}),
              _btn(context, '4 Players', [0, 1, 2, 3], {}),
            ],
          ),
        ),
      ),
    );
  }
}

class DiceFace extends StatelessWidget {
  final int value;
  final Color color;
  final double size;
  final bool glow;
  const DiceFace({
    super.key,
    required this.value,
    required this.color,
    required this.size,
    required this.glow,
  });

  static const Map<int, List<int>> patterns = {
    1: [4],
    2: [0, 8],
    3: [0, 4, 8],
    4: [0, 2, 6, 8],
    5: [0, 2, 4, 6, 8],
    6: [0, 2, 3, 5, 6, 8],
  };

  @override
  Widget build(BuildContext context) {
    final dots = patterns[value] ?? const <int>[];
    final dot = size * 0.17;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(
            color: glow ? color.withOpacity(0.8) : Colors.black45,
            blurRadius: glow ? 16 : 6,
            spreadRadius: glow ? 2 : 0,
            offset: glow ? Offset.zero : const Offset(0, 3),
          ),
        ],
      ),
      child: value == 0
          ? Center(
              child: Text(
                glow ? 'TAP' : '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            )
          : Column(
              children: [
                for (int r = 0; r < 3; r++)
                  Expanded(
                    child: Row(
                      children: [
                        for (int c = 0; c < 3; c++)
                          Expanded(
                            child: Center(
                              child: dots.contains(r * 3 + c)
                                  ? Container(
                                      width: dot,
                                      height: dot,
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class PlayerPanel extends StatelessWidget {
  final int p;
  final String label;
  final bool isAi;
  final bool active;
  final bool leftSide;
  final int value;
  final VoidCallback onTap;

  const PlayerPanel({
    super.key,
    required this.p,
    required this.label,
    required this.isAi,
    required this.active,
    required this.leftSide,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = kColors[p];
    final avatar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2B1240),
            border: Border.all(color: color, width: active ? 4 : 3),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.7),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            isAi ? Icons.smart_toy : Icons.person,
            color: Colors.white70,
            size: 30,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
    final dice = Opacity(
      opacity: active ? 1 : 0.55,
      child: GestureDetector(
        onTap: onTap,
        child: DiceFace(value: value, color: color, size: 60, glow: active),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: leftSide
          ? [avatar, const SizedBox(width: 10), dice]
          : [dice, const SizedBox(width: 10), avatar],
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
  final List<int> diceVals = [0, 0, 0, 0];
  final Random rnd = Random();
  int turnIdx = 0;
  bool rolled = false;
  bool rolling = false;
  bool over = false;
  String msg = '';

  int get cur => widget.players[turnIdx];
  bool get curIsAi => widget.ai.contains(cur);
  int get dice => diceVals[cur];
  set dice(int v) => diceVals[cur] = v;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTurn());
  }

  void _startTurn() {
    if (!mounted || over) return;
    setState(() {
      dice = 0;
      msg = curIsAi ? 'Computer is playing...' : 'Tap your dice to roll';
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

  Future<void> _roll() async {
    if (!mounted || over || rolled || rolling) return;
    rolling = true;
    Sfx.play('roll');
    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted || over) return;
      setState(() => dice = rnd.nextInt(6) + 1);
    }
    final fin = rnd.nextInt(6) + 1;
    setState(() {
      dice = fin;
      rolled = true;
      rolling = false;
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

    if (captured) {
      Sfx.play('capture');
    } else if (nw == 56) {
      Sfx.play('win');
    } else {
      Sfx.play('move');
    }

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
    Sfx.play('win');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('${kNames[p]} wins!'),
        content: const Text('Congratulations!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
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

  Widget _panel(int p) {
    if (!widget.players.contains(p)) return const SizedBox(height: 80);
    final isAi = widget.ai.contains(p);
    final label = isAi
        ? 'Computer'
        : (widget.ai.isNotEmpty ? 'You' : kNames[p]);
    return PlayerPanel(
      p: p,
      label: label,
      isAi: isAi,
      active: p == cur && !over,
      leftSide: p == 0 || p == 3,
      value: diceVals[p],
      onTap: () {
        if (p == cur && !rolled && !rolling && !curIsAi && !over) _roll();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: _bgDecoration,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _panel(0),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _panel(1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF9A6236), Color(0xFF5E3719)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
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
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _panel(3),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _panel(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${kNames[cur]}'s turn  •  $msg",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Spacer(),
            ],
          ),
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

  // 3D coin-style token
  void _drawToken(Canvas canvas, Offset ctr, double r, Color color) {
    final th = r * 0.3;
    // ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: ctr + Offset(0, r * 0.95),
        width: r * 2.1,
        height: r * 0.7,
      ),
      Paint()..color = Colors.black.withOpacity(0.35),
    );
    // side (thickness)
    final side = Color.lerp(color, Colors.black, 0.5)!;
    final sidePaint = Paint()..color = side;
    canvas.drawCircle(ctr + Offset(0, th), r, sidePaint);
    canvas.drawRect(
      Rect.fromLTRB(ctr.dx - r, ctr.dy, ctr.dx + r, ctr.dy + th),
      sidePaint,
    );
    // gold rim
    final rimRect = Rect.fromCircle(center: ctr, radius: r);
    canvas.drawCircle(
      ctr,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFD9B44A), Color(0xFF8A6A1E)],
        ).createShader(rimRect),
    );
    // colored face
    final faceR = r * 0.78;
    canvas.drawCircle(
      ctr,
      faceR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.0,
          colors: [
            Color.lerp(color, Colors.white, 0.5)!,
            color,
            Color.lerp(color, Colors.black, 0.25)!,
          ],
        ).createShader(Rect.fromCircle(center: ctr, radius: faceR)),
    );
    // inner ring + center dot
    canvas.drawCircle(
      ctr,
      r * 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..color = Colors.white.withOpacity(0.85),
    );
    canvas.drawCircle(
      ctr,
      r * 0.16,
      Paint()..color = Colors.white.withOpacity(0.9),
    );
  }

  void _drawStar(Canvas canvas, Offset ctr, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -pi / 2 + i * pi / 5;
      final pt = Offset(ctr.dx + rad * cos(a), ctr.dy + rad * sin(a));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / 15;
    Rect cell(int col, int row) => Rect.fromLTWH(col * c, row * c, c, c);

    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black45
      ..strokeWidth = 1;

    canvas.drawRect(Offset.zero & size, fill..color = Colors.white);

    void home(int col, int row, Color color) {
      canvas.drawRect(
        Rect.fromLTWH(col * c, row * c, 6 * c, 6 * c),
        fill..color = color,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH((col + 1) * c, (row + 1) * c, 4 * c, 4 * c),
          Radius.circular(c * 0.4),
        ),
        fill..color = Color.lerp(color, Colors.black, 0.3)!,
      );
      for (final p in [
        [col + 2, row + 2],
        [col + 4, row + 2],
        [col + 2, row + 4],
        [col + 4, row + 4],
      ]) {
        canvas.drawCircle(
          Offset(p[0] * c, p[1] * c),
          c * 0.55,
          fill..color = Color.lerp(color, Colors.black, 0.45)!,
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

    // Safe star cells
    for (final g in kSafe) {
      if (g == 0 || g == 13 || g == 26 || g == 39) continue;
      final t = kTrack[g];
      canvas.drawRect(cell(t[0], t[1]), fill..color = const Color(0xFFC9C9C9));
      canvas.drawRect(cell(t[0], t[1]), line);
      _drawStar(
        canvas,
        Offset((t[0] + 0.5) * c, (t[1] + 0.5) * c),
        c * 0.34,
        fill..color = const Color(0xFF7A7A7A),
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

    // Tokens: draw top-to-bottom so lower tokens overlap upper ones;
    // current player's tokens last so they stay on top.
    final items = <List<dynamic>>[];
    final used = <String, int>{};
    final order = [...players.where((p) => p != current), current];
    for (final p in order) {
      for (int t = 0; t < 4; t++) {
        final g = gridPos(p, t, pos[p][t]);
        final key = '${g.dx.toStringAsFixed(1)}_${g.dy.toStringAsFixed(1)}';
        final k = used[key] ?? 0;
        used[key] = k + 1;
        final center = Offset(g.dx * c + k * c * 0.16, g.dy * c - k * c * 0.16);
        items.add([p, t, center]);
      }
    }
    items.sort((a, b) {
      final pa = a[0] == current ? 1 : 0;
      final pb = b[0] == current ? 1 : 0;
      if (pa != pb) return pa - pb;
      return (a[2] as Offset).dy.compareTo((b[2] as Offset).dy);
    });

    for (final it in items) {
      final p = it[0] as int;
      final t = it[1] as int;
      final center = it[2] as Offset;
      final isMovable = p == current && movable.contains(t);
      if (isMovable) {
        canvas.drawCircle(
          center,
          c * 0.62,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = Colors.black,
        );
        canvas.drawCircle(
          center,
          c * 0.62,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white,
        );
      }
      _drawToken(canvas, center, c * 0.4, kColors[p]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
