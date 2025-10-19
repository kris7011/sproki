import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sproki/logic/practice/practice_state.dart';

class MicPanel extends StatefulWidget {
  const MicPanel({
    super.key,
    required this.phase,
    required this.countdown,
    required this.onStart,
  });

  final PracticePhase phase;
  final int countdown;
  final Future<void> Function() onStart;

  @override
  State<MicPanel> createState() => _MicPanelState();
}

class _MicPanelState extends State<MicPanel> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.95,
    upperBound: 1.05,
  )..repeat(reverse: true);

  late final AnimationController _countdownCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void didUpdateWidget(covariant MicPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.phase == PracticePhase.countingDown &&
        widget.countdown != oldWidget.countdown) {
      _countdownCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _countdownCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = widget.phase == PracticePhase.idle ||
        widget.phase == PracticePhase.scored;
    final isCounting = widget.phase == PracticePhase.countingDown;
    final isListening = widget.phase == PracticePhase.listening;

    Widget micButton() => ScaleTransition(
          scale: _pulse,
          child: ElevatedButton.icon(
            onPressed: isIdle ? widget.onStart : null,
            icon: const Icon(Icons.mic),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
          ),
        );

    Widget countdown() => ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.2).animate(_countdownCtrl),
          child: Container(
            width: 90,
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              border: Border.all(color: Colors.indigo.shade200, width: 2),
              shape: BoxShape.circle,
            ),
            child: Text('${widget.countdown}',
                style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[700])),
          ),
        );

    Widget waveMock() => SizedBox(
          height: 64,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) {
              const bars = 16;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(bars, (i) {
                  final t = (_pulse.value * 2 * math.pi) + (i * 0.4);
                  final h = (math.sin(t).abs() * 24) + 8;
                  return Container(
                    width: 6,
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                        color: Colors.indigo[400],
                        borderRadius: BorderRadius.circular(4)),
                  );
                }),
              );
            },
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(children: [
            Text(
              isIdle
                  ? 'Tryk på mikrofonen og sig ordet højt'
                  : isCounting
                      ? 'Gør dig klar...'
                      : isListening
                          ? 'Lytter...'
                          : 'Resultat klart',
              style: TextStyle(
                  color: Colors.grey[800], fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (isCounting) countdown(),
            if (isListening) waveMock(),
            if (!isCounting && !isListening) micButton(),
          ]),
        ),
      ),
    );
  }
}
