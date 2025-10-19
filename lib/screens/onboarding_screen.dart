import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sproki/config/env.dart';
import 'package:sproki/constants/hive_boxes.dart';
import 'package:sproki/models/child_profile.dart';
import 'package:sproki/routes/app_routes.dart';
import 'package:sproki/services/active_child_service.dart';
import 'package:sproki/services/sproki_api.dart';
import '../services/user_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  String _childName = '';
  bool _isCompleting = false;
  DateTime? _childBirthDate;

  late AnimationController _slideController;
  late AnimationController _iconController;
  late AnimationController _buttonController;

  late Animation<double> _slideAnimation;
  late Animation<double> _iconRotation;
  late Animation<double> _buttonScale;

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.waving_hand,
      title: "Velkommen til Sproki! 👋",
      description:
          "Sproki hjælper børn med sprogudvikling gennem sjove, interaktive øvelser.",
      color: Colors.blue,
      features: [
        "Eftersigelses øvelser",
        "Kategorisering spil",
        "Instruktions følgning",
        "Billede beskrivelse",
      ],
    ),
    _OnboardingSlide(
      icon: Icons.mic,
      title: "Udtale Øvelser 🎤",
      description:
          "Hør ord og gentag dem. Få feedback på din udtale og optjen stjerner!",
      color: Colors.green,
      features: ["Audio playback", "Stemme optagelse", "Feedback", "Progress"],
    ),
    _OnboardingSlide(
      icon: Icons.grid_view,
      title: "Kategorisering 🎯",
      description: "Vælg alle dyr, mad eller ting fra billeder.",
      color: Colors.purple,
      features: ["Visual læring", "Kategorisk tænkning", "Multi-selection"],
    ),
    _OnboardingSlide(
      icon: Icons.analytics,
      title: "Følg Din Fremgang 📊",
      description: "Se din udvikling, optjen stjerner og unlock udfordringer!",
      color: Colors.teal,
      features: ["Rapporter", "Achievements", "Forældre indsigt"],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _iconController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _buttonController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);

    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart));
    _iconRotation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
        CurvedAnimation(parent: _iconController, curve: Curves.elasticOut));
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut));

    _startSlideAnimation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    _iconController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _startSlideAnimation() {
    _slideController.forward();
    _iconController.forward();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _slideController.reset();
      _iconController.reset();
      setState(() => _currentPage++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _startSlideAnimation();
    } else {
      _showNameSetup();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _slideController.reset();
      _iconController.reset();
      setState(() => _currentPage--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _startSlideAnimation();
    }
  }

  void _skipToEnd() => _showNameSetup();

  Future<void> _showNameSetup() async {
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildNameSetupDialog(),
    );
    if (name != null) {
      _childName = name;
      await _completeOnboarding();
    }
  }

  Widget _buildNameSetupDialog() {
    final controller = TextEditingController(text: _childName);
    DateTime? localBirth = _childBirthDate;

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

    return StatefulBuilder(
      builder: (context, setSB) {
        return AlertDialog(
          scrollable: true,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade400],
                  ),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.child_care, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Hvad hedder dit barn?', textAlign: TextAlign.center),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Navn og fødselsdato bruges til personalisering og fremskridt.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Navn
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Barnets navn',
                  hintText: 'f.eks. Emma, Noah, Ida...',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),

              const SizedBox(height: 16),

              // Fødselsdato
              Row(
                children: [
                  Expanded(
                    child: Text(
                      localBirth == null
                          ? 'Fødselsdato: ikke valgt'
                          : 'Fødselsdato: ${fmt(localBirth!)}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final initial = localBirth ??
                          DateTime(now.year - 4, now.month, now.day);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(2000),
                        lastDate: now,
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                        helpText: 'Vælg fødselsdato',
                        cancelText: 'Annullér',
                        confirmText: 'Vælg',
                      );
                      if (picked != null) setSB(() => localBirth = picked);
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Vælg dato'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (localBirth == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vælg fødselsdato')),
                  );
                  return;
                }
                _childBirthDate = localBirth;
                Navigator.of(context).pop('Mit Barn');
              },
              child: const Text('Spring over'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim().isEmpty
                    ? 'Mit Barn'
                    : controller.text.trim();
                if (localBirth == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vælg fødselsdato')),
                  );
                  return;
                }
                _childBirthDate = localBirth;
                Navigator.of(context).pop(name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Fortsæt'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isCompleting = true);
    try {
      // 1) Markér onboarding som fuldført
      await UserService.saveChildName(_childName);
      await UserService.setOnboardingCompleted();

      // 2) Opret lokalt barn og sæt aktivt
      final childBox = Hive.box<ChildProfile>(HiveBoxes.childProfiles);
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final child = ChildProfile(
        name: _childName.trim().isEmpty ? 'Mit Barn' : _childName.trim(),
        birthDate: _childBirthDate!, // valgt i dialog
        challengeAreas: const <String>[],
        createdAt: DateTime.now(),
      );

      await childBox.put(id, child);
      await ActiveChildService.instance.setActiveChildId(id);

      // 3) Upsert til backend (best effort)
      try {
        final api = SprokiApi(baseUrl: Env.apiBaseUrl);
        await api.upsertChild(id, name: child.name);
      } catch (_) {
        // ignorer – blokér ikke onboarding
      }

      // 4) Videre til main menu – brug navngivet rute
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.mainMenu);
      }
    } catch (e) {
      setState(() => _isCompleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fejl: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleting) return _buildCompletionScreen();
    final color = _slides[_currentPage].color;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.8), color],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _slides.length,
                  itemBuilder: (_, i) => _buildSlide(_slides[i]),
                ),
              ),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Sproki Setup',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          TextButton(
              onPressed: _skipToEnd,
              child: const Text('Spring over',
                  style: TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final isSmall = h < 600;

        return AnimatedBuilder(
          animation: Listenable.merge([_slideAnimation, _iconRotation]),
          builder: (context, child) {
            return Opacity(
              opacity: _slideAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - _slideAnimation.value)),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: _iconRotation.value,
                        child: Container(
                          width: isSmall ? 90 : 120,
                          height: isSmall ? 90 : 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 3,
                            ),
                          ),
                          child: Icon(slide.icon,
                              size: isSmall ? 44 : 60, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: isSmall ? 24 : 40),
                      Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmall ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        slide.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmall ? 14 : 16,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: isSmall ? 24 : 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: slide.features.map((f) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      f,
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    final color = _slides[_currentPage].color;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final active = i == _currentPage;
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                ),
              );
            }),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tilbage-knap med scale-animation
              ScaleTransition(
                scale: _buttonScale,
                child: ElevatedButton.icon(
                  onPressed: _currentPage > 0 ? _previousPage : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Tilbage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Næste/Start-knap med scale-animation
              ScaleTransition(
                scale: _buttonScale,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _buttonController.forward().then((_) {
                      _buttonController.reverse();
                      _nextPage();
                    });
                  },
                  icon: Icon(
                    _currentPage == _slides.length - 1
                        ? Icons.check
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    _currentPage == _slides.length - 1
                        ? 'Start Sproki!'
                        : 'Næste',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B73FF), Color(0xFF9B59B6)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.check, size: 60, color: Colors.green)),
              SizedBox(height: 30),
              Text('Sproki er nu klar til brug! 🎉',
                  style: TextStyle(fontSize: 20, color: Colors.white70)),
              SizedBox(height: 40),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<String> features;
  _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.features,
  });
}
