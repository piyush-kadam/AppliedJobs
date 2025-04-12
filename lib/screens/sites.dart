import 'dart:typed_data';
import 'package:appliedjobs/screens/pdf.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// Comes with pdf package

class SitesPage extends StatefulWidget {
  const SitesPage({super.key});

  @override
  State<SitesPage> createState() => _SitesPageState();
}

class _SitesPageState extends State<SitesPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final summaryController = TextEditingController();
  final experienceController = TextEditingController();
  final educationController = TextEditingController();
  final skillsController = TextEditingController();

  bool isLoading = false;

  Future<void> generateResume() async {
    setState(() => isLoading = true);

    final resumeText = """
${nameController.text}

CONTACT
Email: ${emailController.text}
Phone: ${phoneController.text}

PROFESSIONAL SUMMARY
${summaryController.text}

WORK EXPERIENCE
${experienceController.text}

EDUCATION
${educationController.text}

SKILLS
${skillsController.text}
""";

    final url = Uri.parse(
      'https://ai-resume-builder-cv-checker-resume-rewriter-api.p.rapidapi.com/generateResume?noqueue=1&language=en',
    );

    final headers = {
      'Content-Type': 'application/json',
      'x-rapidapi-host': 'ai-resume-generator.p.rapidapi.com',
      'x-rapidapi-key': 'd13f42535cmsh141899f47a3d719p1b57cdjsn407c386fa0df',
      'x-usiapps-req': 'true',
    };

    final body = jsonEncode({"resumeText": resumeText});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedResume = data['generatedResume'] ?? resumeText;

        // Show the PDF preview
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PDFPreviewPage(resumeText: generatedResume),
          ),
        );
      } else {
        _showError("Failed to generate resume.\n${response.statusCode}");
      }
    } catch (e) {
      _showError("An error occurred:\n$e");
    }

    setState(() => isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Resume Generator")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              buildSectionTitle("Basic Info"),
              buildTextField("Name", nameController),
              buildTextField("Email", emailController),
              buildTextField("Phone", phoneController),

              buildSectionTitle("Professional Summary"),
              buildTextField("Summary", summaryController, maxLines: 4),

              buildSectionTitle("Work Experience"),
              buildTextField("Experience", experienceController, maxLines: 4),

              buildSectionTitle("Education"),
              buildTextField("Education", educationController, maxLines: 3),

              buildSectionTitle("Skills"),
              buildTextField("Skills", skillsController, maxLines: 2),

              const SizedBox(height: 30),

              // 👇 This is now scrollable and visible!
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.picture_as_pdf),
                  label: Text(
                    isLoading ? "Generating..." : "Generate Resume PDF",
                  ),
                  onPressed: isLoading ? null : generateResume,
                ),
              ),
              const SizedBox(height: 30), // extra spacing at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
