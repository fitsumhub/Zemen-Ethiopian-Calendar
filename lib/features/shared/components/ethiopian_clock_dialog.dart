import 'dart:async';
import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../../core/calendar/ethiopian_time_converter.dart';

class EthiopianClockDialog extends StatefulWidget {
  const EthiopianClockDialog({super.key});

  @override
  State<EthiopianClockDialog> createState() => _EthiopianClockDialogState();
}

class _EthiopianClockDialogState extends State<EthiopianClockDialog> {
  bool _isLive = true;
  bool _useGeezNumerals = true;
  double _manualHour = 12.0;
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isLive && mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int gHour = _isLive ? _now.hour : _manualHour.toInt();
    final int gMin = _isLive ? _now.minute : 0;
    final int gSec = _isLive ? _now.second : 0;

    final ethTime = EthiopianTimeConverter.gregorianToEthiopian(gHour, gMin);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.access_time, color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('የኢትዮጵያ ሰዓት', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Ethiopian 12-Hour Clock', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Analog Clock Face Canvas
              SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _ClockPainter(
                    ethHour: ethTime.hour,
                    minute: ethTime.minute,
                    second: gSec,
                    isDaytime: ethTime.isDaytime,
                    useGeez: _useGeezNumerals,
                    primaryColor: theme.colorScheme.primary,
                    surfaceColor: theme.colorScheme.surfaceContainerHighest,
                    textColor: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Digital Clock Display Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: ethTime.isDaytime
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                      : const Color(0xFF1E3A8A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ethTime.isDaytime ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ethTime.isDaytime ? Icons.wb_sunny : Icons.nightlight_round,
                      size: 20,
                      color: ethTime.isDaytime ? const Color(0xFFF59E0B) : const Color(0xFF60A5FA),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${ethTime.period.amharic} ${ethTime.hour}:${ethTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${ethTime.isDaytime ? "ቀን" : "ሌሊት"})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ethTime.isDaytime ? const Color(0xFFB45309) : const Color(0xFF93C5FD),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Gregorian Counterpart
              Text(
                'ግሪጎሪያን: ${gHour.toString().padLeft(2, '0')}:${gMin.toString().padLeft(2, '0')}:${gSec.toString().padLeft(2, '0')} (24h Standard)',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),

              // Controls: Ge'ez Numeral Toggle & Live/Scrub Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilterChip(
                    selected: _useGeezNumerals,
                    label: Text(_useGeezNumerals ? 'ግዕዝ አኃዝ (፩..፲፪)' : 'የአረብኛ አኃዝ (1..12)'),
                    onSelected: (val) => setState(() => _useGeezNumerals = val),
                  ),
                  FilterChip(
                    selected: _isLive,
                    label: Text(_isLive ? '🟢 ቀጥታ (Live)' : '⏱️ በእጅ (Manual)'),
                    onSelected: (val) {
                      setState(() {
                        _isLive = val;
                      });
                    },
                  ),
                ],
              ),

              if (!_isLive) ...[
                const SizedBox(height: 12),
                Text('የግሪጎሪያን ሰዓት ይምረጡ: ${gHour.toString().padLeft(2, '0')}:00'),
                Slider(
                  value: _manualHour,
                  min: 0,
                  max: 23,
                  divisions: 23,
                  label: '${gHour.toString().padLeft(2, '0')}:00',
                  onChanged: (val) => setState(() => _manualHour = val),
                ),
              ],

              const SizedBox(height: 14),

              // Educational Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'የኢትዮጵያ ቀን በፀሐይ መውጣት (ንጋት 12:00 / 6:00 AM) ይጀምራል። የቀትር 6:00 በዓለም አቀፍ 12:00 PM ጋር እኩል ነው።',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final int ethHour;
  final int minute;
  final int second;
  final bool isDaytime;
  final bool useGeez;
  final Color primaryColor;
  final Color surfaceColor;
  final Color textColor;

  _ClockPainter({
    required this.ethHour,
    required this.minute,
    required this.second,
    required this.isDaytime,
    required this.useGeez,
    required this.primaryColor,
    required this.surfaceColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Dial Background
    final dialPaint = Paint()
      ..color = isDaytime ? const Color(0xFF1E293B) : const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dialPaint);

    // Outer rim
    final rimPaint = Paint()
      ..color = isDaytime ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 2, rimPaint);

    // Inner tick circle
    final tickPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 12; i++) {
      final angle = i * (math.pi / 6) - (math.pi / 2);
      final p1 = Offset(center.dx + (radius - 12) * math.cos(angle), center.dy + (radius - 12) * math.sin(angle));
      final p2 = Offset(center.dx + (radius - 5) * math.cos(angle), center.dy + (radius - 5) * math.sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }

    // 2. Draw Numerals (1 to 12)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const geezNumbers = ['፲፪', '፩', '፪', '፫', '፬', '፭', '፮', '፯', '፰', '፱', '፲', '፲፩'];

    for (int i = 0; i < 12; i++) {
      // 0 is 12 o'clock (top)
      final angle = i * (math.pi / 6) - (math.pi / 2);
      final numStr = useGeez ? geezNumbers[i] : (i == 0 ? '12' : '$i');

      textPainter.text = TextSpan(
        text: numStr,
        style: TextStyle(
          color: (i == 0 || i == 6) ? const Color(0xFFF59E0B) : Colors.white,
          fontSize: useGeez ? 13 : 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      final numPos = Offset(
        center.dx + (radius - 24) * math.cos(angle) - textPainter.width / 2,
        center.dy + (radius - 24) * math.sin(angle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, numPos);
    }

    // 3. Hour Hand
    final hourAngle = ((ethHour % 12) + minute / 60.0) * (math.pi / 6) - (math.pi / 2);
    final hourHandPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final hourEnd = Offset(center.dx + (radius * 0.5) * math.cos(hourAngle), center.dy + (radius * 0.5) * math.sin(hourAngle));
    canvas.drawLine(center, hourEnd, hourHandPaint);

    // 4. Minute Hand
    final minAngle = (minute + second / 60.0) * (math.pi / 30) - (math.pi / 2);
    final minHandPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final minEnd = Offset(center.dx + (radius * 0.72) * math.cos(minAngle), center.dy + (radius * 0.72) * math.sin(minAngle));
    canvas.drawLine(center, minEnd, minHandPaint);

    // 5. Second Hand
    final secAngle = second * (math.pi / 30) - (math.pi / 2);
    final secHandPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final secEnd = Offset(center.dx + (radius * 0.82) * math.cos(secAngle), center.dy + (radius * 0.82) * math.sin(secAngle));
    canvas.drawLine(center, secEnd, secHandPaint);

    // Center pivot
    final pivotPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(center, 4, pivotPaint);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) {
    return oldDelegate.ethHour != ethHour ||
        oldDelegate.minute != minute ||
        oldDelegate.second != second ||
        oldDelegate.useGeez != useGeez;
  }
}
