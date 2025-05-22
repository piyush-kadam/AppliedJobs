import 'package:appliedjobs/auth/authservice.dart';
import 'package:appliedjobs/screens/details.dart';
import 'package:appliedjobs/screens/resume.dart';
import 'package:appliedjobs/user/start.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/rendering.dart';

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
  String? profileImageUrl;
  String? resumeUrl;
  String? resumeName;
  bool isLoading = true;
  final GlobalKey _initialsAvatarKey = GlobalKey();

  final AuthService authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupUserProfile();
    });
  }

  Future<void> fetchUserData() async {
    var user = authService.getCurrentUser();

    if (user != null) {
      email = user.email ?? "No Email";

      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('Users').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          setState(() {
            username = data?['username'] ?? "No Username";
            phoneNumber = data?['phone'] ?? "No Phone";
            location = data?['location'] ?? "No Location";
            aboutMe = data?['about'] ?? "No Description";
            resumeUrl = data?['resumeUrl'];
            resumeName = data?['resumeName'];
            profileImageUrl = data?['profileImageUrl'];
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

  // Create initials avatar for users without profile pictures
  Widget buildInitialsAvatar() {
    String initials = "";
    if (username != null && username!.isNotEmpty) {
      List<String> nameParts = username!.split(" ");
      if (nameParts.isNotEmpty) {
        initials += nameParts[0][0].toUpperCase();
        if (nameParts.length > 1) {
          initials += nameParts[1][0].toUpperCase();
        }
      }
    } else if (email != null && email!.isNotEmpty) {
      initials = email![0].toUpperCase();
    }

    return RepaintBoundary(
      key: _initialsAvatarKey,
      child: CircleAvatar(
        radius: 70,
        backgroundColor: Colors.black,
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Method to capture initials avatar as an image
  Future<Uint8List?> captureInitialsAvatar() async {
    try {
      // Ensure the widget is built and rendered before trying to capture it
      await Future.delayed(const Duration(milliseconds: 500));

      final RenderRepaintBoundary? boundary =
          _initialsAvatarKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        print("Error: Could not find RenderRepaintBoundary");
        return null;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }

      return null;
    } catch (e) {
      print("Error capturing avatar: $e");
      return null;
    }
  }

  Future<void> removeProfilePicture() async {
    final user = authService.getCurrentUser();

    if (user != null) {
      try {
        setState(() {
          isLoading = true;
        });

        // Create and upload initials avatar instead of deleting
        await uploadInitialsAvatar(user.uid);
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Error updating profile picture: $e",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Add this method to your class to create an initials avatar on user signup/login
  Future<void> setupUserProfile() async {
    final user = authService.getCurrentUser();

    if (user != null) {
      try {
        // Check if the user already has a profile image
        DocumentSnapshot userDoc =
            await _firestore.collection('Users').doc(user.uid).get();

        // If user doesn't have a profile image URL, create an initials avatar
        if (userDoc.exists &&
            (userDoc.data() as Map<String, dynamic>)['profileImageUrl'] ==
                null) {
          setState(() {
            isLoading = true;
          });

          // Generate and upload the initials avatar
          await uploadInitialsAvatar(user.uid);
        }
      } catch (e) {
        print("Error setting up user profile: $e");
      }
    }
  }

  // New method to handle creating and uploading initials avatar
  Future<void> uploadInitialsAvatar(String userId) async {
    try {
      // Get current user data to ensure we have the latest username/email
      DocumentSnapshot userDoc =
          await _firestore.collection('Users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception("User document not found");
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? userName = userData['username'] as String?;
      String? userEmail = userData['email'] as String?;

      // Create initials based on username or email
      String initials = "";
      if (userName != null && userName.isNotEmpty) {
        List<String> nameParts = userName.split(" ");
        if (nameParts.isNotEmpty) {
          initials += nameParts[0][0].toUpperCase();
          if (nameParts.length > 1) {
            initials += nameParts[1][0].toUpperCase();
          }
        }
      } else if (userEmail != null && userEmail.isNotEmpty) {
        initials = userEmail[0].toUpperCase();
      }

      // Create a temporary RepaintBoundary for capturing
      final tempKey = GlobalKey();
      final repaintBoundary = RepaintBoundary(
        key: tempKey,
        child: CircleAvatar(
          radius: 70,
          backgroundColor: Colors.black,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      // Add the temporary widget to the tree temporarily
      final overlayState = Overlay.of(context);
      final entry = OverlayEntry(
        builder:
            (context) => Positioned(
              left: -500, // Position off-screen
              top: -500,
              child: Material(
                type: MaterialType.transparency,
                child: repaintBoundary,
              ),
            ),
      );

      overlayState.insert(entry);

      // Give it time to render
      await Future.delayed(const Duration(milliseconds: 1000));

      // Capture the image
      final RenderRepaintBoundary boundary =
          tempKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      // Remove the temporary overlay
      entry.remove();

      if (byteData == null) {
        throw Exception("Failed to capture initials avatar image");
      }

      final Uint8List bytes = byteData.buffer.asUint8List();

      // Create a temporary file from the captured image
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/initials_avatar.png');
      await tempFile.writeAsBytes(bytes);

      // Upload the initials avatar to Supabase
      final String fileName = 'profile_$userId.jpg';
      final String filePath = 'profiles/$fileName';

      final storage = Supabase.instance.client.storage;
      await storage
          .from('pfp')
          .upload(
            filePath,
            tempFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Add timestamp to URL to force refresh cached images
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String imageUrl =
          "${storage.from('pfp').getPublicUrl(filePath)}?t=$timestamp";

      // Update the Firestore document with the new URL
      await _firestore.collection('Users').doc(userId).update({
        'profileImageUrl': imageUrl,
      });

      // Clean up the temporary file
      await tempFile.delete();
      await tempDir.delete(recursive: true);

      if (mounted) {
        setState(() {
          profileImageUrl = imageUrl;
          isLoading = false;
        });
      }

      // Show success message only if we're removing a profile picture
      // (not during initial setup)
      if (context.mounted && userData['profileImageUrl'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Profile picture updated to initials",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("Error in uploadInitialsAvatar: $e");

      // Fallback if we couldn't create the initials avatar
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Could not create initials avatar. Try uploading a photo instead.",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> pickAndSaveImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      final File file = File(image.path);
      final user = authService.getCurrentUser();

      if (user != null) {
        try {
          setState(() {
            isLoading = true;
          });

          // Use consistent file name based on user ID
          final String fileName = 'profile_${user.uid}.jpg';
          final String filePath = 'profiles/$fileName';

          // Upload to Supabase pfp bucket with upsert to replace existing file
          final storage = Supabase.instance.client.storage;
          await storage
              .from('pfp')
              .upload(
                filePath,
                file,
                fileOptions: const FileOptions(upsert: true),
              );

          // Add timestamp to URL to force refresh cached images
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final String imageUrl =
              "${storage.from('pfp').getPublicUrl(filePath)}?t=$timestamp";

          // Save URL to Firestore
          await _firestore.collection('Users').doc(user.uid).update({
            'profileImageUrl': imageUrl,
          });

          setState(() {
            profileImageUrl = imageUrl;
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Profile picture updated successfully",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        } catch (e) {
          setState(() {
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Error uploading profile picture: $e",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
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
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFF3D47D1),
                              width: 4,
                            ),
                          ),
                          child:
                              profileImageUrl != null
                                  ? CircleAvatar(
                                    radius: 70,
                                    backgroundColor: Colors.black,
                                    backgroundImage: NetworkImage(
                                      profileImageUrl!,
                                    ),
                                  )
                                  : buildInitialsAvatar(),
                        ),
                        // Row(
                        //   mainAxisSize: MainAxisSize.min,
                        //   children: [
                        //     if (profileImageUrl != null)
                        //       Container(
                        //         decoration: BoxDecoration(
                        //           color: Colors.white,
                        //           shape: BoxShape.circle,
                        //           boxShadow: [
                        //             BoxShadow(
                        //               color: Colors.black.withOpacity(0.2),
                        //               blurRadius: 4,
                        //               offset: const Offset(0, 2),
                        //             ),
                        //           ],
                        //         ),
                        //         child: IconButton(
                        //           icon: const Icon(
                        //             Icons.delete,
                        //             color: Colors.red,
                        //             size: 24,
                        //           ),
                        //           onPressed: removeProfilePicture,
                        //         ),
                        //       ),
                        //     const SizedBox(width: 8),
                        //     Container(
                        //       decoration: BoxDecoration(
                        //         color: Color(0xFF3D47D1),
                        //         shape: BoxShape.circle,
                        //         boxShadow: [
                        //           BoxShadow(
                        //             color: Colors.black.withOpacity(0.2),
                        //             blurRadius: 4,
                        //             offset: const Offset(0, 2),
                        //           ),
                        //         ],
                        //       ),
                        //       child: IconButton(
                        //         icon: const Icon(
                        //           Icons.edit,
                        //           color: Colors.white,
                        //           size: 24,
                        //         ),
                        //         onPressed: pickAndSaveImage,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (profileImageUrl != null)
                              // Container(
                              //   padding: const EdgeInsets.only(bottom: 8.0),
                              //   width:
                              //       48, // Ensure both containers are the same size
                              //   height: 48,
                              //   decoration: BoxDecoration(
                              //     color: Colors.white,
                              //     shape: BoxShape.circle,
                              //     boxShadow: [
                              //       BoxShadow(
                              //         color: Colors.black.withOpacity(0.2),
                              //         blurRadius: 4,
                              //         offset: const Offset(0, 2),
                              //       ),
                              //     ],
                              //   ),
                              //   child: IconButton(
                              //     icon: const Icon(
                              //       Icons.delete,
                              //       color: Colors.red,
                              //       size: 24,
                              //     ),
                              //     onPressed: removeProfilePicture,
                              //     padding:
                              //         EdgeInsets.zero, // Remove extra padding
                              //     alignment:
                              //         Alignment.center, // Center the icon
                              //   ),
                              // ),
                              Transform.translate(
                                offset: const Offset(
                                  0,
                                  8,
                                ), // Move down by 8 pixels
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                                    onPressed: removeProfilePicture,
                                    padding: EdgeInsets.zero,
                                    alignment: Alignment.center,
                                  ),
                                ),
                              ),

                            const SizedBox(width: 8),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Color(0xFF3D47D1),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: pickAndSaveImage,
                                padding: EdgeInsets.zero,
                                alignment: Alignment.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // User Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
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

                    // About Me
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "About Me",
                            style: GoogleFonts.poppins(
                              color: Color(0xFF3D47D1),
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
                        fetchUserData();
                      },
                    ),

                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Resume",
                            style: GoogleFonts.poppins(
                              color: Color(0xFF3D47D1),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (resumeUrl != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resumeName ?? "resume.pdf",
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ResumeViewerPage(
                                              url: resumeUrl!,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.remove_red_eye,
                                    size: 20,
                                  ),
                                  label: Text(
                                    "View Resume",
                                    style: GoogleFonts.poppins(
                                      color: Color(0xFF3D47D1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ElevatedButton.icon(
                            icon: Icon(
                              color: Colors.white,
                              resumeUrl == null
                                  ? Icons.upload_file
                                  : Icons.edit,
                            ),
                            label: Text(
                              resumeUrl == null
                                  ? "Upload Resume in PDF"
                                  : "Change Resume",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3D47D1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: uploadResume,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Text(
                          //   "💼  AppliedPlus: Your all-in-one job application tracker.🌐 Fetch job posts from LinkedIn, Indeed, and Unstop. ✅ Stay organized, track your applications, and boost your chances of landing your dream job!",
                          //   textAlign: TextAlign.center,
                          //   style: GoogleFonts.poppins(
                          //     color: Colors.black,
                          //     fontSize: 16,
                          //   ),
                          // ),
                          // Text(
                          //   "Mission:\nTo make job searching easy by bringing all jobs in one place, helping people find the right job quickly and easily.\n\nVision:\nTo be the most trusted job platform where everyone can find the right job without checking many different websites.",
                          //   textAlign: TextAlign.center,
                          //   style: GoogleFonts.poppins(
                          //     color: Colors.black,
                          //     fontWeight: FontWeight.bold,
                          //     fontSize: 16,
                          //   ),
                          // ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start, // Align all children to start (left)
                            children: [
                              Text(
                                "Mission:",
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ), // Small space after label
                              Text(
                                "To make job searching easy by bringing all jobs in one place, helping people find the right job quickly and easily.",
                                textAlign:
                                    TextAlign
                                        .start, // Align description text to start
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(
                                height: 16,
                              ), // Space between Mission and Vision
                              Text(
                                "Vision:",
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "To be the most trusted job platform where everyone can find the right job without checking many different websites.",
                                textAlign: TextAlign.start,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () async {
                              await authService.signOut();
                              if (context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const StartPage(),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              "Log Out",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }

  Future<void> uploadResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final user = authService.getCurrentUser();
      final originalFileName = result.files.single.name;
      final filePath = "resumes/${user!.uid}_resume.pdf"; // path in Supabase

      try {
        final storage = Supabase.instance.client.storage;
        await storage
            .from('resumes')
            .upload(
              filePath,
              file,
              fileOptions: const FileOptions(upsert: true),
            );

        // Add timestamp to force reload
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final urlWithTimestamp =
            "${storage.from('resumes').getPublicUrl(filePath)}?t=$timestamp";

        // Save URL and original filename to Firestore
        await _firestore.collection('Users').doc(user.uid).update({
          'resumeUrl': urlWithTimestamp,
          'resumeName': originalFileName,
        });

        setState(() {
          resumeUrl = urlWithTimestamp;
          resumeName = originalFileName; // Show actual uploaded file name
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Resume uploaded successfully",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Error uploading resume: $e",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildInfoContainer({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      leading: Icon(icon, color: Color(0xFF3D47D1), size: 28),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          color: Color(0xFF3D47D1),
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
      leading: Icon(icon, color: Color(0xFF3D47D1), size: 28),
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
