import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://jsearch.p.rapidapi.com/search';
  static const Map<String, String> _headers = {
    'x-rapidapi-host': 'jsearch.p.rapidapi.com',
    'x-rapidapi-key': '1398211647mshbf9c83824427cf4p1ca482jsnf6f38a66f752',
  };

  /// Fetch jobs one page at a time for lazy loading
  Future<List<dynamic>> fetchJobsPage({
    String query = 'jobs',
    int page = 1,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl?query=$query%20in%20India&page=$page&num_pages=1&country=in&date_posted=all',
    );

    final response = await http.get(uri, headers: _headers);

    if (kDebugMode) {
      print("🔍 Request URL: $uri");
      print("📦 Response Body: ${response.body}");
    }

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final jobs = jsonData['data'] ?? [];

      if (kDebugMode) {
        print("✅ Page $page - Fetched ${jobs.length} jobs:");
        for (var job in jobs) {
          print("🧩 Job: ${job['job_title']}");
          print("🏢 Company: ${job['employer_name']}");
          print("🌐 Platform: ${job['job_publisher']}");
          print("🔗 Apply Link: ${job['job_apply_link']}");
          print("-------------------------------------------------");
        }
      }

      return jobs;
    } else {
      throw Exception('Failed to load jobs for page $page');
    }
  }
}
