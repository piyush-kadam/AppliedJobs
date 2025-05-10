import 'dart:io';
import 'package:appliedjobs/auth/authservice.dart';
import 'package:appliedjobs/screens/applied_jobs.dart';
import 'package:appliedjobs/screens/jobs.dart';
import 'package:appliedjobs/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Getter for _pages
  List<Widget> get _pages => [
    JobsPage(),
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
              ClipOval(
                child: Image.asset(
                  'assets/images/plus.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "AppliedPlus",
                style: GoogleFonts.poppins(
                  color: Color(0xFF3D47D1),
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
                      _selectedIndex = 2; // Profile tab index
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF3D47D1), width: 2),
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

      body: _pages[_selectedIndex],

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.grey[400]!, // a light grey border
              width: 1.0, // you can adjust thickness as needed
            ),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.work_outline, 'Jobs'),
                _buildNavItem(
                  1,
                  Icons.assignment_turned_in_outlined,
                  'Applied',
                ),
                _buildNavItem(2, Icons.person_outline, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top indicator line when selected
          Container(
            height: 3,
            width: 30,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3D47D1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Icon(
            icon,
            color: isSelected ? const Color(0xFF3D47D1) : Colors.black,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF3D47D1) : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}
