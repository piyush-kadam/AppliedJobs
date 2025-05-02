import 'dart:io';
import 'package:appliedjobs/auth/authservice.dart';
import 'package:appliedjobs/screens/applied_jobs.dart';
import 'package:appliedjobs/screens/jobs.dart';
import 'package:appliedjobs/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool isJoined = false;
  String username = '';
  final AuthService authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter for _pages, it will dynamically return the updated value of 'isJoined'
  List<Widget> get _pages => [
    JobsPage(), // This updates when isJoined changes
    const AppliedPage(),

    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkIfUserJoined();
  }

  Future<void> _checkIfUserJoined() async {
    try {
      final user = authService.getCurrentUser();
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('Users').doc(user.uid).get();

        if (userDoc.exists && userDoc['username'] != null) {
          setState(() {
            isJoined = true;
            username = userDoc['username'];
          });
        }
      }
    } catch (e) {
      print("Error checking user: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _joinUser() async {
    final user = authService.getCurrentUser();
    if (user != null) {
      String? newUsername = await _showUsernameDialog();

      if (newUsername != null && newUsername.isNotEmpty) {
        bool usernameExists = await _checkIfUsernameExists(newUsername);

        if (usernameExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Username already exists. Try another."),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          try {
            await _firestore.collection('Users').doc(user.uid).set({
              'uid': user.uid,
              'email': user.email,
              'username': newUsername,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("You're now a Member!"),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );

            setState(() {
              isJoined = true;
              username = newUsername;
            });
          } catch (e) {
            print("Error adding user to Firestore: $e");
          }
        }
      }
    }
  }

  Future<String?> _showUsernameDialog() async {
    TextEditingController controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter a username", style: GoogleFonts.poppins()),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Username"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkIfUsernameExists(String username) async {
    QuerySnapshot snapshot =
        await _firestore
            .collection('Users')
            .where('username', isEqualTo: username)
            .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<String?> _getProfileImageUrl() async {
    final user = authService.getCurrentUser();
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('Users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['profileImageUrl'] as String?;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.check, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                "AppliedPlus",
                style: GoogleFonts.poppins(
                  color: Colors.deepPurple,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0E0E0),
        actions: [
          FutureBuilder<String?>(
            future: _getProfileImageUrl(),
            builder: (context, snapshot) {
              final imageUrl = snapshot.data;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex =
                          2; // index of 'Profile' tab (corrected from 3)
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.deepPurple, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black,
                      backgroundImage:
                          imageUrl != null ? NetworkImage(imageUrl) : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),

      body: _pages[_selectedIndex], // Use the dynamic getter here

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10), // Padding from all sides
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.deepPurple,
              color: Colors.black,
              tabs: const [
                GButton(icon: Icons.work, text: 'Jobs'),
                GButton(icon: Icons.assignment_turned_in, text: 'Applied'),

                GButton(icon: Icons.person, text: 'Profile'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
