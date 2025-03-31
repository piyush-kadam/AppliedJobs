import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SitesPage extends StatelessWidget {
  const SitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Platforms'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFE0E0E0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Connect Platforms',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _platformCard(
              context,
              'LinkedIn',
              'assets/images/linkedin.jpg',
              Colors.blue,
              _connectLinkedIn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _platformCard(
    BuildContext context,
    String title,
    String iconPath,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Image.asset(iconPath, width: 40, height: 40),
        title: Text(title),
        trailing: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.login),
          label: const Text('Connect'),
          style: ElevatedButton.styleFrom(backgroundColor: color),
        ),
      ),
    );
  }

  // OAuth Connection to LinkedIn
  void _connectLinkedIn() async {
    const clientId = '863n2mh5e6vx5q';
    const redirectUri = 'https://www.your-placeholder.com/oauth/callback';

    const scope = 'w_member_social'; // Match your LinkedIn app scopes

    // Encode the redirect URI
    final encodedRedirectUri = Uri.encodeComponent(redirectUri);

    final url =
        'https://www.linkedin.com/oauth/v2/authorization'
        '?response_type=code'
        '&client_id=$clientId'
        '&redirect_uri=$encodedRedirectUri'
        '&scope=$scope';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
}
