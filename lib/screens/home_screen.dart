/// HomeScreen med KORREKT TabController configuration
/// CRITICAL FIX: TabController length (25) matcher antal tabs (25) og TabBarView children (25)
/// FEJL HISTORIE: Tidligere mismatch forårsagede "Controller's length property does not match" crash

import 'package:flutter/material.dart';
import '../data/words_content.dart';
import '../services/progress_service.dart';
import '../services/unlock_service.dart';
import '../widgets/word_card.dart';
import 'progress_overview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showLockedWords = false; // Toggle til at vise/skjule låste ord

  @override
  void initState() {
    super.initState();
    ProgressService.initialize();

    // CRITICAL FIX: EKSAKT 25 tabs defineret nedenfor - dette TAL skal matche!
    // TAB OVERSIGT: 1 Alle + 5 vokaler + 6 konsonanter + 7 komplekse + 3 danske + 2 kategorier + 1 avanceret = 25
    _tabController = TabController(length: 25, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ProgressService.getOverallStats();
    final unlockedWords = UnlockService.getUnlockedWords();
    final lockedWords = UnlockService.getLockedWords();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sproki 🗣️'),
        backgroundColor: Colors.blue.shade300,
        actions: [
          // Toggle for låste ord - vigtig for forældre at se progression
          IconButton(
            icon: Icon(_showLockedWords ? Icons.lock_open : Icons.lock),
            onPressed: () {
              setState(() {
                _showLockedWords = !_showLockedWords;
              });
            },
            tooltip: _showLockedWords ? 'Skjul låste ord' : 'Vis låste ord',
          ),
          // Analytics navigation for professionel rapportering
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProgressOverviewScreen(),
                ),
              );
            },
          ),
        ],

        // KOMPLETTE TAB STRUKTUR: PRÆCIS 25 TABS (matcher TabController length: 25)
        bottom: TabBar(
          controller: _tabController,
          isScrollable:
              true, // VIGTIGT: Tillader horizontal scroll gennem alle 25 kategorier
          tabs: const [
            // TAB 1: ALLE ORD OVERSIGT
            Tab(text: 'Alle', icon: Icon(Icons.apps)),

            // TABS 2-6: FUNDAMENTALE VOKALER (Tier 0 - Starter ord)
            Tab(
              text: 'A-lyde',
              icon: Text('A', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              text: 'E-lyde',
              icon: Text('E', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              text: 'I-lyde',
              icon: Text('I', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              text: 'O-lyde',
              icon: Text('O', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              text: 'U-lyde',
              icon: Text('U', style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            // TABS 7-12: LETTE KONSONANTER (Tier 1)
            Tab(
              text: 'B-lyde',
              icon: Text('B', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              text: 'D-lyde',
              icon: Text('D', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              text: 'M-lyde',
              icon: Text('M', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              text: 'N-lyde',
              icon: Text('N', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              text: 'P-lyde',
              icon: Text('P', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              text: 'T-lyde',
              icon: Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            // TABS 13-19: KOMPLEKSE KONSONANTER (Tier 2)
            Tab(
              text: 'S-lyde',
              icon: Text(
                'S',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            Tab(
              text: 'R-lyde',
              icon: Text(
                'R',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            Tab(
              text: 'L-lyde',
              icon: Text(
                'L',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            Tab(
              text: 'F-lyde',
              icon: Text('F', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              text: 'V-lyde',
              icon: Text('V', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              text: 'K-lyde',
              icon: Text('K', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              text: 'G-lyde',
              icon: Text('G', style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            // TABS 20-22: DANSKE SPECIALVOKALER (Tier 3)
            Tab(
              text: 'Æ-lyde',
              icon: Text(
                'Æ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            Tab(
              text: 'Ø-lyde',
              icon: Text(
                'Ø',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            Tab(
              text: 'Å-lyde',
              icon: Text(
                'Å',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),

            // TABS 23-24: TEMATISKE KATEGORIER (Tier 4)
            Tab(
              text: 'Dyr',
              icon: Icon(Icons.pets, color: Colors.green),
            ),
            Tab(
              text: 'Mad',
              icon: Icon(Icons.restaurant, color: Colors.orange),
            ),

            // TAB 25: AVANCEREDE KOMBINATIONER (Tier 5)
            Tab(
              text: 'Avanceret',
              icon: Icon(Icons.star, color: Colors.purple),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // PROGRESS OVERVIEW MED UNLOCK STATUS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                // Hovedstatistikker - fokus på actionable metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      '⭐',
                      stats['totalStars'].toString(),
                      'Stjerner',
                    ),
                    _buildStatItem(
                      '🏆',
                      stats['masteredWords'].toString(),
                      'Mestret',
                    ),
                    _buildStatItem(
                      '🔓',
                      unlockedWords.length.toString(),
                      'Unlocked',
                    ),
                    _buildStatItem(
                      '📊',
                      '${(stats['averageSuccessRate'] * 100).round()}%',
                      'Success',
                    ),
                  ],
                ),
                // Motiverende unlock status besked
                if (lockedWords.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '🔐 ${lockedWords.length} ord venter på at blive låst op!',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // HOVEDINDHOLD: TabBarView med PRÆCIS 25 CHILDREN (matcher TabController length og tabs antal)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // CHILD 1: ALLE ORD (komplet oversigt)
                _buildWordGrid(_getWordsToShow(initialWords)),

                // CHILDREN 2-6: FUNDAMENTALE VOKALER
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'a-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'e-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'i-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'o-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'u-sounds')
                        .toList(),
                  ),
                ),

                // CHILDREN 7-12: LETTE KONSONANTER
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'b-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'd-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'm-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'n-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'p-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 't-sounds')
                        .toList(),
                  ),
                ),

                // CHILDREN 13-19: KOMPLEKSE KONSONANTER
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 's-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'r-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'l-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'f-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'v-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'k-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'g-sounds')
                        .toList(),
                  ),
                ),

                // CHILDREN 20-22: DANSKE SPECIALVOKALER
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'æ-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'ø-sounds')
                        .toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'å-sounds')
                        .toList(),
                  ),
                ),

                // CHILDREN 23-24: TEMATISKE KATEGORIER
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords.where((w) => w.category == 'animals').toList(),
                  ),
                ),
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords.where((w) => w.category == 'food').toList(),
                  ),
                ),

                // CHILD 25: AVANCEREDE KOMBINATIONER
                _buildWordGrid(
                  _getWordsToShow(
                    initialWords
                        .where((w) => w.category == 'advanced')
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Filtrerer ord baseret på unlock status og bruger preference
  /// LOGIC: Hvis _showLockedWords er false, vis kun unlocked ord
  /// Hvis _showLockedWords er true, vis alle ord (med lock indicators)
  List<WordContent> _getWordsToShow(List<WordContent> words) {
    if (_showLockedWords) {
      return words; // Vis alle ord med lock indicators
    } else {
      // Vis kun unlocked ord for mindre overvældende UI
      return words
          .where((word) => UnlockService.isWordUnlocked(word.id))
          .toList();
    }
  }

  /// Bygger responsive word grid med intelligent empty state handling
  /// PERFORMANCE: Lazy loading med GridView.builder for store datasæt
  /// UX: Meaningful empty states baseret på lock status
  Widget _buildWordGrid(List<WordContent> words) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: words.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Ingen ord tilgængelige endnu',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mestrer flere ord for at låse nye op!',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : GridView.builder(
              // RESPONSIVE GRID: Optimeret for mobile viewing
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    2, // 2 kolonner passer på de fleste mobile enheder
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio:
                    0.85, // Lidt højere cards for bedre content fit
              ),
              itemCount: words.length,
              itemBuilder: (context, index) {
                final word = words[index];
                final progress = ProgressService.getProgress(word.id);
                return WordCard(
                  word: word,
                  progress: progress,
                  showLocked:
                      _showLockedWords, // Pass lock visibility preference
                );
              },
            ),
    );
  }

  /// Bygger kompakte statistik items for header overview
  /// DESIGN: Emoji + værdi + label for hurtig scanning af status
  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
