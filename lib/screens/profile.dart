import 'package:appliedjobs/auth/authservice.dart';
import 'package:appliedjobs/screens/details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  String? email;
  String? phoneNumber;
  String? location;
  String? aboutMe;
  String? profileImagePath;
  bool isLoading = true;

  final AuthService authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    var user = authService.getCurrentUser();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (user != null) {
      email = user.email ?? "No Email";
      profileImagePath = prefs.getString('profile_image');

      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('Users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            username = userDoc['username'] ?? "No Username";
            phoneNumber = userDoc['phone'] ?? "No Phone";
            location = userDoc['location'] ?? "No Location";
            aboutMe = userDoc['about'] ?? "No Description";
          });
        } else {
          setState(() {
            username = "No Username";
            phoneNumber = "No Phone";
            location = "No Location";
            aboutMe = "No Description";
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
        setState(() {
          username = "Error loading username";
          phoneNumber = "Error loading phone";
          location = "Error loading location";
          aboutMe = "Error loading description";
        });
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickAndSaveImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', image.path);

      setState(() {
        profileImagePath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0), // Light grey background
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ✅ Profile Picture
                    GestureDetector(
                      onTap: pickAndSaveImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.deepPurple,
                            width: 4,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.black,
                          backgroundImage:
                              profileImagePath != null
                                  ? FileImage(File(profileImagePath!))
                                  : const AssetImage('assets/images/pfp.jpg')
                                      as ImageProvider,
                          child:
                              profileImagePath == null
                                  ? const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 35,
                                  )
                                  : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ✅ Container for User Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, // White container
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInfoContainer(
                            label: "User Email",
                            value: email ?? "No Email",
                            icon: Icons.email,
                          ),
                          _buildInfoContainer(
                            label: "User Name",
                            value: username ?? "Loading...",
                            icon: Icons.person,
                          ),
                          _buildInfoContainer(
                            label: "Phone Number",
                            value: phoneNumber ?? "No Phone",
                            icon: Icons.phone,
                          ),
                          _buildInfoContainer(
                            label: "Location",
                            value: location ?? "No Location",
                            icon: Icons.location_on,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ✅ About Me Section (Outside the container)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, // White container
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "About Me",
                            style: GoogleFonts.poppins(
                              color: Colors.deepPurple,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            aboutMe ?? "No description available.",
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ✅ My Details Section
                    _buildSectionTile(
                      context,
                      icon: Icons.person,
                      label: "My Details",
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DetailsPage(),
                          ),
                        );
                        // Refresh the profile page after returning
                        fetchUserData();
                      },
                    ),

                    const SizedBox(height: 30),

                    // ✅ About Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, // White container
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "💼  AppliedPlus: Your all-in-one job application tracker.🌐fetch job posts from LinkedIn, Indeed, and Unstop. ✅ Stay organized, track your applications, and boost your chances of landing your dream job!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black, // Black text
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }

  // 🛠️ Helper Method for User Info Container
  Widget _buildInfoContainer({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      leading: Icon(icon, color: Colors.deepPurple, size: 28),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.deepPurple,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSectionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: Colors.deepPurple, size: 28),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black),
      onTap: onTap,
    );
  }
}
