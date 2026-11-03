/// Report Builder Screen - Professional rapport konfiguration til PPR møder
/// FORMÅL: Giver forældre mulighed for at generere tilpassede rapporter
/// TARGET: PPR møder, logopæd konsultationer, progress dokumentation

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/pdf_service.dart';
import '../services/share_service.dart';
import 'dart:io';

class ReportBuilderScreen extends StatefulWidget {
  final String childName;

  const ReportBuilderScreen({super.key, required this.childName});

  @override
  ReportBuilderScreenState createState() => ReportBuilderScreenState();
}

class ReportBuilderScreenState extends State<ReportBuilderScreen> {
  // Report configuration state
  ReportType _selectedReportType = ReportType.weekly;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  // Category selection for custom reports
  final Set<String> _selectedCategories = <String>{};

  // Custom report options
  bool _includeRecommendations = true;
  bool _includeDetailedBreakdown = true;
  bool _includeCharts = true;

  // Loading and error states
  bool _isGenerating = false;
  String? _errorMessage;

  // Available categories with user-friendly names
  final Map<String, String> _availableCategories = {
    'a-sounds': '🅰️ A-lyde (and, arm, baby)',
    'e-sounds': '🅴 E-lyde (elefant, te, se)',
    'i-sounds': '🅸 I-lyde (is, tiger, dit)',
    'o-sounds': '🅾️ O-lyde (ord, bro)',
    'u-sounds': '🆄 U-lyde (ugle, bus, hus)',
    'b-sounds': '🅱️ B-lyde (bold, bord, bog)',
    'd-sounds': '🅳 D-lyde (dør, dukke, dans)',
    'm-sounds': '🅼 M-lyde (mor, mælk, måne)',
    'n-sounds': '🅽 N-lyde (næse, nat, nål)',
    'p-sounds': '🅿️ P-lyde (pige, pizza, papir)',
    't-sounds': '🆃 T-lyde (tog, tand, top)',
    's-sounds': '🅢 S-lyde (sol, sko, slange)',
    'r-sounds': '🅡 R-lyde (rød, rose, radio)',
    'l-sounds': '🅛 L-lyde (lys, løve, lukke)',
    'f-sounds': '🅕 F-lyde (fire, fugl, frugt)',
    'v-sounds': '🅥 V-lyde (vand, bil, vejr)',
    'k-sounds': '🅚 K-lyde (ko, kage, kylling)',
    'g-sounds': '🅖 G-lyde (gul, gave, glas)',
    'æ-sounds': '🇩🇰 Æ-lyde (æble, læge, træ)',
    'ø-sounds': '🇩🇰 Ø-lyde (ørn, ø, grød)',
    'å-sounds': '🇩🇰 Å-lyde (åben, kål, år)',
    'animals': '🐾 Dyr (kat, hund, fisk)',
    'food': '🍎 Mad (brød, ost)',
    'advanced': '⭐ Avanceret (frost, skrig, storm)',
  };

  @override
  void initState() {
    super.initState();
    // Default: Select all categories for custom reports
    _selectedCategories.addAll(_availableCategories.keys);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generer Rapport'),
        backgroundColor: Colors.purple.shade300,
        elevation: 0,
      ),
      body: _isGenerating ? _buildLoadingView() : _buildConfigurationView(),
      bottomNavigationBar: _isGenerating ? null : _buildGenerateButton(),
    );
  }

  /// Bygger loading view under rapport generering
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
          const SizedBox(height: 20),
          Text(
            'Genererer ${_getReportTypeName()} rapport...',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          const Text(
            'Dette kan tage et øjeblik',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Bygger hoved konfiguration view
  Widget _buildConfigurationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          _buildHeaderSection(),
          const SizedBox(height: 24),

          // Report type selection
          _buildReportTypeSection(),
          const SizedBox(height: 24),

          // Date range selection
          _buildDateRangeSection(),
          const SizedBox(height: 24),

          // Category selection (kun for custom reports)
          if (_selectedReportType == ReportType.custom) ...[
            _buildCategorySelectionSection(),
            const SizedBox(height: 24),
          ],

          // Advanced options (kun for custom reports)
          if (_selectedReportType == ReportType.custom) ...[
            _buildAdvancedOptionsSection(),
            const SizedBox(height: 24),
          ],

          // Error message display
          if (_errorMessage != null) ...[
            _buildErrorMessage(),
            const SizedBox(height: 24),
          ],

          // Preview section
          _buildPreviewSection(),

          // Extra spacing for bottom button
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// Header section med barn info og instruktioner
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.purple.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Rapport for: ${widget.childName}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Generer professionelle rapporter til PPR møder, logopæd konsultationer og progress dokumentation.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Report type selection section
  Widget _buildReportTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rapport Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        RadioGroup<ReportType>(
          groupValue: _selectedReportType,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedReportType = value;
              _updateDefaultDateRange();
            });
          },
          child: Column(
            children: ReportType.values
                .map(
                  (type) => RadioListTile<ReportType>(
                    title: Text(_getReportTypeName(type)),
                    subtitle: Text(_getReportTypeDescription(type)),
                    value: type,
                    activeColor: Colors.purple,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  /// Date range selection section
  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dato Periode',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateSelector(
                label: 'Fra dato',
                date: _startDate,
                onTap: () => _selectStartDate(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateSelector(
                label: 'Til dato',
                date: _endDate,
                onTap: () => _selectEndDate(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildQuickDateButtons(),
      ],
    );
  }

  /// Date selector widget
  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  /// Quick date selection buttons
  Widget _buildQuickDateButtons() {
    return Wrap(
      spacing: 8,
      children: [
        _buildQuickDateChip('Sidste uge', () {
          setState(() {
            _endDate = DateTime.now();
            _startDate = _endDate.subtract(const Duration(days: 7));
          });
        }),
        _buildQuickDateChip('Sidste måned', () {
          setState(() {
            _endDate = DateTime.now();
            _startDate = DateTime(
              _endDate.year,
              _endDate.month - 1,
              _endDate.day,
            );
          });
        }),
        _buildQuickDateChip('Sidste 3 måneder', () {
          setState(() {
            _endDate = DateTime.now();
            _startDate = DateTime(
              _endDate.year,
              _endDate.month - 3,
              _endDate.day,
            );
          });
        }),
      ],
    );
  }

  /// Quick date chip widget
  Widget _buildQuickDateChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.purple.shade50,
      labelStyle: TextStyle(color: Colors.purple.shade700),
    );
  }

  /// Category selection section (kun for custom reports)
  Widget _buildCategorySelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kategorier',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategories.addAll(_availableCategories.keys);
                    });
                  },
                  child: const Text('Vælg alle'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategories.clear();
                    });
                  },
                  child: const Text('Fravælg alle'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: _availableCategories.entries.map((entry) {
              return CheckboxListTile(
                title: Text(entry.value, style: const TextStyle(fontSize: 14)),
                value: _selectedCategories.contains(entry.key),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedCategories.add(entry.key);
                    } else {
                      _selectedCategories.remove(entry.key);
                    }
                  });
                },
                activeColor: Colors.purple,
                dense: true,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Advanced options section (kun for custom reports)
  Widget _buildAdvancedOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avancerede Indstillinger',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Inkluder anbefalinger'),
          subtitle: const Text('Professional anbefalinger til videre træning'),
          value: _includeRecommendations,
          onChanged: (value) {
            setState(() {
              _includeRecommendations = value;
            });
          },
          activeThumbColor: Colors.purple,
        ),
        SwitchListTile(
          title: const Text('Detaljeret ord analyse'),
          subtitle: const Text('Ord-for-ord breakdown og performance data'),
          value: _includeDetailedBreakdown,
          onChanged: (value) {
            setState(() {
              _includeDetailedBreakdown = value;
            });
          },
          activeThumbColor: Colors.purple,
        ),
        SwitchListTile(
          title: const Text('Inkluder charts'),
          subtitle: const Text('Visual performance charts og diagrammer'),
          value: _includeCharts,
          onChanged: (value) {
            setState(() {
              _includeCharts = value;
            });
          },
          activeThumbColor: Colors.purple,
        ),
      ],
    );
  }

  /// Error message widget
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  /// Preview section
  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rapport Preview',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rapport: ${_getReportTypeName()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Barn: ${widget.childName}'),
              Text(
                'Periode: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
              ),
              if (_selectedReportType == ReportType.custom) ...[
                Text('Kategorier: ${_selectedCategories.length} valgt'),
                if (_includeRecommendations)
                  const Text('✓ Inkluderer anbefalinger'),
                if (_includeDetailedBreakdown)
                  const Text('✓ Inkluderer detaljeret analyse'),
                if (_includeCharts) const Text('✓ Inkluderer charts'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Generate button
  Widget _buildGenerateButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: _canGenerate() ? _generateReport : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.file_download),
            const SizedBox(width: 8),
            Text(
              'Generer ${_getReportTypeName()} Rapport',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /// Checks if report can be generated
  bool _canGenerate() {
    if (_selectedReportType == ReportType.custom &&
        _selectedCategories.isEmpty) {
      return false;
    }
    return _startDate.isBefore(_endDate);
  }

  /// Main report generation method
  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      File? pdfFile;

      switch (_selectedReportType) {
        case ReportType.weekly:
          pdfFile = await PDFService.generateWeeklyReport(
            childName: widget.childName,
            startDate: _startDate,
            endDate: _endDate,
          );
          break;
        case ReportType.monthly:
          pdfFile = await PDFService.generateMonthlyReport(
            childName: widget.childName,
            startDate: _startDate,
            endDate: _endDate,
          );
          break;
        case ReportType.custom:
          pdfFile = await PDFService.generateCustomReport(
            childName: widget.childName,
            startDate: _startDate,
            endDate: _endDate,
            selectedCategories: _selectedCategories.toList(),
            includeRecommendations: _includeRecommendations,
            includeDetailedBreakdown: _includeDetailedBreakdown,
          );
          break;
      }

      if (mounted) {
        // Vis sharing optioner
        await ShareService.showShareOptions(
          context: context,
          pdfFile: pdfFile,
          childName: widget.childName,
          reportType: _getReportTypeName(),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fejl ved generering af rapport: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  /// Date selection methods
  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: _endDate,
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  /// Updates default date range based on report type
  void _updateDefaultDateRange() {
    final now = DateTime.now();
    switch (_selectedReportType) {
      case ReportType.weekly:
        _endDate = now;
        _startDate = now.subtract(const Duration(days: 7));
        break;
      case ReportType.monthly:
        _endDate = now;
        _startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case ReportType.custom:
        // Keep current selection
        break;
    }
  }

  /// Helper methods for report type names and descriptions
  String _getReportTypeName([ReportType? type]) {
    switch (type ?? _selectedReportType) {
      case ReportType.weekly:
        return 'Ugentlig Rapport';
      case ReportType.monthly:
        return 'Månedlig Rapport';
      case ReportType.custom:
        return 'Tilpasset Rapport';
    }
  }

  String _getReportTypeDescription(ReportType type) {
    switch (type) {
      case ReportType.weekly:
        return 'Detaljeret analyse af ugens fremgang - perfekt til PPR møder';
      case ReportType.monthly:
        return 'Omfattende månedlig udvikling og milestone tracking';
      case ReportType.custom:
        return 'Tilpasset rapport med valgfrie kategorier og indhold';
    }
  }
}

/// Report type enumeration
enum ReportType { weekly, monthly, custom }
