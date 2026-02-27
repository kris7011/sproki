import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/sproki_service.dart';
import '../state/app_state.dart';
import 'children/children_list_screen.dart';
import 'training/training_plan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.service,
    required this.appState,
  });

  final SprokiService service;
  final AppState appState;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      ChildrenListScreen(service: widget.service),
      TrainingPlanScreen(service: widget.service),
    ];

    // Kick off background invite check AFTER we are on home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.appState.checkInviteInBackground();
    });
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? 'Børn' : 'Plan'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Log ud',
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (v) => setState(() => _index = v),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.family_restroom),
            label: 'Børn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Plan',
          ),
        ],
      ),
    );
  }
}