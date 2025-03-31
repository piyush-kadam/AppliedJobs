import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  String? accessToken;
  List<dynamic> jobPosts = [];

  @override
  void initState() {
    super.initState();
  }

  // Launch LinkedIn OAuth URL
  Future<void> _launchLinkedInOAuth() async {
    const clientId = '863n2mh5e6vx5q';
    const redirectUri = 'https://yourapp.com/callback';
    const scope = 'r_liteprofile%20r_emailaddress%20w_member_social';

    final authUrl = Uri.parse(
      'https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&scope=$scope',
    );

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch LinkedIn OAuth');
    }
  }

  // Exchange code for access token
  Future<void> _getAccessToken(String code) async {
    const clientId = '863n2mh5e6vx5q';
    const clientSecret = 'WPL_AP1.PbKHptAaGqdFOmhf.RPDbYQ==';
    const redirectUri = 'https://www.your-placeholder.com/oauth/callback';


    final response = await http.post(
      Uri.parse('https://www.linkedin.com/oauth/v2/accessToken'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        accessToken = data['access_token'];
      });
      await _fetchJobPosts();
    } else {
      print('Failed to get access token: ${response.body}');
    }
  }

  // Fetch job posts from LinkedIn API
  Future<void> _fetchJobPosts() async {
    if (accessToken == null) return;

    final response = await http.get(
      Uri.parse('https://api.linkedin.com/v2/jobPosts?q=recent'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        jobPosts = data['elements'] ?? [];
      });
    } else {
      print('Failed to fetch job posts: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Posts'),
        backgroundColor: Colors.black,
      ),
      body:
          accessToken == null
              ? Center(
                child: ElevatedButton(
                  onPressed: _launchLinkedInOAuth,
                  child: const Text('Login with LinkedIn'),
                ),
              )
              : ListView.builder(
                itemCount: jobPosts.length,
                itemBuilder: (context, index) {
                  final job = jobPosts[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 4,
                    child: ListTile(
                      title: Text(job['title'] ?? 'No Title'),
                      subtitle: Text(job['company'] ?? 'No Company'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        // Open job post details
                      },
                    ),
                  );
                },
              ),
    );
  }
}
