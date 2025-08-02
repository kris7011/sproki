/// Progress Overview Screen med komplet dansk alfabet support
/// FORMÅL: Professionel rapportering til PPR møder og logopæd konsultationer
/// FUNKTIONALITET: Detaljeret analytics, kategori performance, unlock progression

import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../models/progress_data.dart';
import '../data/words_content.dart';
import 'report_builder_screen.dart'; // NYT: Import report builder

class ProgressOverviewScreen extends StatefulWidget {
  const ProgressOverviewScreen({super.key});

  @override
  ProgressOverviewScreenState createState() => ProgressOverviewScreenState();
}

class ProgressOverviewScreenState extends State<ProgressOverviewScreen> {
  @override
  Widget build(BuildContext context) {
    final stats = ProgressService.getOverallStats();
    final allProgress = ProgressService.getAllProgress();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fremgang 📊'),
        backgroundColor: Colors.purple.shade300,
        actions: [
          // PDF Export funktion - nu fuldt funktionel!
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generer PDF Rapport',
            onPressed: () => _shareProgress(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Statistics Card - kompakte metrics for quick overview
            _buildOverallStatsCard(stats),

            const SizedBox(height: 20),

            // Category Performance - viser hvor barnet klarer sig i hver lydkategori
            _buildCategoryPerformance(allProgress),

            const SizedBox(height: 20),

            // Mastered Words - motiverende showcase af success
            _buildMasteredWords(allProgress),

            const SizedBox(height: 20),

            // Words Needing Practice - fokusområder for videre træning
            _buildWordsNeedingPractice(allProgress),

            const SizedBox(height: 20),

            // Detailed Word Breakdown - komplet ord-for-ord status
            _buildDetailedBreakdown(allProgress),
          ],
        ),
      ),
    );
  }

  /// Bygger hovedstatistik kortet med kritiske metrics
  /// OVERFLOW FIX: Reduceret fra 6 til 4 stats + øget aspect ratio for stability
  /// METRICS: Fokus på actionable data for forældre og fagpersoner
  Widget _buildOverallStatsCard(Map<String, dynamic> stats) {
    return Card(
      elevation: 6, // Højere elevation for visuelt hierarki
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header med analytics ikon for professional look
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Samlet Fremgang',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // OVERFLOW FIX: Optimeret grid layout for stabil visning på alle devices
            GridView.count(
              shrinkWrap:
                  true, // KRITISK: Forhindrer infinite expansion i Column
              physics:
                  const NeverScrollableScrollPhysics(), // Deaktiverer scroll da parent er ScrollView
              crossAxisCount: 2, // 2 kolonner optimeret for mobile viewport
              // CRITICAL FIX: childAspectRatio øget fra 2.0 → 2.8 for 40% mere højde
              // Dette eliminerer 8px overflow der opstod med tighter layout
              childAspectRatio: 2.8,

              // Spacing for bedre visual separation
              mainAxisSpacing: 8, // Vertical spacing mellem rækker
              crossAxisSpacing: 8, // Horizontal spacing mellem kolonner

              children: [
                // De 4 mest relevante metrics for PPR rapportering
                // Prioritering: Progress indicators > Success metrics > Scope
                _buildStatBox(
                  '⭐ Stjerner',
                  '${stats['totalStars']}',
                  Colors.orange,
                ),
                _buildStatBox(
                  '🏆 Mestret',
                  '${stats['masteredWords']}',
                  Colors.green,
                ),
                _buildStatBox(
                  '📊 Success',
                  '${(stats['averageSuccessRate'] * 100).round()}%',
                  Colors.purple,
                ),
                _buildStatBox('📚 Ord', '${stats['totalWords']}', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Bygger individuelle statistik bokse med overflow protection
  /// OVERFLOW LØSNING: Reduceret padding + font sizes + Flexible wrappers
  /// DESIGN: Color-coded for hurtig visual scanning
  Widget _buildStatBox(String title, String value, Color color) {
    return Container(
      // Reduceret margin/padding for at undgå overflow på små Android skærme
      // Original values forårsagede 8px overflow på F8331 device (API 26)
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(6), // REDUCERET fra 12 → 6 for tight space
      decoration: BoxDecoration(
        // withValues() bruges i stedet for deprecated withOpacity() for Flutter 3.27+
        color: color.withValues(alpha: 0.1), // Svag baggrund for læsbarhed
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)), // Subtil kant
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize:
            MainAxisSize.min, // Minimerer column højde for compact layout
        children: [
          // Flexible er KRITISK for overflow prevention
          // Tillader text at shrink hvis container bliver for lille
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14, // REDUCERET fra 18 → 14 for at passe i container
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1, // Forhindrer line wrapping
              overflow: TextOverflow.ellipsis, // Graceful degradation
            ),
          ),
          const SizedBox(height: 1), // MINIMAL spacing da hver pixel tæller
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 8, // REDUCERET fra 10 → 8 for garanteret plads
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Tillader wrapping for længere labels
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Bygger kategori performance overview med alfabetisk progression
  /// FORMÅL: Viser hvor barnet klarer sig i hver lydkategori for målrettet træning
  /// OUTPUT: Progress bars + mastery ratios per kategori
  Widget _buildCategoryPerformance(List<ProgressData> allProgress) {
    // Grupperer progress data efter kategori for analyse
    final categories = <String, List<ProgressData>>{};

    for (final progress in allProgress) {
      final word = initialWords.firstWhere((w) => w.id == progress.wordId);
      categories.putIfAbsent(word.category, () => []).add(progress);
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance pr. Kategori',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Dynamisk liste af alle kategorier med performance metrics
            ...categories.entries.map((entry) {
              final categoryName = entry.key;
              final categoryProgress = entry.value;

              // Beregner gennemsnitlig success rate for kategorien
              final avgSuccessRate = categoryProgress.isEmpty
                  ? 0.0
                  : categoryProgress
                            .map((p) => p.successRate)
                            .reduce((a, b) => a + b) /
                        categoryProgress.length;

              // Tæller antal mestrede ord i kategorien
              final masteredCount = categoryProgress
                  .where((p) => p.isMastered)
                  .length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori header med mastery ratio
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _getCategoryDisplayName(categoryName),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '$masteredCount/${categoryProgress.length} mestret',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Visual progress bar med color coding
                    LinearProgressIndicator(
                      value: avgSuccessRate,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        avgSuccessRate >= 0.8 ? Colors.green : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Numerisk success rate for præcision
                    Text(
                      '${(avgSuccessRate * 100).round()}% success rate',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Viser alle mestrede ord som achievements for motivering
  /// DESIGN: Badge-style layout med stjerner for visual reward
  /// EMPTY STATE: Motiverende besked hvis ingen ord mestret endnu
  Widget _buildMasteredWords(List<ProgressData> allProgress) {
    final masteredWords = allProgress.where((p) => p.isMastered).toList();

    // Empty state: Motiverende design når ingen ord mestret endnu
    if (masteredWords.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.emoji_events, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Ingen ord mestret endnu',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Text(
                'Bliv ved med at øve!',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Achievement header med trophy ikon
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Mestring! 🏆 (${masteredWords.length} ord)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Wrap layout af mestrede ord som badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: masteredWords.map((progress) {
                final word = initialWords.firstWhere(
                  (w) => w.id == progress.wordId,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(word.emoji),
                      const SizedBox(width: 4),
                      Text(word.word),
                      const SizedBox(width: 4),
                      // Viser optjente stjerner for visual achievement
                      ...List.generate(
                        progress.stars,
                        (index) => const Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Identificerer ord der har brug for mere træning
  /// ALGORITME: Filtrerer ord med lav success rate og prioriterer efter sværhedsgrad
  /// FORMÅL: Giver forældre konkrete fokusområder for næste træningssession
  Widget _buildWordsNeedingPractice(List<ProgressData> allProgress) {
    // Filtrerer og sorterer ord der har brug for mere træning
    final needsPractice =
        allProgress.where((p) => !p.isMastered && p.totalAttempts > 0).toList()
          ..sort(
            (a, b) => a.successRate.compareTo(b.successRate),
          ); // Laveste success rate først

    if (needsPractice.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header med workout ikon for "trænings" tema
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Fokusområder 💪 ($needsPractice.length ord)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Viser top 5 ord der har brug for træning
            ...needsPractice.take(5).map((progress) {
              final word = initialWords.firstWhere(
                (w) => w.id == progress.wordId,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(word.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            word.word,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${progress.successfulAttempts}/${progress.totalAttempts} (${(progress.successRate * 100).round()}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Difficulty indicator badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: progress.successRate < 0.5
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        progress.successRate < 0.5 ? 'Svær' : 'Øv mere',
                        style: TextStyle(
                          fontSize: 10,
                          color: progress.successRate < 0.5
                              ? Colors.red.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Komplet ord-for-ord breakdown for detaljeret analyse
  /// FORMÅL: Giver fagpersoner granular indsigt i barnets progress
  /// LAYOUT: Listformat med progress bars og success metrics
  Widget _buildDetailedBreakdown(List<ProgressData> allProgress) {
    if (allProgress.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Ingen data endnu - start med at øve nogle ord!'),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detaljeret Oversigt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Komplet liste af alle ord med progress data
            ...allProgress.map((progress) {
              final word = initialWords.firstWhere(
                (w) => w.id == progress.wordId,
              );
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(
                    word.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(word.word),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${progress.successfulAttempts}/${progress.totalAttempts} forsøg',
                      ),
                      const SizedBox(height: 4),
                      // Progress bar med color coding baseret på mastery status
                      LinearProgressIndicator(
                        value: progress.successRate,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress.isMastered ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Viser stjerner hvis optjent
                      if (progress.stars > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            progress.stars,
                            (index) => const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 16,
                            ),
                          ),
                        ),
                      Text(
                        '${(progress.successRate * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Konverterer kategori ID til brugervenlige danske navne med ikoner
  /// FORMÅL: Professionel præsentation af kategorier i analytics for logopæder/PPR
  /// STRUKTUR: Organiseret efter læringsprogression med visuelle ikoner og eksempler
  String _getCategoryDisplayName(String category) {
    switch (category) {
      // FUNDAMENTALE VOKALER (Tier 0 - Starter ord altid tilgængelige)
      case 'a-sounds':
        return '🅰️ A-lyde (and, arm, baby)';
      case 'e-sounds':
        return '🅴 E-lyde (elefant, te, se)';
      case 'i-sounds':
        return '🅸 I-lyde (is, tiger, dit)';
      case 'o-sounds':
        return '🅾️ O-lyde (ord, bro)';
      case 'u-sounds':
        return '🆄 U-lyde (ugle, bus, hus)';

      // LETTE KONSONANTER (Tier 1 - Låses op fra vokal mastery)
      case 'b-sounds':
        return '🅱️ B-lyde (bold, bord, bog)';
      case 'd-sounds':
        return '🅳 D-lyde (dør, dukke, dans)';
      case 'm-sounds':
        return '🅼 M-lyde (mor, mælk, måne)';
      case 'n-sounds':
        return '🅽 N-lyde (næse, nat, nål)';
      case 'p-sounds':
        return '🅿️ P-lyde (pige, pizza, papir)';
      case 't-sounds':
        return '🆃 T-lyde (tog, tand, top)';

      // KOMPLEKSE KONSONANTER (Tier 2 - Ofte problematiske i sprogudvikling)
      case 's-sounds':
        return '🅢 S-lyde (sol, sko, slange)';
      case 'r-sounds':
        return '🅡 R-lyde (rød, rose, radio)';
      case 'l-sounds':
        return '🅛 L-lyde (lys, løve, lukke)';
      case 'f-sounds':
        return '🅕 F-lyde (fire, fugl, frugt)';
      case 'v-sounds':
        return '🅥 V-lyde (vand, bil, vejr)';
      case 'k-sounds':
        return '🅚 K-lyde (ko, kage, kylling)';
      case 'g-sounds':
        return '🅖 G-lyde (gul, gave, glas)';

      // DANSKE SPECIALVOKALER (Tier 3 - Unikke for dansk sprog)
      case 'æ-sounds':
        return '🇩🇰 Æ-lyde (æble, læge, træ)';
      case 'ø-sounds':
        return '🇩🇰 Ø-lyde (ørn, ø, grød)';
      case 'å-sounds':
        return '🇩🇰 Å-lyde (åben, kål, år)';

      // TEMATISKE KATEGORIER (Tier 4 - Kontekstuel læring gennem kategorier)
      case 'animals':
        return '🐾 Dyr (kat, hund, fisk)';
      case 'food':
        return '🍎 Mad (brød, ost)';

      // AVANCEREDE KOMBINATIONER (Tier 5 - Højeste sværhedsgrad)
      case 'advanced':
        return '⭐ Avanceret (frost, skrig, storm)';

      // Fallback for eventuelle ukendte kategorier
      default:
        return category;
    }
  }

  /// Åbner Report Builder for professional PDF generation
  /// UPGRADE: Nu fuldt funktionel i stedet for placeholder
  void _shareProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportBuilderScreen(
          childName: 'Dit Barn', // TODO: Få actual barn navn fra app settings
        ),
      ),
    );
  }
}
