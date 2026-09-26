import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/resume.dart';

class PdfExportService {
  PdfExportService._();

  /// Generates a clean, ATS-compliant PDF from [resume] and opens the platform share sheet.
  static Future<String> exportAndShare(Resume resume) async {
    final pdfDocument = PdfDocument();
    pdfDocument.pageSettings.margins.all = 36; // 0.5 inch margins

    final page = pdfDocument.pages.add();
    final graphics = page.graphics;
    final pageSize = page.getClientSize();

    // Fonts
    final headerFont = PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold);
    final subHeaderFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
    final sectionTitleFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final bodyBoldFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    final smallFont = PdfStandardFont(PdfFontFamily.helvetica, 9);

    final primaryColor = PdfColor(79, 70, 229); // Modern Indigo
    final textDark = PdfColor(15, 23, 42);
    final textMuted = PdfColor(100, 116, 139);

    double y = 0;

    // 1. Header (Name, Headline, Contact)
    final name = resume.personalInfo.fullName.isNotEmpty
        ? resume.personalInfo.fullName
        : (resume.title.isNotEmpty ? resume.title : 'My Resume');
    graphics.drawString(name, headerFont,
        brush: PdfSolidBrush(primaryColor), bounds: Rect.fromLTWH(0, y, pageSize.width, 24));
    y += 24;

    if (resume.headline != null && resume.headline!.isNotEmpty) {
      graphics.drawString(resume.headline!, subHeaderFont,
          brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(0, y, pageSize.width, 16));
      y += 18;
    }

    final contactParts = <String>[];
    if (resume.personalInfo.email.isNotEmpty) contactParts.add(resume.personalInfo.email);
    if (resume.personalInfo.phone.isNotEmpty) contactParts.add(resume.personalInfo.phone);
    if (resume.personalInfo.location.isNotEmpty) contactParts.add(resume.personalInfo.location);
    if (resume.personalInfo.website.isNotEmpty) contactParts.add(resume.personalInfo.website);

    if (contactParts.isNotEmpty) {
      graphics.drawString(contactParts.join('  •  '), smallFont,
          brush: PdfSolidBrush(textMuted), bounds: Rect.fromLTWH(0, y, pageSize.width, 14));
      y += 18;
    }

    // Divider Line
    graphics.drawLine(
      PdfPen(PdfColor(226, 232, 240), width: 1),
      Offset(0, y),
      Offset(pageSize.width, y),
    );
    y += 14;

    // Helper for Section Titles
    void drawSectionHeader(String title) {
      if (y > pageSize.height - 40) {
        // Next page if needed
        pdfDocument.pages.add();
        y = 0;
      }
      graphics.drawString(title.toUpperCase(), sectionTitleFont,
          brush: PdfSolidBrush(primaryColor), bounds: Rect.fromLTWH(0, y, pageSize.width, 16));
      y += 18;
    }

    // 2. Summary
    if (resume.professionalSummary != null && resume.professionalSummary!.isNotEmpty) {
      drawSectionHeader('Professional Summary');
      final textElement = PdfTextElement(text: resume.professionalSummary!, font: bodyFont);
      textElement.brush = PdfSolidBrush(textDark);
      final layoutResult = textElement.draw(
        page: page,
        bounds: Rect.fromLTWH(0, y, pageSize.width, pageSize.height - y),
      );
      y = layoutResult?.bounds.bottom ?? (y + 30);
      y += 14;
    }

    // 3. Experience
    if (resume.experience.isNotEmpty) {
      drawSectionHeader('Work Experience');
      for (final exp in resume.experience) {
        // Role & Company
        final roleLine = '${exp.role} — ${exp.company}';
        graphics.drawString(roleLine, bodyBoldFont,
            brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(0, y, pageSize.width - 120, 14));

        final dateLine = '${exp.startDate} - ${exp.isCurrent ? "Present" : exp.endDate}';
        graphics.drawString(dateLine, smallFont,
            brush: PdfSolidBrush(textMuted),
            bounds: Rect.fromLTWH(pageSize.width - 110, y, 110, 14),
            format: PdfStringFormat(alignment: PdfTextAlignment.right));
        y += 16;

        for (final bullet in exp.bullets) {
          graphics.drawString('• ', bodyFont,
              brush: PdfSolidBrush(primaryColor), bounds: Rect.fromLTWH(8, y, 12, 14));
          final bulletElement = PdfTextElement(text: bullet, font: bodyFont);
          bulletElement.brush = PdfSolidBrush(textDark);
          final res = bulletElement.draw(
            page: page,
            bounds: Rect.fromLTWH(20, y, pageSize.width - 20, pageSize.height - y),
          );
          y = res?.bounds.bottom ?? (y + 16);
          y += 4;
        }
        y += 8;
      }
      y += 8;
    }

    // 4. Skills
    if (resume.skills.isNotEmpty) {
      drawSectionHeader('Skills & Competencies');
      final skillsText = resume.skills.join(', ');
      final skillsElement = PdfTextElement(text: skillsText, font: bodyFont);
      skillsElement.brush = PdfSolidBrush(textDark);
      final res = skillsElement.draw(
        page: page,
        bounds: Rect.fromLTWH(0, y, pageSize.width, pageSize.height - y),
      );
      y = res?.bounds.bottom ?? (y + 24);
      y += 14;
    }

    // 5. Projects
    if (resume.projects.isNotEmpty) {
      drawSectionHeader('Key Projects');
      for (final proj in resume.projects) {
        final title = proj.techStack.isNotEmpty
            ? '${proj.name} (${proj.techStack.join(", ")})'
            : proj.name;
        graphics.drawString(title, bodyBoldFont,
            brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(0, y, pageSize.width, 14));
        y += 16;

        if (proj.description.isNotEmpty) {
          final descElement = PdfTextElement(text: proj.description, font: bodyFont);
          descElement.brush = PdfSolidBrush(textDark);
          final res = descElement.draw(
            page: page,
            bounds: Rect.fromLTWH(0, y, pageSize.width, pageSize.height - y),
          );
          y = res?.bounds.bottom ?? (y + 14);
          y += 4;
        }

        for (final bullet in proj.bullets) {
          graphics.drawString('• ', bodyFont,
              brush: PdfSolidBrush(primaryColor), bounds: Rect.fromLTWH(8, y, 12, 14));
          final bulletElement = PdfTextElement(text: bullet, font: bodyFont);
          bulletElement.brush = PdfSolidBrush(textDark);
          final res = bulletElement.draw(
            page: page,
            bounds: Rect.fromLTWH(20, y, pageSize.width - 20, pageSize.height - y),
          );
          y = res?.bounds.bottom ?? (y + 14);
          y += 4;
        }
        y += 8;
      }
      y += 8;
    }

    // 6. Education
    if (resume.education.isNotEmpty) {
      drawSectionHeader('Education');
      for (final edu in resume.education) {
        final deg = edu.fieldOfStudy.isNotEmpty
            ? '${edu.degree} in ${edu.fieldOfStudy}'
            : edu.degree;
        graphics.drawString(deg, bodyBoldFont,
            brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(0, y, pageSize.width - 120, 14));

        final dates = '${edu.startDate} - ${edu.endDate}';
        graphics.drawString(dates, smallFont,
            brush: PdfSolidBrush(textMuted),
            bounds: Rect.fromLTWH(pageSize.width - 110, y, 110, 14),
            format: PdfStringFormat(alignment: PdfTextAlignment.right));
        y += 16;

        graphics.drawString(edu.institution, smallFont,
            brush: PdfSolidBrush(textMuted), bounds: Rect.fromLTWH(0, y, pageSize.width, 14));
        y += 16;
      }
    }

    // Save and Share
    final bytes = await pdfDocument.save();
    pdfDocument.dispose();

    final tempDir = await getTemporaryDirectory();
    final sanitizedTitle = resume.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final fileName = '${sanitizedTitle.isEmpty ? "Resume" : sanitizedTitle}.pdf';
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/pdf', name: fileName)],
      subject: '$name - Resume',
      text: 'Here is my resume generated with CVNova.',
    );

    return filePath;
  }
}
