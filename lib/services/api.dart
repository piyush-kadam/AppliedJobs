import 'dart:convert';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://jsearch.p.rapidapi.com/search';
  static const Map<String, String> _headers = {
    'x-rapidapi-host': 'jsearch.p.rapidapi.com',
    'x-rapidapi-key': 'f95128157bmsha7437932abc58fcp10819bjsn3d8d54dc20c3',
  };

  Future<List<dynamic>> fetchJobs({
    String query = 'jobs', // fetch all types of jobs
    int pages = 5,
  }) async {
    List<dynamic> allJobs = [];

    for (int page = 1; page <= pages; page++) {
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
        if (jsonData['data'] != null) {
          allJobs.addAll(jsonData['data']);
        }
      } else {
        throw Exception('Failed to load jobs');
      }
    }

    if (kDebugMode) {
      print("✅ Jobs Fetched (${allJobs.length} jobs):");
      for (var job in allJobs) {
        print("🧩 Job: ${job['job_title']}");
        print("🏢 Company: ${job['employer_name']}");
        print("🌐 Platform: ${job['job_publisher']}");
        print("🔗 Apply Link: ${job['job_apply_link']}");
        print("-------------------------------------------------");
      }
    }

    return allJobs;
  }
}
