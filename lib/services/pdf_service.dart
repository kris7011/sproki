/// PDF Service - Professionel rapport generation til PPR møder
/// FORMÅL: Objektiv dokumentation af børns sprogudvikling for fagpersoner
/// OUTPUT: Professional PDF rapporter med charts, trends og anbefalinger

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../services/progress_service.dart';
import '../models/progress_data.dart';
import '../data/words_content.dart';

class PDFService {
  /// Genererer ugentlig progress rapport til PPR/logopæd møder
  /// INDHOLD: Kategori performance, ord progression, trends, anbefalinger
  /// TARGET AUDIENCE: Professionelle fagpersoner (logopæder, PPR team)
  static Future<File> generateWeeklyReport({
    required String childName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final allProgress = ProgressService.getAllProgress();
    final stats = ProgressService.getOverallStats();

    // Filtrér progress data for dato range (simuleret - kunne udvides med real timestamps)
    final weekProgress = allProgress; // I fremtiden: filtrer på actual dates

    // Professional header og metadata
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildReportHeader(childName, startDate, endDate),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          // EXECUTIVE SUMMARY SECTION
          _buildExecutiveSummary(stats, weekProgress),
          pw.SizedBox(height: 20),

          // KATEGORI PERFORMANCE SECTION
          _buildCategoryPerformanceSection(weekProgress),
          pw.SizedBox(height: 20),

          // DETAILED PROGRESS SECTION
          _buildDetailedProgressSection(weekProgress),
          pw.SizedBox(height: 20),

          // RECOMMENDATIONS SECTION
          _buildRecommendationsSection(weekProgress),
          pw.SizedBox(height: 20),

          // UNLOCK PROGRESSION SECTION
          _buildUnlockProgressionSection(weekProgress),
        ],
      ),
    );

    return _savePDFToFile(
      pdf,
      'sproki_weekly_report_${DateFormat('yyyy_MM_dd').format(endDate)}.pdf',
    );
  }

  /// Genererer månedlig development summary for langsigtet analyse
  /// FOKUS: Trends over tid, milestone opnåelse, development trajectory
  static Future<File> generateMonthlyReport({
    required String childName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final allProgress = ProgressService.getAllProgress();
    final stats = ProgressService.getOverallStats();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildReportHeader(childName, startDate, endDate, isMonthly: true),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          // MONTHLY OVERVIEW
          _buildMonthlyOverview(stats, allProgress),
          pw.SizedBox(height: 20),

          // MILESTONE ACHIEVEMENTS
          _buildMilestoneSection(allProgress),
          pw.SizedBox(height: 20),

          // DEVELOPMENT TRENDS
          _buildTrendsSection(allProgress),
          pw.SizedBox(height: 20),

          // FUTURE GOALS SECTION
          _buildFutureGoalsSection(allProgress),
        ],
      ),
    );

    return _savePDFToFile(
      pdf,
      'sproki_monthly_report_${DateFormat('yyyy_MM').format(endDate)}.pdf',
    );
  }

  /// Genererer custom rapport baseret på bruger valg
  /// FLEXIBILITET: Tilpasset til specifikke møder eller focus areas
  static Future<File> generateCustomReport({
    required String childName,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> selectedCategories,
    required bool includeRecommendations,
    required bool includeDetailedBreakdown,
  }) async {
    final pdf = pw.Document();
    final allProgress = ProgressService.getAllProgress();
    final stats = ProgressService.getOverallStats();

    // Filtrér progress baseret på valgte kategorier
    final filteredProgress = allProgress.where((progress) {
      final word = initialWords.firstWhere((w) => w.id == progress.wordId);
      return selectedCategories.contains(word.category);
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildReportHeader(childName, startDate, endDate, isCustom: true),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          // CUSTOM SUMMARY
          _buildCustomSummary(stats, filteredProgress, selectedCategories),
          pw.SizedBox(height: 20),

          // CATEGORY FOCUS
          _buildCategoryPerformanceSection(filteredProgress),
          pw.SizedBox(height: 20),

          // CONDITIONAL SECTIONS baseret på bruger valg
          if (includeDetailedBreakdown) ...[
            _buildDetailedProgressSection(filteredProgress),
            pw.SizedBox(height: 20),
          ],

          if (includeRecommendations) ...[
            _buildRecommendationsSection(filteredProgress),
            pw.SizedBox(height: 20),
          ],
        ],
      ),
    );

    return _savePDFToFile(
      pdf,
      'sproki_custom_report_${DateFormat('yyyy_MM_dd').format(endDate)}.pdf',
    );
  }

  /// Bygger professional report header med metadata
  /// DESIGN: Professional, clean layout med vigtige identifiers
  static pw.Widget _buildReportHeader(
    String childName,
    DateTime startDate,
    DateTime endDate, {
    bool isMonthly = false,
    bool isCustom = false,
  }) {
    String reportType = 'Ugentlig Progress Rapport';
    if (isMonthly) reportType = 'Månedlig Development Summary';
    if (isCustom) reportType = 'Tilpasset Analyse Rapport';

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SPROKI SPROGTERAPI',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                reportType,
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Barn: $childName',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Periode: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Genereret: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bygger professional footer med side numre
  static pw.Widget _buildReportFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'SPROKI - Digital Sprogterapi Platform',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Side ${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Executive Summary - høj-niveau overview til busy professionals
  /// MÅLGRUPPE: Logopæder og PPR teams der skal hurtigt forstå status
  static pw.Widget _buildExecutiveSummary(
    Map<String, dynamic> stats,
    List<ProgressData> allProgress,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'EXECUTIVE SUMMARY',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSummaryMetric(
                  'Total Ord Øvet',
                  allProgress.length.toString(),
                ),
              ),
              pw.Expanded(
                child: _buildSummaryMetric(
                  'Ord Mestret',
                  '${stats['masteredWords']}',
                ),
              ),
              pw.Expanded(
                child: _buildSummaryMetric(
                  'Stjerner Optjent',
                  '${stats['totalStars']}',
                ),
              ),
              pw.Expanded(
                child: _buildSummaryMetric(
                  'Success Rate',
                  '${(stats['averageSuccessRate'] * 100).round()}%',
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            _generateExecutiveSummaryText(stats),
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// Genererer intelligent executive summary text baseret på data
  static String _generateExecutiveSummaryText(Map<String, dynamic> stats) {
    final successRate = (stats['averageSuccessRate'] * 100).round();
    final masteredWords = stats['masteredWords'] as int;

    String performance = '';
    if (successRate >= 80) {
      performance = 'Fremragende progress med høj success rate.';
    } else if (successRate >= 60) {
      performance = 'God udvikling med stabil fremgang.';
    } else {
      performance = 'Tidlig fase af træning - fortsat støtte anbefales.';
    }

    String mastery = '';
    if (masteredWords == 0) {
      mastery = 'Ingen ord fuldt mestret endnu, hvilket er normalt i starten.';
    } else if (masteredWords < 5) {
      mastery = 'Første ordmestring opnået - positiv udvikling.';
    } else {
      mastery = 'Solid mastery af flere ord demonstreret.';
    }

    return '$performance $mastery Anbefaler fortsat regelmæssig træning for optimal udvikling.';
  }

  /// Bygger individuelle summary metrics
  static pw.Widget _buildSummaryMetric(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Kategori performance section med visual charts
  static pw.Widget _buildCategoryPerformanceSection(
    List<ProgressData> allProgress,
  ) {
    // Gruppér progress efter kategori
    final categories = <String, List<ProgressData>>{};
    for (final progress in allProgress) {
      final word = initialWords.firstWhere((w) => w.id == progress.wordId);
      categories.putIfAbsent(word.category, () => []).add(progress);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'KATEGORI PERFORMANCE ANALYSE',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Kategori', isHeader: true),
                _buildTableCell('Ord Total', isHeader: true),
                _buildTableCell('Mestret', isHeader: true),
                _buildTableCell('Success Rate', isHeader: true),
                _buildTableCell('Status', isHeader: true),
              ],
            ),
            // Data rows
            ...categories.entries.map((entry) {
              final categoryName = entry.key;
              final categoryProgress = entry.value;
              final avgSuccessRate = categoryProgress.isEmpty
                  ? 0.0
                  : categoryProgress
                            .map((p) => p.successRate)
                            .reduce((a, b) => a + b) /
                        categoryProgress.length;
              final masteredCount = categoryProgress
                  .where((p) => p.isMastered)
                  .length;

              return pw.TableRow(
                children: [
                  _buildTableCell(_getCategoryDisplayName(categoryName)),
                  _buildTableCell('${categoryProgress.length}'),
                  _buildTableCell('$masteredCount'),
                  _buildTableCell('${(avgSuccessRate * 100).round()}%'),
                  _buildTableCell(_getCategoryStatus(avgSuccessRate)),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  /// Helper til table cell building
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Detaljeret progress section med ord-for-ord analyse
  static pw.Widget _buildDetailedProgressSection(
    List<ProgressData> allProgress,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DETALJERET ORD ANALYSE',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 12),
        // Gruppér ord efter performance for bedre indsigt
        ..._buildPerformanceGroups(allProgress),
      ],
    );
  }

  /// Grupperer ord efter performance niveau for actionable insights
  static List<pw.Widget> _buildPerformanceGroups(
    List<ProgressData> allProgress,
  ) {
    final mastered = allProgress.where((p) => p.isMastered).toList();
    final developing = allProgress
        .where((p) => !p.isMastered && p.successRate >= 0.5)
        .toList();
    final challenging = allProgress
        .where((p) => !p.isMastered && p.successRate < 0.5)
        .toList();

    return [
      if (mastered.isNotEmpty)
        _buildPerformanceGroup('MESTREDE ORD', mastered, PdfColors.green),
      if (developing.isNotEmpty)
        _buildPerformanceGroup('UNDER UDVIKLING', developing, PdfColors.orange),
      if (challenging.isNotEmpty)
        _buildPerformanceGroup('UDFORDRENDE ORD', challenging, PdfColors.red),
    ];
  }

  /// Bygger performance group med ord liste
  static pw.Widget _buildPerformanceGroup(
    String title,
    List<ProgressData> progressList,
    PdfColor color,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$title (${progressList.length} ord)',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 8,
            runSpacing: 4,
            children: progressList.map((progress) {
              final word = initialWords.firstWhere(
                (w) => w.id == progress.wordId,
              );
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: color),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  '${word.word} (${(progress.successRate * 100).round()}%)',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Professional recommendations baseret på data analyse
  static pw.Widget _buildRecommendationsSection(
    List<ProgressData> allProgress,
  ) {
    final recommendations = _generateRecommendations(allProgress);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PROFESSIONAL ANBEFALINGER',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.orange50,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.orange200),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: recommendations
                .map(
                  (rec) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '• ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            rec,
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  /// Genererer intelligente anbefalinger baseret på performance data
  static List<String> _generateRecommendations(List<ProgressData> allProgress) {
    final recommendations = <String>[];

    // Analyse af kategorier der kræver focus
    final categories = <String, List<ProgressData>>{};
    for (final progress in allProgress) {
      final word = initialWords.firstWhere((w) => w.id == progress.wordId);
      categories.putIfAbsent(word.category, () => []).add(progress);
    }

    // Find problematiske kategorier
    final problematicCategories = categories.entries
        .where((entry) {
          final avgSuccessRate = entry.value.isEmpty
              ? 0.0
              : entry.value.map((p) => p.successRate).reduce((a, b) => a + b) /
                    entry.value.length;
          return avgSuccessRate < 0.6;
        })
        .map((e) => e.key)
        .toList();

    if (problematicCategories.isNotEmpty) {
      recommendations.add(
        'Fokusér særligt på ${problematicCategories.map(_getCategoryDisplayName).join(', ')} da disse kategorier viser lavere success rates.',
      );
    }

    // Find ord der trænger til mere øvelse
    final challengingWords = allProgress
        .where(
          (p) => !p.isMastered && p.totalAttempts >= 3 && p.successRate < 0.5,
        )
        .take(3)
        .toList();

    if (challengingWords.isNotEmpty) {
      final wordNames = challengingWords
          .map((p) {
            final word = initialWords.firstWhere((w) => w.id == p.wordId);
            return word.word;
          })
          .join(', ');
      recommendations.add(
        'Ordene "$wordNames" kræver ekstra øvelse og kan have gavn af målrettet træning.',
      );
    }

    // Success rate baserede anbefalinger
    final overallSuccessRate = allProgress.isEmpty
        ? 0.0
        : allProgress.map((p) => p.successRate).reduce((a, b) => a + b) /
              allProgress.length;

    if (overallSuccessRate >= 0.8) {
      recommendations.add(
        'Fremragende progress! Overvej at introducere mere avancerede ord eller sætninger.',
      );
    } else if (overallSuccessRate >= 0.6) {
      recommendations.add(
        'God udvikling. Fortsæt nuværende træningsfrekvens og fokusér på konsistens.',
      );
    } else {
      recommendations.add(
        'Øg træningsfrekvens til daglige sessioner. Overvej at reducere antal ord per session for bedre fokus.',
      );
    }

    // Generelle anbefalinger
    recommendations.add(
      'Vedligehold regelmæssige 10-15 minutters sessioner for optimal læring.',
    );
    recommendations.add(
      'Celebrér små fremskridt for at opretholde motivation og engagement.',
    );

    return recommendations;
  }

  /// Månedlig overview section
  static pw.Widget _buildMonthlyOverview(
    Map<String, dynamic> stats,
    List<ProgressData> allProgress,
  ) {
    return _buildExecutiveSummary(stats, allProgress);
  }

  /// Milestone achievements section
  static pw.Widget _buildMilestoneSection(List<ProgressData> allProgress) {
    final milestones = _calculateMilestones(allProgress);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'MILESTONE OPNÅELSER',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 12),
        ...milestones
            .map(
              (milestone) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  children: [
                    pw.Text('🏆 ', style: const pw.TextStyle(fontSize: 14)),
                    pw.Text(milestone, style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  /// Beregner opnåede milestones
  static List<String> _calculateMilestones(List<ProgressData> allProgress) {
    final milestones = <String>[];
    final masteredCount = allProgress.where((p) => p.isMastered).length;

    if (masteredCount >= 1) milestones.add('Første ord mestret');
    if (masteredCount >= 5) milestones.add('5 ord mestret');
    if (masteredCount >= 10) milestones.add('10 ord mestret');
    if (masteredCount >= 20) {
      milestones.add('20 ord mestret - fremragende progress!');
    }

    final totalStars = allProgress.fold(0, (sum, p) => sum + p.stars);
    if (totalStars >= 10) milestones.add('10 stjerner optjent');
    if (totalStars >= 25) milestones.add('25 stjerner optjent');

    return milestones.isEmpty
        ? ['Første milestones venter på at blive opnået']
        : milestones;
  }

  /// Development trends section
  static pw.Widget _buildTrendsSection(List<ProgressData> allProgress) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'UDVIKLINGS TRENDS',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Trend analyse ville kræve historiske data over tid. Denne sektion kan udvides med time-series data.',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
        ),
      ],
    );
  }

  /// Future goals section
  static pw.Widget _buildFutureGoalsSection(List<ProgressData> allProgress) {
    final goals = _generateFutureGoals(allProgress);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'FREMTIDIGE MÅL',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 12),
        ...goals
            .map(
              (goal) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  children: [
                    pw.Text('🎯 ', style: const pw.TextStyle(fontSize: 14)),
                    pw.Text(goal, style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  /// Genererer fremtidige mål baseret på nuværende progress
  static List<String> _generateFutureGoals(List<ProgressData> allProgress) {
    final goals = <String>[];
    final masteredCount = allProgress.where((p) => p.isMastered).length;

    goals.add('Opnå 80% success rate på alle kategorier');
    goals.add('Mestre ${masteredCount + 5} ord inden for næste måned');
    goals.add('Introducere sætnings-baserede øvelser');
    goals.add('Udvikle spontan brug af mestrede ord i daglig tale');

    return goals;
  }

  /// Unlock progression section
  static pw.Widget _buildUnlockProgressionSection(
    List<ProgressData> allProgress,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'UNLOCK PROGRESSION',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Progressiv unlock struktur motiverer barnet gennem systematisk læring fra grundlæggende vokaler til avancerede konsonant kombinationer.',
          style: const pw.TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  /// Custom summary for custom reports
  static pw.Widget _buildCustomSummary(
    Map<String, dynamic> stats,
    List<ProgressData> filteredProgress,
    List<String> categories,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.purple50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.purple200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TILPASSET ANALYSE',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Fokus kategorier: ${categories.map(_getCategoryDisplayName).join(', ')}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Analyserer ${filteredProgress.length} ord inden for valgte kategorier.',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// Helper metoder
  static String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'a-sounds':
        return 'A-lyde';
      case 'e-sounds':
        return 'E-lyde';
      case 'i-sounds':
        return 'I-lyde';
      case 'o-sounds':
        return 'O-lyde';
      case 'u-sounds':
        return 'U-lyde';
      case 'b-sounds':
        return 'B-lyde';
      case 'd-sounds':
        return 'D-lyde';
      case 'm-sounds':
        return 'M-lyde';
      case 'n-sounds':
        return 'N-lyde';
      case 'p-sounds':
        return 'P-lyde';
      case 't-sounds':
        return 'T-lyde';
      case 's-sounds':
        return 'S-lyde';
      case 'r-sounds':
        return 'R-lyde';
      case 'l-sounds':
        return 'L-lyde';
      case 'f-sounds':
        return 'F-lyde';
      case 'v-sounds':
        return 'V-lyde';
      case 'k-sounds':
        return 'K-lyde';
      case 'g-sounds':
        return 'G-lyde';
      case 'æ-sounds':
        return 'Æ-lyde';
      case 'ø-sounds':
        return 'Ø-lyde';
      case 'å-sounds':
        return 'Å-lyde';
      case 'animals':
        return 'Dyr';
      case 'food':
        return 'Mad';
      case 'advanced':
        return 'Avanceret';
      default:
        return category;
    }
  }

  static String _getCategoryStatus(double successRate) {
    if (successRate >= 0.8) return 'Fremragende';
    if (successRate >= 0.6) return 'God';
    if (successRate >= 0.4) return 'Udvikling';
    return 'Udfordrende';
  }

  /// Gemmer PDF til fil system
  static Future<File> _savePDFToFile(pw.Document pdf, String filename) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
