import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PDFPreviewPage extends StatefulWidget {
  final Map<String, dynamic> resumeData;

  const PDFPreviewPage({super.key, required this.resumeData});

  @override
  State<PDFPreviewPage> createState() => _PDFPreviewPageState();
}

class _PDFPreviewPageState extends State<PDFPreviewPage> {
  String? pdfDownloadUrl;
  bool isLoading = true;
  String? error;

  // Replace with your actual values
  final String templateId = '421AF363-D886-4667-9C0E-F717C6495441';
  final String apiKey = '-h43b5y4MUjTQK29T1ms';

  @override
  void initState() {
    super.initState();
    generateResume();
  }

  Future<void> generateResume() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.pdfmonkey.io/api/v1/documents'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'document': {
            'document_template_id': templateId,
            'payload': widget.resumeData,
          },
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String url = data['data']['attributes']['download_url'];

        setState(() {
          pdfDownloadUrl = url;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to generate PDF: ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _launchURL() async {
    if (pdfDownloadUrl != null &&
        await canLaunchUrl(Uri.parse(pdfDownloadUrl!))) {
      await launchUrl(
        Uri.parse(pdfDownloadUrl!),
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not launch PDF')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resume Preview')),
      body: Center(
        child:
            isLoading
                ? const CircularProgressIndicator()
                : error != null
                ? Text(error!)
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                    const Text('Resume is ready!'),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _launchURL,
                      icon: const Icon(Icons.download),
                      label: const Text('Download Resume'),
                    ),
                  ],
                ),
      ),
    );
  }
}
