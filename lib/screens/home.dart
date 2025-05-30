// import 'dart:io';
// import 'package:appliedjobs/auth/authservice.dart';
// import 'package:appliedjobs/screens/applied_jobs.dart';
// import 'package:appliedjobs/screens/jobs.dart';
// import 'package:appliedjobs/screens/profile.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   int _selectedIndex = 0;
//   bool isJoined = false;
//   String username = '';
//   final AuthService authService = AuthService();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Getter for _pages
//   List<Widget> get _pages => [
//     JobsPage(),
//     const AppliedPage(),
//     const ProfilePage(),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _checkIfUserJoined();
//   }

//   Future<void> _checkIfUserJoined() async {
//     try {
//       final user = authService.getCurrentUser();
//       if (user != null) {
//         DocumentSnapshot userDoc =
//             await _firestore.collection('Users').doc(user.uid).get();

//         if (userDoc.exists && userDoc['username'] != null) {
//           setState(() {
//             isJoined = true;
//             username = userDoc['username'];
//           });
//         }
//       }
//     } catch (e) {
//       print("Error checking user: $e");
//     }
//   }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   Future<String?> _getProfileImageUrl() async {
//     final user = authService.getCurrentUser();
//     if (user != null) {
//       DocumentSnapshot userDoc =
//           await _firestore.collection('Users').doc(user.uid).get();
//       if (userDoc.exists && userDoc.data() != null) {
//         final data = userDoc.data() as Map<String, dynamic>;
//         return data['profileImageUrl'] as String?;
//       }
//     }
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBody: true,
//       appBar: AppBar(
//         title: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             children: [
//               ClipOval(
//                 child: Image.asset(
//                   'assets/images/plus.png',
//                   width: 36,
//                   height: 36,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 "AppliedPlus",
//                 style: GoogleFonts.poppins(
//                   color: Color(0xFF3D47D1),
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),

//         centerTitle: true,
//         backgroundColor: const Color(0xFFE0E0E0),
//         actions: [
//           FutureBuilder<String?>(
//             future: _getProfileImageUrl(),
//             builder: (context, snapshot) {
//               final imageUrl = snapshot.data;
//               return Padding(
//                 padding: const EdgeInsets.only(right: 16),
//                 child: GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _selectedIndex = 2; // Profile tab index
//                     });
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.all(2),
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Color(0xFF3D47D1), width: 2),
//                     ),
//                     child: CircleAvatar(
//                       radius: 18,
//                       backgroundColor: Colors.black,
//                       backgroundImage:
//                           imageUrl != null ? NetworkImage(imageUrl) : null,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//         automaticallyImplyLeading: false,
//       ),

//       body: _pages[_selectedIndex],

//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(30),
//             border: Border.all(
//               color: Colors.grey[400]!, // a light grey border
//               width: 1.0, // you can adjust thickness as needed
//             ),
//             boxShadow: [
//               BoxShadow(
//                 blurRadius: 20,
//                 color: Colors.black.withOpacity(0.1),
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildNavItem(0, Icons.work_outline, 'Jobs'),
//                 _buildNavItem(
//                   1,
//                   Icons.assignment_turned_in_outlined,
//                   'Applied',
//                 ),
//                 _buildNavItem(2, Icons.person_outline, 'Profile'),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(int index, IconData icon, String label) {
//     bool isSelected = _selectedIndex == index;
//     return InkWell(
//       onTap: () => _onItemTapped(index),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Top indicator line when selected
//           Container(
//             height: 3,
//             width: 30,
//             margin: const EdgeInsets.only(bottom: 8),
//             decoration: BoxDecoration(
//               color: isSelected ? const Color(0xFF3D47D1) : Colors.transparent,
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           Icon(
//             icon,
//             color: isSelected ? const Color(0xFF3D47D1) : Colors.black,
//             size: 24,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               color: isSelected ? const Color(0xFF3D47D1) : Colors.grey,
//               fontSize: 12,
//               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//               fontFamily: GoogleFonts.poppins().fontFamily,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:appliedjobs/auth/authservice.dart';
import 'package:appliedjobs/models/filter_model.dart';
import 'package:appliedjobs/notification/notification_services.dart';
import 'package:appliedjobs/screens/applied_jobs.dart';
import 'package:appliedjobs/screens/job_filter_modal.dart';
import 'package:appliedjobs/screens/jobs.dart';
import 'package:appliedjobs/screens/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NotificationServices notificationServices = NotificationServices();

  int _selectedIndex = 0;
  bool isJoined = false;
  String username = '';
  final AuthService authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Filter overlay state
  bool _showGlobalFilterBox = false;
  JobFilters _currentFilters = JobFilters();

  // These will be set by JobsPage for unique lists
  List<String> _uniqueRoles = [];
  List<String> _uniqueLocations = [];
  List<String> _uniqueCompanies = [];
  final List<String> _applicationStatuses = [
    'All Jobs',
    'Applied',
    'Not Applied',
  ];
  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Remote',
  ];

  // Callback to show filter box from JobsPage
  void showFilterBox({
    required JobFilters currentFilters,
    required void Function(JobFilters) onApply,
    required void Function() onClear,
    required List<String> uniqueRoles,
    required List<String> uniqueLocations,
    required List<String> uniqueCompanies,
  }) {
    setState(() {
      _currentFilters = currentFilters;
      _uniqueRoles = uniqueRoles;
      _uniqueLocations = uniqueLocations;
      _uniqueCompanies = uniqueCompanies;
      _onApplyFilters = onApply;
      _onClearFilters = onClear;
      _showGlobalFilterBox = true;
    });
  }

  void hideFilterBox() {
    setState(() {
      _showGlobalFilterBox = false;
    });
  }

  // Store callbacks from JobsPage
  void Function(JobFilters)? _onApplyFilters;
  void Function()? _onClearFilters;

  // Getter for pages, pass showFilterBox and currentFilters to JobsPage
  List<Widget> get _pages => [
    JobsPage(showFilterBox: showFilterBox, currentFilters: _currentFilters),
    const AppliedPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize notification services
    notificationServices.requestNotificationPermission();
    notificationServices.forgroundMessage();
    notificationServices.firebaseInit(context); // to show dialogs/snackbars
    notificationServices.setupInteractMessage(
      context,
    ); // handle taps on notification

    notificationServices.getDeviceToken().then((value) {
      if (kDebugMode) {
        print('Device Token: $value');
      }
    });
    notificationServices.saveDeviceToken();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          appBar: AppBar(
            // ... your existing app bar code ...
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
                      color: const Color(0xFF3D47D1),
                      fontSize: 16,
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
                          border: Border.all(
                            color: const Color(0xFF3D47D1),
                            width: 2,
                          ),
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
                border: Border.all(color: Colors.grey[400]!, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8,
                ),
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
        ),
        // This overlay will cover everything, including the navigation bar!
        if (_showGlobalFilterBox)
          Positioned.fill(
            child: Material(
              color: Colors.black.withOpacity(0.32),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    hideFilterBox();
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.93,
                    child: GestureDetector(
                      onTap: () {}, // Prevent tap from closing overlay
                      child: JobFilterBox(
                        currentFilters: _currentFilters,
                        onApply: (filters) {
                          _onApplyFilters?.call(filters);
                          hideFilterBox();
                        },
                        onClear: () {
                          _onClearFilters?.call();
                          hideFilterBox();
                        },
                        onClose: hideFilterBox,
                        jobRoles: ['All Roles', ..._uniqueRoles],
                        locations: ['All Cities', ..._uniqueLocations],
                        applicationStatuses: _applicationStatuses,
                        companies: _uniqueCompanies,
                        jobTypes: _jobTypes,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
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
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF3D47D1) : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}
