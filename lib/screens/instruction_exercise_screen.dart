// lib/screens/instruction_exercise_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// InstructionExercise - "Tag den røde bold på stolen" type øvelser
/// FORMÅL: Træner at følge danske instruktioner + spatial forståelse
/// FUNKTIONALITET: Drag & drop, feedback, progression, (mock) TTS

class InstructionExerciseScreen extends StatefulWidget {
  const InstructionExerciseScreen({super.key});

  @override
  State<InstructionExerciseScreen> createState() =>
      _InstructionExerciseScreenState();
}

class _InstructionExerciseScreenState extends State<InstructionExerciseScreen> {
  // INSTRUKTIONS ØVELSER - Progressive sværhedsgrad
  final List<Map<String, dynamic>> _exercises = [
    {
      'instruction': 'Tag den røde bold på stolen',
      'description': 'Simpel placering',
      'objects': [
        {
          'id': 'red_ball',
          'type': 'ball',
          'color': 'rød',
          'icon': Icons.sports_soccer,
          'colorValue': Colors.red,
          'isTarget': true
        },
        {
          'id': 'blue_ball',
          'type': 'ball',
          'color': 'blå',
          'icon': Icons.sports_soccer,
          'colorValue': Colors.blue,
          'isTarget': false
        },
      ],
      'dropZones': [
        {
          'id': 'chair',
          'name': 'stolen',
          'icon': Icons.chair,
          'isTarget': true
        },
        {
          'id': 'table',
          'name': 'bordet',
          'icon': Icons.table_restaurant,
          'isTarget': false
        },
      ],
      'targetObject': 'red_ball',
      'targetZone': 'chair',
    },
    {
      'instruction': 'Put den blå kop på bordet',
      'description': 'Farve + objekt + placering',
      'objects': [
        {
          'id': 'blue_cup',
          'type': 'cup',
          'color': 'blå',
          'icon': Icons.local_cafe,
          'colorValue': Colors.blue,
          'isTarget': true
        },
        {
          'id': 'red_cup',
          'type': 'cup',
          'color': 'rød',
          'icon': Icons.local_cafe,
          'colorValue': Colors.red,
          'isTarget': false
        },
        {
          'id': 'green_ball',
          'type': 'ball',
          'color': 'grøn',
          'icon': Icons.sports_soccer,
          'colorValue': Colors.green,
          'isTarget': false
        },
      ],
      'dropZones': [
        {
          'id': 'table',
          'name': 'bordet',
          'icon': Icons.table_restaurant,
          'isTarget': true
        },
        {
          'id': 'shelf',
          'name': 'hylden',
          'icon': Icons.shelves,
          'isTarget': false
        },
      ],
      'targetObject': 'blue_cup',
      'targetZone': 'table',
    },
    {
      'instruction': 'Læg den gule bog under stolen',
      'description': 'Præposition: under',
      'objects': [
        {
          'id': 'yellow_book',
          'type': 'book',
          'color': 'gul',
          'icon': Icons.book,
          'colorValue': Colors.yellow,
          'isTarget': true
        },
        {
          'id': 'red_book',
          'type': 'book',
          'color': 'rød',
          'icon': Icons.book,
          'colorValue': Colors.red,
          'isTarget': false
        },
      ],
      'dropZones': [
        {
          'id': 'under_chair',
          'name': 'under stolen',
          'icon': Icons.keyboard_arrow_down,
          'isTarget': true
        },
        {
          'id': 'on_table',
          'name': 'på bordet',
          'icon': Icons.table_restaurant,
          'isTarget': false
        },
      ],
      'targetObject': 'yellow_book',
      'targetZone': 'under_chair',
    },
    {
      'instruction': 'Sæt den grønne kasse ved siden af lampen',
      'description': 'Kompleks spatial relation',
      'objects': [
        {
          'id': 'green_box',
          'type': 'box',
          'color': 'grøn',
          'icon': Icons.inventory_2,
          'colorValue': Colors.green,
          'isTarget': true
        },
        {
          'id': 'blue_box',
          'type': 'box',
          'color': 'blå',
          'icon': Icons.inventory_2,
          'colorValue': Colors.blue,
          'isTarget': false
        },
      ],
      'dropZones': [
        {
          'id': 'beside_lamp',
          'name': 'ved siden af lampen',
          'icon': Icons.lightbulb_outline,
          'isTarget': true
        },
        {
          'id': 'on_floor',
          'name': 'på gulvet',
          'icon': Icons.crop_square,
          'isTarget': false
        },
      ],
      'targetObject': 'green_box',
      'targetZone': 'beside_lamp',
    },
  ];

  int _currentExerciseIndex = 0;

  /// ready, playing_instruction, dragging, checking, success, error
  String _exerciseState = 'ready';

  String _feedbackMessage = '';
  int _score = 0;

  // Drag state
  String? _draggedObjectId;
  final Map<String, Offset> _objectPositions = {};

  // Nøgler/refs til koordinater og layout
  final GlobalKey _gameAreaKey = GlobalKey();

  Map<String, dynamic> get _currentExercise =>
      _exercises[_currentExerciseIndex];
  List<Map<String, dynamic>> get _currentObjects => _currentExercise['objects'];
  List<Map<String, dynamic>> get _currentDropZones =>
      _currentExercise['dropZones'];

  // Dropzone layout-konstanter (skal matche UI)
  static const double _zoneWidth = 100;
  static const double _zoneHeight = 80;
  static const double _zoneRight = 40;
  static const double _zoneTopStart = 60;
  static const double _zoneTopStep = 100;

  @override
  void initState() {
    super.initState();
    _initializeObjectPositions();
    _playInstruction();
  }

  // Startpositioner for objekter
  void _initializeObjectPositions() {
    _objectPositions.clear();
    for (int i = 0; i < _currentObjects.length; i++) {
      // Venstre side (startområde)
      _objectPositions[_currentObjects[i]['id']] =
          Offset(50.0, 100.0 + (i * 80.0));
    }
  }

  // --- (Mock) TTS ------------------------------------------------------------

  Future<void> _speakDanish(String text) async {
    if (kDebugMode) {
      // Skift til rigtig TTS senere (fx flutter_tts)
      print('🎵 Speaking Danish: "$text"');
    }
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  Future<void> _playInstruction() async {
    setState(() {
      _exerciseState = 'playing_instruction';
      _feedbackMessage = 'Lyt til instruktionen...';
    });

    await _speakDanish(_currentExercise['instruction']);

    setState(() {
      _exerciseState = 'dragging';
      _feedbackMessage = 'Træk objektet til det rigtige sted';
    });
  }

  // --- Drag & drop -----------------------------------------------------------

  // Konverter global skærmposition → lokal position inde i game area
  Offset _toLocal(Offset globalPosition) {
    final RenderBox? box =
        _gameAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return globalPosition; // fallback
    return box.globalToLocal(globalPosition);
  }

  // Dropzone-rect i lokal koordinat for en given index
  Rect _getDropZoneRectByIndex(int index, Size areaSize) {
    final double left =
        areaSize.width - _zoneRight - _zoneWidth; // pga. Positioned(right)
    final double top = _zoneTopStart + index * _zoneTopStep;
    return Rect.fromLTWH(left, top, _zoneWidth, _zoneHeight);
  }

  // Find dropzone-rect ud fra dens id
  Rect? _getDropZoneRectById(String id, Size areaSize) {
    for (int i = 0; i < _currentDropZones.length; i++) {
      if (_currentDropZones[i]['id'] == id) {
        return _getDropZoneRectByIndex(i, areaSize);
      }
    }
    return null;
  }

  void _onObjectDragStart(String objectId) {
    setState(() {
      _draggedObjectId = objectId;
      _exerciseState = 'dragging';
    });
  }

  void _onObjectDragUpdate(String objectId, Offset globalPosition) {
    final local = _toLocal(globalPosition);
    setState(() {
      _objectPositions[objectId] = local;
    });
  }

  void _onObjectDragEnd(String objectId, Offset globalOffset) {
    final local = _toLocal(globalOffset);
    setState(() {
      _objectPositions[objectId] = local;
      _draggedObjectId = null;
    });

    // Tjek droppet position i forhold til zone
    _checkDropTarget(objectId, local);
  }

  void _checkDropTarget(String objectId, Offset localDropPosition) {
    final isCorrectObject = objectId == _currentExercise['targetObject'];

    // Hent game area størrelse
    final RenderBox? box =
        _gameAreaKey.currentContext?.findRenderObject() as RenderBox?;
    final Size areaSize = box?.size ?? const Size(400, 400);

    // Find mål-zonen (Rect) ud fra targetZone id
    final String targetZoneId = _currentExercise['targetZone'];
    final Rect? targetRect = _getDropZoneRectById(targetZoneId, areaSize);

    final bool isInTargetZone =
        targetRect?.contains(localDropPosition) ?? false;

    if (isCorrectObject && isInTargetZone) {
      _handleSuccess();
    } else {
      _handleError(objectId);
    }
  }

  Future<void> _handleSuccess() async {
    _score++;
    setState(() {
      _exerciseState = 'success';
      _feedbackMessage = _getSuccessMessage();
    });

    await _speakDanish(_feedbackMessage);

    // Auto-næste
    await Future.delayed(const Duration(seconds: 2));
    _nextExercise();
  }

  Future<void> _handleError(String objectId) async {
    setState(() {
      _exerciseState = 'error';
      _feedbackMessage = _getErrorMessage();
    });

    await _speakDanish(_feedbackMessage);

    // Reset position efter fejl
    await Future.delayed(const Duration(seconds: 1));
    _resetObjectPosition(objectId);

    setState(() {
      _exerciseState = 'dragging';
      _feedbackMessage = 'Prøv igen';
    });
  }

  void _resetObjectPosition(String objectId) {
    final objectIndex =
        _currentObjects.indexWhere((obj) => obj['id'] == objectId);
    setState(() {
      _objectPositions[objectId] = Offset(50.0, 100.0 + (objectIndex * 80.0));
    });
  }

  String _getSuccessMessage() {
    final messages = [
      'Fremragende! Du fulgte instruktionen perfekt!',
      'Super godt! Du gjorde præcis det rigtige!',
      'Fantastisk! Du forstod instruktionen!',
      'Perfekt! Du placerede det rigtigt!',
    ];
    return messages[_score % messages.length];
  }

  String _getErrorMessage() {
    final messages = [
      'Det var ikke helt rigtigt. Prøv igen.',
      'Næsten! Tjek instruktionen igen.',
      'Prøv at lytte til instruktionen igen.',
    ];
    return messages[_score % messages.length];
  }

  void _nextExercise() {
    setState(() {
      _currentExerciseIndex = (_currentExerciseIndex + 1) % _exercises.length;
      _exerciseState = 'ready';
      _feedbackMessage = '';
    });

    _initializeObjectPositions();
    _playInstruction();
  }

  void _replayInstruction() {
    _playInstruction();
  }

  // --- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text('🎮 Instruktioner'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '$_score/${_exercises.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentExerciseIndex) / _exercises.length,
            backgroundColor: Colors.orange[100],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
          ),

          Expanded(
            child: Column(
              children: [
                // Instruction card
                _buildInstructionCard(),

                // Game area
                Expanded(
                  child: _buildGameArea(),
                ),

                // Controls
                _buildControls(),

                // Feedback
                if (_feedbackMessage.isNotEmpty) _buildFeedback(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.orange[100],
          ),
          child: Column(
            children: [
              Icon(
                Icons.touch_app,
                size: 32,
                color: Colors.orange[700],
              ),
              const SizedBox(height: 8),
              Text(
                _currentExercise['instruction'],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _currentExercise['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameArea() {
    return Container(
      key: _gameAreaKey,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          // Baggrunds-grid
          _buildBackgroundGrid(),

          // Drop zones (højre side)
          ..._buildDropZones(),

          // Draggable objects (venstre side)
          ..._buildDraggableObjects(),

          // Instruction overlay
          if (_exerciseState == 'playing_instruction')
            _buildInstructionOverlay(),
        ],
      ),
    );
  }

  Widget _buildBackgroundGrid() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: GridPainter(),
      ),
    );
  }

  List<Widget> _buildDropZones() {
    return _currentDropZones.asMap().entries.map((entry) {
      final index = entry.key;
      final zone = entry.value;
      final isTargetZone = zone['isTarget'] as bool;

      return Positioned(
        right: _zoneRight,
        top: _zoneTopStart + (index * _zoneTopStep),
        child: Container(
          width: _zoneWidth,
          height: _zoneHeight,
          decoration: BoxDecoration(
            color: isTargetZone ? Colors.green[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTargetZone ? Colors.green[400]! : Colors.grey[400]!,
              width: 2,
            ),
            boxShadow: [
              if (isTargetZone)
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                zone['icon'],
                size: 32,
                color: isTargetZone ? Colors.green[700] : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                zone['name'],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isTargetZone ? Colors.green[700] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildDraggableObjects() {
    return _currentObjects.map((object) {
      final objectId = object['id'] as String;
      final position = _objectPositions[objectId] ?? Offset.zero;
      final isCurrentlyDragging = _draggedObjectId == objectId;

      return Positioned(
        left: position.dx,
        top: position.dy,
        child: Draggable<String>(
          data: objectId,
          onDragStarted: () => _onObjectDragStart(objectId),
          onDragUpdate: (details) =>
              _onObjectDragUpdate(objectId, details.globalPosition),
          onDragEnd: (details) => _onObjectDragEnd(objectId, details.offset),
          feedback: _buildObjectWidget(object, isDragging: true),
          childWhenDragging: _buildObjectWidget(object, isGhost: true),
          child: _buildObjectWidget(object, isDragging: isCurrentlyDragging),
        ),
      );
    }).toList();
  }

  Widget _buildObjectWidget(Map<String, dynamic> object,
      {bool isDragging = false, bool isGhost = false}) {
    final Color colorValue = (object['colorValue'] as Color?) ?? Colors.grey;
    final IconData icon = object['icon'] as IconData;
    final String color = object['color'] as String;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isGhost
            ? Colors.grey[300]
            : colorValue.withValues(alpha: isDragging ? 0.8 : 1.0),
        shape: BoxShape.circle,
        boxShadow: [
          if (isDragging)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          else if (!isGhost)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isGhost ? Colors.grey[500] : Colors.white,
          ),
          Text(
            color,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isGhost ? Colors.grey[500] : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.volume_up, size: 48, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Lyt til instruktionen...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    switch (_exerciseState) {
      case 'ready':
      case 'playing_instruction':
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.volume_up),
            label: const Text('Spiller instruktion...'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[400],
            ),
          ),
        );

      case 'dragging':
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _replayInstruction,
                icon: const Icon(Icons.replay),
                label: const Text('Hør igen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );

      case 'success':
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Icon(
            Icons.check_circle,
            size: 60,
            color: Colors.green[600],
          ),
        );

      case 'error':
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Icon(
            Icons.refresh,
            size: 60,
            color: Colors.red[600],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFeedback() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: _getFeedbackCardColor(),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(
                _getFeedbackIcon(),
                color: _getFeedbackTextColor(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _feedbackMessage,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getFeedbackTextColor(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getFeedbackCardColor() {
    switch (_exerciseState) {
      case 'success':
        return Colors.green[50]!;
      case 'error':
        return Colors.red[50]!;
      default:
        return Colors.blue[50]!;
    }
  }

  Color _getFeedbackTextColor() {
    switch (_exerciseState) {
      case 'success':
        return Colors.green[700]!;
      case 'error':
        return Colors.red[700]!;
      default:
        return Colors.blue[700]!;
    }
  }

  IconData _getFeedbackIcon() {
    switch (_exerciseState) {
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}

// Baggrunds-grid til game area (estetik)
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
