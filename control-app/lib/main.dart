import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'machine.dart';

void main() => runApp(const ControlApp());

const background = Color(0xFF101922);
const panel = Color(0xFF1B2935);
const aqua = Color(0xFF5EDDC5);
const amber = Color(0xFFFFC06A);

class ControlApp extends StatelessWidget {
  const ControlApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Силикон · управление камерой',
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: aqua,
        brightness: Brightness.dark,
      ),
    ),
    home: const MachineScreen(),
  );
}

class MachineScreen extends StatefulWidget {
  const MachineScreen({super.key});
  @override
  State<MachineScreen> createState() => _MachineScreenState();
}

class _MachineScreenState extends State<MachineScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final machine = Machine();
  late final Ticker ticker;
  Duration previous = Duration.zero;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ticker = createTicker((elapsed) {
      final seconds = (elapsed - previous).inMicroseconds / 1000000;
      previous = elapsed;
      machine.advance(seconds.clamp(0.0, 0.1));
    })..start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) machine.stop();
  }

  @override
  void dispose() {
    ticker.dispose();
    WidgetsBinding.instance.removeObserver(this);
    machine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListenableBuilder(
        listenable: machine,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'СИЛИКОН / ВАКУУМНАЯ КАМЕРА',
                      style: TextStyle(
                        color: aqua,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Смешивание и заливка',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Chip(
                          avatar: Icon(Icons.science_outlined, size: 18),
                          label: Text('ДЕМО · без подключения к ESP32'),
                        ),
                        OutlinedButton.icon(
                          onPressed: machine.stop,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Остановить всё'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Удерживайте стрелку для наклона стакана. Отпустите, чтобы остановить.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: panel,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: AspectRatio(
                        aspectRatio: constraints.maxWidth < 600 ? 0.72 : 1.25,
                        child: LayoutBuilder(
                          builder: (context, size) => Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: MachinePainter(machine),
                                ),
                              ),
                              Positioned(
                                left: size.maxWidth * .04,
                                top: size.maxHeight * .15,
                                child: cupControls(
                                  'A',
                                  'Компонент A',
                                  machine.angleA,
                                ),
                              ),
                              Positioned(
                                left: size.maxWidth * .04,
                                top: size.maxHeight * .51,
                                child: cupControls(
                                  'B',
                                  'Смешивание',
                                  machine.angleB,
                                ),
                              ),
                              Positioned(
                                right: size.maxWidth * .04,
                                top: size.maxHeight * .10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Мешалка C',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FilledButton.tonalIcon(
                                      key: const ValueKey('mixer'),
                                      onPressed: machine.toggleMixer,
                                      icon: Icon(
                                        machine.mixing
                                            ? Icons.stop
                                            : Icons.play_arrow,
                                      ),
                                      label: Text(
                                        machine.mixing
                                            ? 'Выключить'
                                            : 'Включить',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'A → компонент B → мешалка → воронка → литейная форма',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget cupControls(String cup, String title, double angle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Стакан $cup',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      const SizedBox(height: 6),
      Text(
        '${angle.toStringAsFixed(0)}° / 90°',
        style: TextStyle(color: cup == 'A' ? aqua : amber),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HoldButton(
            key: ValueKey('$cup-ccw'),
            icon: Icons.rotate_left,
            label: 'Против часовой',
            onHold: () => machine.hold(cup, -1),
            onRelease: () => machine.release(cup),
          ),
          const SizedBox(width: 8),
          HoldButton(
            key: ValueKey('$cup-cw'),
            icon: Icons.rotate_right,
            label: 'По часовой',
            onHold: () => machine.hold(cup, 1),
            onRelease: () => machine.release(cup),
          ),
        ],
      ),
    ],
  );
}

class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onHold,
    required this.onRelease,
  });
  final IconData icon;
  final String label;
  final VoidCallback onHold, onRelease;
  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  int? pointer;
  void release() {
    if (pointer == null) return;
    pointer = null;
    widget.onRelease();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: '${widget.label} · удерживать',
    child: Semantics(
      label: widget.label,
      button: true,
      child: MouseRegion(
        onExit: (_) => release(),
        child: Listener(
          onPointerDown: (event) {
            if (pointer != null || event.buttons != 1) return;
            pointer = event.pointer;
            widget.onHold();
            setState(() {});
          },
          onPointerUp: (event) {
            if (event.pointer == pointer) release();
          },
          onPointerCancel: (event) {
            if (event.pointer == pointer) release();
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: pointer == null ? const Color(0xFF304553) : aqua,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              widget.icon,
              color: pointer == null ? Colors.white : background,
            ),
          ),
        ),
      ),
    ),
  );
}

class MachinePainter extends CustomPainter {
  MachinePainter(this.machine);
  final Machine machine;
  @override
  void paint(Canvas canvas, Size size) {
    // Uniform scaling preserves cup geometry and rotation axes on both platforms.
    final scale = math.min(size.width / 800, size.height / 640);
    canvas.translate(
      (size.width - 800 * scale) / 2,
      (size.height - 640 * scale) / 2,
    );
    canvas.scale(scale);
    final line = Paint()
      ..color = const Color(0xFF74909F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final ghost = Paint()
      ..color = const Color(0xFF304553)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(255, 35, 510, 570),
        const Radius.circular(22),
      ),
      ghost,
    );
    label(
      canvas,
      'ВАКУУМНАЯ КАМЕРА',
      const Offset(275, 52),
      Colors.white38,
      12,
    );
    cup(canvas, const Offset(350, 190), machine.angleA, aqua, 'A');
    cup(canvas, const Offset(510, 405), machine.angleB, amber, 'B');
    // Mixer shaft remains fixed: no unrequested lift axis is introduced.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(490, 238, 40, 42),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF8BA3B2),
    );
    canvas.drawLine(const Offset(510, 280), const Offset(510, 422), line);
    for (var i = 0; i < 4; i++) {
      final y = 367.0 + i * 14;
      final x =
          math.sin(machine.mixerPhase * math.pi * 2 + i * math.pi / 2) * 22;
      canvas.drawLine(
        Offset(510 - x, y),
        Offset(510 + x, y + 9),
        Paint()
          ..color = aqua
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
    final funnel = Path()
      ..moveTo(560, 485)
      ..lineTo(660, 485)
      ..lineTo(619, 531)
      ..lineTo(619, 553)
      ..lineTo(601, 553)
      ..lineTo(601, 531)
      ..close();
    canvas.drawPath(funnel, Paint()..color = const Color(0xFF304553));
    canvas.drawPath(funnel, line);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(545, 565, 130, 48),
        const Radius.circular(7),
      ),
      line,
    );
    label(canvas, 'Литейная форма', const Offset(549, 579), Colors.white70, 13);
    label(canvas, 'Воронка', const Offset(670, 500), Colors.white60, 12);
    flow(canvas, const Offset(430, 225), const Offset(462, 298));
    flow(canvas, const Offset(590, 439), const Offset(610, 472));
  }

  void cup(
    Canvas canvas,
    Offset center,
    double degrees,
    Color color,
    String name,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(degrees * math.pi / 180);
    final body = Path()
      ..moveTo(-65, -64)
      ..lineTo(-59, 62)
      ..quadraticBezierTo(0, 76, 59, 62)
      ..lineTo(65, -64);
    final fill = Path()
      ..moveTo(-61, 7)
      ..lineTo(-59, 62)
      ..quadraticBezierTo(0, 76, 59, 62)
      ..lineTo(61, 7)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: .25));
    canvas.drawPath(
      body,
      Paint()
        ..color = color
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    label(canvas, name, const Offset(-38, -43), color, 23);
    canvas.restore();
    canvas.drawCircle(center, 9, Paint()..color = background);
    canvas.drawCircle(center, 5, Paint()..color = Colors.white70);
  }

  void flow(Canvas canvas, Offset from, Offset to) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;
    canvas.drawLine(from, to, paint);
    canvas.drawLine(to, to + const Offset(-10, -9), paint);
    canvas.drawLine(to, to + const Offset(5, -12), paint);
  }

  void label(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
    double fontSize,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant MachinePainter oldDelegate) => true;
}
