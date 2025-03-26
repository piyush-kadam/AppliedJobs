import "package:appliedjobs/auth/authservice.dart";
import "package:appliedjobs/auth/lr.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'AppliedJobs',
          style: GoogleFonts.abel(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await AuthService().signOut(); // Use signOut() from AuthService

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginOrRegister(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
