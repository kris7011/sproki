/// WordPracticeScreen med klikbart billede for genafspilning
/// UX FORBEDRING: Billedet er nu primære interaction point for at høre ordet
/// VISUAL FEEDBACK: Border, shadow og animation indikerer interaktivitet

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:sproki/services/progress_service.dart';
import '../features/speech_practice/application/speech_bloc.dart';
import '../features/speech_practice/data/device_speech_recognition_gateway.dart';
import '../features/speech_practice/domain/speech_recognition_gateway.dart';
import 'package:sproki/services/tts_service.dart';
import 'package:sproki/services/unlock_service.dart';
import 'package:sproki/widgets/unlock_animation.dart';
import 'package:sproki/widgets/celebration_widget.dart';
import '../data/words_content.dart';

class WordPracticeScreen extends StatefulWidget {
  final WordContent word;
  final SpeechRecognitionGateway? speechGateway;

  const WordPracticeScreen({
    super.key,
    required this.word,
    this.speechGateway,
  });

  @override
  WordPracticeScreenState createState() => WordPracticeScreenState();
}

class WordPracticeScreenState extends State<WordPracticeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController
  _imageAnimationController; // NYT: For billede interaktion
  late Animation<double> _scaleAnimation;
  late Animation<double> _imageScaleAnimation; // NYT: For billede scale effect
  late Animation<double>
  _imageBounceAnimation; // NYT: For billede bounce effect

  late final SpeechBloc _speechBloc = SpeechBloc(
    gateway: widget.speechGateway ?? const DeviceSpeechRecognitionGateway(),
    targetWord: widget.word.word,
  );
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();

    // Eksisterende mikrofon animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // NYT: Billede interaktion animation controller
    // FORMÅL: Giver visual feedback når børn trykker på billedet
    _imageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Scale animation for tap feedback (billede bliver lidt større når trykket)
    _imageScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _imageAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Bounce animation for playful feedback (let bounce når trykket)
    _imageBounceAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _imageAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SpeechBloc, SpeechState>(
      bloc: _speechBloc,
      listener: (context, state) {
        if (state is SpeechStarting || state is SpeechListening) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }

        if (state is SpeechMatched) {
          _showFeedback(true);
        } else if (state is SpeechNoInput) {
          _showFeedback(false);
        } else if (state is SpeechUnavailable) {
          _showError('Mikrofon ikke tilgængelig');
        } else if (state is SpeechFailure) {
          _showError('Stemmegenkendelse kunne ikke startes');
        }
      },
      child: CelebrationWidget(
        show: _showCelebration,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Øv: ${widget.word.word}'),
          backgroundColor: Colors.green.shade300,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // KLIKBART BILLEDE MED VISUAL FEEDBACK
                // DESIGN RATIONALE: Intuitivt for børn at trykke på billede for at høre ordet
                // VISUAL CUES: Border, shadow og animationer indikerer interaktivitet
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _scaleAnimation,
                    _imageScaleAnimation,
                    _imageBounceAnimation,
                  ]),
                  builder: (context, child) {
                    return Transform.translate(
                      // Subtle bounce effect ved tryk for playful feedback
                      offset: Offset(0, -_imageBounceAnimation.value),
                      child: Transform.scale(
                        // Kombinerer mikrofon scale med billede interaktion scale
                        scale:
                            _scaleAnimation.value * _imageScaleAnimation.value,
                        child: GestureDetector(
                          // PRIMÆR INTERAKTION: Tryk på billede for at høre ordet
                          onTap: _playWord,
                          // Visual feedback ved tryk start
                          onTapDown: (_) {
                            _imageAnimationController.forward();
                          },
                          // Visual feedback ved tryk slut
                          onTapUp: (_) {
                            _imageAnimationController.reverse();
                          },
                          onTapCancel: () {
                            _imageAnimationController.reverse();
                          },
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              // Gradient baggrund for premium look
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue.shade50,
                                  Colors.blue.shade100,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),

                              // VISUAL FEEDBACK: Animeret border der indikerer interaktivitet
                              border: Border.all(
                                color: _imageAnimationController.isAnimating
                                    ? Colors
                                          .blue
                                          .shade400 // Aktiv farve ved tryk
                                    : Colors
                                          .blue
                                          .shade200, // Normal border farve
                                width: _imageAnimationController.isAnimating
                                    ? 4
                                    : 3,
                              ),

                              // SHADOW FEEDBACK: Dybere shadow ved tryk for "pressed" effect
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius:
                                      _imageAnimationController.isAnimating
                                      ? 15
                                      : 8,
                                  spreadRadius:
                                      _imageAnimationController.isAnimating
                                      ? 3
                                      : 1,
                                  offset: Offset(
                                    0,
                                    _imageAnimationController.isAnimating
                                        ? 2
                                        : 4,
                                  ),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize
                                  .min, // CRITICAL FIX: Minimerer column størrelse
                              children: [
                                // Hoved emoji/billede
                                Text(
                                  widget.word.emoji,
                                  style: const TextStyle(
                                    fontSize: 76,
                                  ), // REDUCERET fra 80 → 76
                                ),
                                const SizedBox(
                                  height: 6,
                                ), // REDUCERET fra 8 → 6
                                // INTERAKTIVITET HINT: Lille volume ikon for at indikere lydafspilning
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ), // REDUCERET padding
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.volume_up,
                                        size: 14, // REDUCERET fra 16 → 14
                                        color: Colors.blue.shade600,
                                      ),
                                      const SizedBox(
                                        width: 3,
                                      ), // REDUCERET fra 4 → 3
                                      Text(
                                        'Tryk for lyd',
                                        style: TextStyle(
                                          fontSize: 9, // REDUCERET fra 10 → 9
                                          color: Colors.blue.shade600,
                                          fontWeight: FontWeight.w500,
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
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Ordet (nu større og mere prominent)
                Text(
                  widget.word.word,
                  style: TextStyle(
                    fontSize: 44, // Øget fra 40 for bedre visibility
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),

                const SizedBox(height: 30),

                // Instruktioner (opdateret for ny interaktion)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        'Tryk på billedet for at høre "${widget.word.word}"',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tryk derefter på mikrofonen og sig ordet højt',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Microphone controls render the Bloc state directly.
                BlocBuilder<SpeechBloc, SpeechState>(
                  bloc: _speechBloc,
                  builder: (context, state) {
                    final isActive =
                        state is SpeechStarting || state is SpeechListening;
                    final transcript = state is SpeechListening
                        ? state.transcript
                        : '';

                    return Column(
                      children: [
                        Semantics(
                          button: true,
                          label: isActive
                              ? 'Stop stemmegenkendelse'
                              : 'Start stemmegenkendelse',
                          child: GestureDetector(
                            onTap: _toggleListening,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.red : Colors.green,
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isActive ? Icons.stop : Icons.mic,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        if (isActive)
                          Column(
                            children: [
                              const Text(
                                'Lytter...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                              if (transcript.isNotEmpty)
                                Text(
                                  'Jeg hørte: "$transcript"',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                        if (state is SpeechNotMatched)
                          const Text('Prøv igen – ordet blev ikke genkendt.'),
                        const SizedBox(height: 30),
                      ],
                    );
                  },
                ),

                // FJERNET: "Hør ordet igen" knap da funktionaliteten nu er i billedet
                // Dette giver et cleaner interface med færre knapper
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  /// Afspiller ordet med enhanced visual feedback
  /// FORBEDRING: Nu trigges fra billede tap i stedet for separat knap
  /// ANIMATION: Kombinerer eksisterende animation med ny billede feedback
  void _playWord() async {
    if (kDebugMode) {
      print('Playing word from image tap: ${widget.word.word}');
    }

    // Kombineret animation: Mikrofon scale + billede bounce
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Afspil ordet med text-to-speech (uændret funktionalitet)
    await TTSService.speak(widget.word.word);

    // Tjek om widget stadig er mounted før context brug
    if (!mounted) return;

    // Enhanced visual feedback med øget varighed for bedre noticeability
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              '🔊 "${widget.word.word}"',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        backgroundColor: Colors.blue, // Ændret fra orange for konsistens
        duration: const Duration(seconds: 2), // Øget fra 1 til 2 sekunder
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// The Bloc owns microphone operations, timeouts and transcript state.
  void _toggleListening() {
    _speechBloc.add(
      _speechBloc.isRecording
          ? const SpeechStopRequested()
          : const SpeechStartRequested(),
    );
  }

  /// Error display helper (uændret)
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Feedback dialog med unlock system (uændret funktionalitet)
  /// BEHOLD: Denne komplekse feedback system fungerer perfekt
  void _showFeedback(bool success) async {
    if (!mounted) return;

    // Gem progress data
    await ProgressService.recordAttempt(
      wordId: widget.word.id,
      targetWord: widget.word.word,
      wasSuccessful: success,
      accuracyScore: success ? 1.0 : 0.0,
    );

    if (!mounted) return;

    // Tjek om ordet lige er blevet mestret
    final progress = ProgressService.getProgress(widget.word.id);
    final wasJustMastered = success && progress != null && progress.isMastered;

    // Tjek for nye unlocks
    List<WordContent> newUnlocks = [];
    if (wasJustMastered) {
      newUnlocks = UnlockService.checkNewUnlocks(widget.word.id);
    }

    final stars = progress?.stars ?? 0;
    final successRate = progress?.successRate ?? 0.0;

    // Start celebration animation for success
    if (success) {
      setState(() {
        _showCelebration = true;
      });

      // Stop celebration after a bit
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showCelebration = false;
          });
        }
      });
    }

    // Vis unlock animation først hvis der er nye unlocks
    if (newUnlocks.isNotEmpty) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UnlockAnimation(
          newlyUnlockedWords: newUnlocks,
          onAnimationComplete: () {
            Navigator.pop(context);
          },
        ),
      );

      if (!mounted) return;
    }

    // Derefter vis normal feedback dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(success ? 'Godt klaret! 🎉' : 'Prøv igen! 💪'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              success
                  ? 'Du sagde "${widget.word.word}" rigtigt!'
                  : 'Lad os prøve "${widget.word.word}" en gang til',
            ),
            if (progress != null) ...[
              const SizedBox(height: 16),
              // Vis stjerner
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Icon(
                    index < stars ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${progress.successfulAttempts}/${progress.totalAttempts} forsøg (${(successRate * 100).round()}%)',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              if (progress.isMastered)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'MESTRET! 🏆',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // Vis unlock info
              if (newUnlocks.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🔓 ${newUnlocks.length} nye ord låst op!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (success) {
                Navigator.of(context).pop(); // Tilbage til home screen
              }
            },
            child: Text(success ? 'Næste ord!' : 'Prøv igen'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_speechBloc.close());
    _animationController.dispose();
    _imageAnimationController.dispose(); // NYT: Dispose ny animation controller
    super.dispose();
  }
}
