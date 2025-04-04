import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SitesPage extends StatefulWidget {
  const SitesPage({super.key});

  @override
  State<SitesPage> createState() => _SitesPageState();
}

class _SitesPageState extends State<SitesPage> {
  bool _isConnected = false; // Flag to track connection status

  @override
  void initState() {
    super.initState();
    _loadConnectionStatus();
  }

  // Load the connection status from SharedPreferences
  Future<void> _loadConnectionStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isConnected = prefs.getBool('linkedin_connected') ?? false;
    });
  }

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
              _isConnected ? Colors.green : Colors.blue,
              _isConnected ? 'Connected' : 'Connect',
              _isConnected
                  ? null
                  : _connectLinkedIn, // Disable tap if connected
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
    String buttonText,
    VoidCallback? onTap,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Image.asset(iconPath, width: 40, height: 40),
        title: Text(title),
        trailing: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(_isConnected ? Icons.check : Icons.login),
          label: Text(buttonText),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              color,
            ), // ✅ Proper color application
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
        ),
      ),
    );
  }

  // OAuth Connection to LinkedIn
  void _connectLinkedIn() async {
    const clientId = '863n2mh5e6vx5q'; // Your LinkedIn Client ID
    const redirectUri =
        'https://tinyurl.com/4wj7u2zp'; // Your Webhook redirect URI
    const scope = 'w_member_social';

    final url =
        'https://www.linkedin.com/oauth/v2/authorization'
        '?response_type=code'
        '&client_id=$clientId'
        '&redirect_uri=$redirectUri'
        '&scope=$scope';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));

        // Simulate successful connection
        setState(() {
          _isConnected = true;
        });

        // Save connection status in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('linkedin_connected', true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully connected to LinkedIn!')),
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
}
