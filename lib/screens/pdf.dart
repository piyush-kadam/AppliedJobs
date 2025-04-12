import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PDFPreviewPage extends StatelessWidget {
  final String resumeText;

  const PDFPreviewPage({super.key, required this.resumeText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preview Resume PDF")),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) => generatePdf(resumeText),
              allowPrinting: true,
              allowSharing: true,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final pdfData = await generatePdf(resumeText);
                final permission = await Permission.storage.request();

                if (permission.isGranted) {
                  Directory? baseDir;

                  if (Platform.isAndroid) {
                    baseDir = await getExternalStorageDirectory();
                    // Navigate to Downloads-like directory
                    final downloadsDir = Directory(
                      "${baseDir!.parent.parent.parent.parent.path}/Download",
                    );

                    if (!(await downloadsDir.exists())) {
                      await downloadsDir.create(recursive: true);
                    }

                    final file = File("${downloadsDir.path}/Resume.pdf");
                    await file.writeAsBytes(pdfData);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Saved to ${file.path}")),
                    );
                  } else if (Platform.isIOS) {
                    baseDir = await getApplicationDocumentsDirectory();
                    final file = File("${baseDir.path}/Resume.pdf");
                    await file.writeAsBytes(pdfData);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Saved to app documents: ${file.path}"),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Storage permission denied')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            icon: const Icon(Icons.download),
            label: const Text("Download Resume"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

Future<Uint8List> generatePdf(String text) async {
  final pdf = pw.Document();

  final ttf = await PdfGoogleFonts.openSansRegular();
  final boldTtf = await PdfGoogleFonts.openSansBold();
  final headingFont = await PdfGoogleFonts.robotoBold();

  final sections = _parseResumeSections(text);

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(32),
      build:
          (context) => [
            pw.Center(
              child: pw.Text(
                sections['name'] ?? 'Your Name',
                style: pw.TextStyle(
                  font: boldTtf,
                  fontSize: 28,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Text(
                sections['contact'] ?? '',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 12,
                  color: PdfColors.grey800,
                ),
              ),
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 20),
            _buildSection(
              "Professional Summary",
              sections['summary'],
              ttf,
              headingFont,
            ),
            _buildSection(
              "Work Experience",
              sections['experience'],
              ttf,
              headingFont,
            ),
            _buildSection("Education", sections['education'], ttf, headingFont),
            _buildSection("Skills", sections['skills'], ttf, headingFont),
          ],
    ),
  );

  return pdf.save();
}

Map<String, String> _parseResumeSections(String text) {
  final lines = text.split('\n');
  final sections = {
    'name': lines.first.trim(),
    'contact': '',
    'summary': '',
    'experience': '',
    'education': '',
    'skills': '',
  };

  String? currentSection;

  for (var line in lines.skip(1)) {
    final trimmed = line.trim();
    if (trimmed.toUpperCase().contains("CONTACT")) {
      currentSection = 'contact';
    } else if (trimmed.toUpperCase().contains("PROFESSIONAL SUMMARY")) {
      currentSection = 'summary';
    } else if (trimmed.toUpperCase().contains("WORK EXPERIENCE")) {
      currentSection = 'experience';
    } else if (trimmed.toUpperCase().contains("EDUCATION")) {
      currentSection = 'education';
    } else if (trimmed.toUpperCase().contains("SKILLS")) {
      currentSection = 'skills';
    } else if (currentSection != null) {
      sections[currentSection] =
          (sections[currentSection]! + '\n' + line).trim();
    }
  }

  return sections;
}

pw.Widget _buildSection(
  String title,
  String? content,
  pw.Font font,
  pw.Font headingFont,
) {
  if (content == null || content.trim().isEmpty) return pw.SizedBox();

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          font: headingFont,
          fontSize: 18,
          color: PdfColors.blueGrey900,
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Text(
          content.trim(),
          style: pw.TextStyle(
            font: font,
            fontSize: 12,
            color: PdfColors.grey800,
            lineSpacing: 3,
          ),
        ),
      ),
      pw.SizedBox(height: 16),
    ],
  );
}
