/// Share Service - Professional email og sharing system til PPR rapporter
/// FORMÅL: Send progress rapporter direkte til logopæder og fagteam
/// FUNKTIONALITET: Email templates, fil sharing, professional communication

import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

class ShareService {
  /// Deler PDF rapport via system share sheet
  /// BRUG: Universal sharing til alle platforme (email, WhatsApp, etc.)
  static Future<void> sharePDFReport({
    required File pdfFile,
    required String childName,
    required String reportType,
  }) async {
    try {
      final XFile xFile = XFile(pdfFile.path);

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: _generateEmailSubject(childName, reportType),
          text: _generateEmailBody(childName, reportType),
        ),
      );
    } catch (e) {
      throw Exception('Kunne ikke dele rapport: $e');
    }
  }

  /// Sender rapport direkte via email med professional template
  /// TARGET: Logopæder, PPR teams, fagpersoner
  static Future<void> sendToTherapist({
    required File pdfFile,
    required String childName,
    required String reportType,
    required String recipientEmail,
    String? ccEmail,
    String? customMessage,
  }) async {
    try {
      final XFile xFile = XFile(pdfFile.path);

      // Professional email composition
      final subject = _generateEmailSubject(childName, reportType);
      final body = _generateProfessionalEmailBody(
        childName: childName,
        reportType: reportType,
        customMessage: customMessage,
      );

      await SharePlus.instance.share(
        ShareParams(files: [xFile], subject: subject, text: body),
      );
    } catch (e) {
      throw Exception('Kunne ikke sende email: $e');
    }
  }

  /// Bulk sharing til fagteam (logopæd + PPR + forældre)
  /// SCENARIO: Større møder hvor alle parter skal have rapporten
  static Future<void> shareToTeam({
    required File pdfFile,
    required String childName,
    required String reportType,
    required List<String> teamEmails,
    String? meetingDate,
  }) async {
    try {
      final XFile xFile = XFile(pdfFile.path);

      final subject = _generateTeamEmailSubject(
        childName,
        reportType,
        meetingDate,
      );
      final body = _generateTeamEmailBody(
        childName: childName,
        reportType: reportType,
        teamEmails: teamEmails,
        meetingDate: meetingDate,
      );

      await SharePlus.instance.share(
        ShareParams(files: [xFile], subject: subject, text: body),
      );
    } catch (e) {
      throw Exception('Kunne ikke dele til team: $e');
    }
  }

  /// Quick share til forældre/familie
  /// BRUG: Mere casual sharing til bedsteforældre, familie
  static Future<void> shareToFamily({
    required File pdfFile,
    required String childName,
    required String reportType,
  }) async {
    try {
      final XFile xFile = XFile(pdfFile.path);

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: '$childName\'s sprogudvikling - $reportType',
          text: _generateFamilyEmailBody(childName, reportType),
        ),
      );
    } catch (e) {
      throw Exception('Kunne ikke dele til familie: $e');
    }
  }

  /// Genererer professional email subject lines
  static String _generateEmailSubject(String childName, String reportType) {
    final now = DateTime.now();
    return 'SPROKI Rapport - $childName - $reportType (${now.day}/${now.month}/${now.year})';
  }

  /// Genererer team email subject med møde reference
  static String _generateTeamEmailSubject(
    String childName,
    String reportType,
    String? meetingDate,
  ) {
    if (meetingDate != null) {
      return 'PPR Møde $meetingDate - SPROKI Rapport: $childName';
    }
    return 'SPROKI Team Rapport - $childName - $reportType';
  }

  /// Standard email body for basic sharing
  static String _generateEmailBody(String childName, String reportType) {
    return '''
Hej,

Vedhæftet finder du $reportType for $childName fra SPROKI sprogterapi appen.

Rapporten indeholder detaljeret analyse af $childName's sprogudvikling og fremgang.

Med venlig hilsen,
SPROKI Team
''';
  }

  /// Professional email body til fagpersoner
  static String _generateProfessionalEmailBody({
    required String childName,
    required String reportType,
    String? customMessage,
  }) {
    final now = DateTime.now();

    return '''
Kære fagperson,

Vedhæftet finder du $reportType for $childName genereret via SPROKI digital sprogterapi platform.

RAPPORT DETALJER:
• Barn: $childName
• Rapport type: $reportType  
• Genereret: ${now.day}/${now.month}/${now.year}
• Platform: SPROKI Digital Sprogterapi

RAPPORT INDHOLD:
✓ Detaljeret progress analyse
✓ Kategori-specifik performance
✓ Professional anbefalinger
✓ Objektiv data dokumentation
✓ Unlock progression oversigt

${customMessage != null ? '\nTILFØJET BESKED:\n$customMessage\n' : ''}

Rapporten er genereret automatisk baseret på $childName's faktiske træningsdata og giver objektiv dokumentation af sprogudvikling.

For spørgsmål til rapporten eller SPROKI platformen, er I velkommen til at kontakte os.

Med venlig hilsen,
$childName's forældre
via SPROKI Platform

---
SPROKI - Digital Sprogterapi Platform
Objektiv dokumentation af børns sprogudvikling
''';
  }

  /// Team email body til fagteam og PPR møder
  static String _generateTeamEmailBody({
    required String childName,
    required String reportType,
    required List<String> teamEmails,
    String? meetingDate,
  }) {
    final meetingRef = meetingDate != null
        ? 'til PPR møde d. $meetingDate'
        : '';

    return '''
Kære fagteam,

Vedhæftet finder du $reportType for $childName $meetingRef.

TEAM MODTAGERE:
${teamEmails.map((email) => '• $email').join('\n')}

FORMÅL:
Dette er en objektiv progress rapport baseret på $childName's træning i SPROKI appen. Rapporten giver data-drevet indsigt i sprogudvikling og kan bruges som grundlag for faglig vurdering.

RAPPORT HIGHLIGHTS:
✓ Kategori performance analyse
✓ Ord-for-ord progression  
✓ Success rate trends
✓ Professional anbefalinger
✓ Milestone dokumentation

${meetingDate != null ? 'Rapporten er forberedt specifikt til mødet d. $meetingDate og reflekterer $childName\'s aktuelle sprogudvikling.\n' : ''}

Vi ser frem til en konstruktiv dialog om $childName's fortsatte udvikling.

Med venlig hilsen,
$childName's forældre

---
SPROKI Digital Sprogterapi Platform
Professional dokumentation til faglig brug
''';
  }

  /// Casual email body til familie
  static String _generateFamilyEmailBody(String childName, String reportType) {
    return '''
Hej alle sammen! 👋

$childName har gjort så store fremskridt med sproget, og vi ville gerne dele det med jer! 

📊 Vedhæftet er en rapport der viser hvordan $childName klarer sig med de forskellige lyde og ord vi øver.

Det er så sjovt at se hvordan appen hjælper, og $childName elsker at "låse nye ord op" når de mestrer dem! 🔓✨

Håber I har lyst til at se hvor godt det går! 

Kærlig hilsen 💕
''';
  }

  /// Viser share optioner til brugeren
  static Future<void> showShareOptions({
    required BuildContext context,
    required File pdfFile,
    required String childName,
    required String reportType,
  }) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Del Rapport',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 20),

            // Standard sharing
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Del via apps'),
              subtitle: const Text('WhatsApp, email, etc.'),
              onTap: () async {
                Navigator.pop(context);
                await sharePDFReport(
                  pdfFile: pdfFile,
                  childName: childName,
                  reportType: reportType,
                );
              },
            ),

            // Professional sharing
            ListTile(
              leading: const Icon(Icons.business, color: Colors.green),
              title: const Text('Send til logopæd'),
              subtitle: const Text('Professional email template'),
              onTap: () async {
                Navigator.pop(context);
                // Kunne åbne dialog for email input
                await sendToTherapist(
                  pdfFile: pdfFile,
                  childName: childName,
                  reportType: reportType,
                  recipientEmail: '', // Skulle fyldes via dialog
                );
              },
            ),

            // Family sharing
            ListTile(
              leading: const Icon(Icons.family_restroom, color: Colors.orange),
              title: const Text('Del med familie'),
              subtitle: const Text('Casual sharing til bedsteforældre'),
              onTap: () async {
                Navigator.pop(context);
                await shareToFamily(
                  pdfFile: pdfFile,
                  childName: childName,
                  reportType: reportType,
                );
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Validates email addresses
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Genererer preview af email indhold
  static String getEmailPreview({
    required String childName,
    required String reportType,
    required EmailType emailType,
  }) {
    switch (emailType) {
      case EmailType.professional:
        return _generateProfessionalEmailBody(
          childName: childName,
          reportType: reportType,
        );
      case EmailType.family:
        return _generateFamilyEmailBody(childName, reportType);
      case EmailType.team:
        return _generateTeamEmailBody(
          childName: childName,
          reportType: reportType,
          teamEmails: ['logopæd@eksempel.dk', 'ppr@eksempel.dk'],
        );
      default:
        return _generateEmailBody(childName, reportType);
    }
  }
}

/// Email type enum for different sharing scenarios
enum EmailType { standard, professional, family, team }
