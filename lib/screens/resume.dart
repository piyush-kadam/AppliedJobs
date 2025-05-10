import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ResumeViewerPage extends StatelessWidget {
  final String url;

  const ResumeViewerPage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Resume',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF3D47D1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SfPdfViewer.network(url),
    );
  }
}
