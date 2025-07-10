import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appliedjobs/screens/resume.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';

class Apply extends StatefulWidget {
  final String jobId;

  const Apply({super.key, required this.jobId});

  @override
  State<Apply> createState() => _ApplyState();
}

class _ApplyState extends State<Apply> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool isFinished = false;
  Map<String, dynamic>? _jobData;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

  final Color primaryColor = Colors.deepPurple;
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF333333);
  final Color textSecondaryColor = const Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User not signed in';
          _isLoading = false;
        });
        return;
      }

      final jobDoc =
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(widget.jobId)
              .get();

      if (!jobDoc.exists) {
        setState(() {
          _errorMessage = 'Job not found';
          _isLoading = false;
        });
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(currentUser.uid)
              .get();

      if (!userDoc.exists) {
        setState(() {
          _errorMessage = 'User profile not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _jobData = jobDoc.data();
        _userData = userDoc.data();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitApplication() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Create the application in job applications subcollection
      final jobAppRef =
          FirebaseFirestore.instance
              .collection('jobs')
              .doc(widget.jobId)
              .collection('applications')
              .doc();

      final applicationData = {
        'applicationId': jobAppRef.id,
        'userId': currentUser.uid,
        'companyName': _jobData!['companyName'],
        'jobTitle': _jobData!['title'],
        'applicantName': _userData!['username'] ?? 'Not provided',
        'applicantpfp': _userData!['profileImageUrl'] ?? 'Not provided',
        'applicantEmail': _userData!['email'] ?? 'Not provided',
        'applicantPhone': _userData!['phone'] ?? 'Not provided',
        'applicantLocation': _userData!['location'] ?? 'Not provided',
        'applicantAbout': _userData!['about'] ?? 'Not provided',
        'resumeUrl': _userData!['resumeUrl'] ?? 'Not provided',
        'resumeName': _userData!['resumeName'] ?? 'Not provided',
        'educationHistory': _userData!['educationHistory'] ?? [],
        'workExperiences': _userData!['workExperiences'] ?? [],
        'skills': _userData!['skills'] ?? [],
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      };

      await jobAppRef.set(applicationData);

      // Save in user's `appliedjobs` subcollection
      final userAppliedJobRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .collection('appliedjobs')
          .doc(widget.jobId);

      await userAppliedJobRef.set({
        'jobId': widget.jobId,
        'companyName': _jobData!['companyName'],
        'companyLogoUrl': _jobData!['companyLogoUrl'],
        'title': _jobData!['title'],
        'location': _jobData!['location'],
        'employmentType': _jobData!['employmentType'],
        'salaryRange': _jobData!['salaryRange'],
        'experienceLevel': _jobData!['experienceLevel'],
        'appliedAt': FieldValue.serverTimestamp(),
        'applicationId': jobAppRef.id,
        'status': 'pending',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Application submitted successfully',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          duration: Duration(seconds: 2),
          elevation: 6,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'Job Application',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Color(0xFF3D47D1),
          elevation: 0,
        ),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'Job Application',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryColor,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            _errorMessage!,
            style: GoogleFonts.poppins(color: textPrimaryColor, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Job Application',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF3D47D1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job info card
                _buildJobInfoCard(),
                const SizedBox(height: 24),

                // Your info section
                Text(
                  'Your Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildUserInfoCard(),

                // Resume section

                // Education section
                if (_userData!['educationHistory'] != null &&
                    (_userData!['educationHistory'] as List).isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildEducationSection(),
                ],

                // Work Experience section
                if (_userData!['workExperiences'] != null &&
                    (_userData!['workExperiences'] as List).isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildWorkExperienceSection(),
                ],

                if (_userData!['resumeUrl'] != null) ...[
                  const SizedBox(height: 24),
                  _buildResumeSection(),
                ],

                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: SwipeableButtonView(
                    buttonText: "Submit Application",
                    buttontextstyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    buttonWidget: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF3D47D1),
                    ),
                    activeColor: Color(0xFF3D47D1),
                    isFinished: isFinished,
                    onWaitingProcess: () async {
                      setState(() {
                        _isSubmitting = true;
                      });

                      await _submitApplication(); // your submit function

                      setState(() {
                        isFinished = true;
                        _isSubmitting = false;
                      });
                    },
                    onFinish: () async {
                      // Optionally show a confirmation or pop a screen
                      await Future.delayed(Duration(seconds: 1));
                      setState(() {
                        isFinished = false; // Reset to allow resubmission
                      });
                    },
                  ),
                ),

                // Added spacing after submit button
                const SizedBox(height: 50), // Extra space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        // <-- added scrollable safety
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _jobData!['title'] ?? 'Job Title',
              style: GoogleFonts.poppins(
                color: textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _jobData!['companyName'] ?? 'Company Name',
              style: GoogleFonts.poppins(
                color: textSecondaryColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              // <-- safer than two Rows
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildJobDetailItem(
                  Icons.location_on,
                  _jobData!['location'] ?? 'Location',
                ),
                _buildJobDetailItem(
                  Icons.work,
                  _jobData!['employmentType'] ?? 'Employment Type',
                ),
                _buildJobDetailItem(
                  Icons.currency_rupee,
                  _jobData!['salaryRange'] ?? 'Salary Range',
                ),
                _buildJobDetailItem(
                  Icons.school,
                  _jobData!['experienceLevel'] ?? 'Experience Level',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Description',
              style: GoogleFonts.poppins(
                color: textPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _jobData!['description'] ?? 'No description provided.',
              style: GoogleFonts.poppins(
                color: textSecondaryColor,
                fontSize: 14,
              ),
            ),
            if (_jobData!['skills'] != null &&
                (_jobData!['skills'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Skills Required',
                style: GoogleFonts.poppins(
                  color: textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    (_jobData!['skills'] as List).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF3D47D1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFF3D47D1).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          skill,
                          style: GoogleFonts.poppins(
                            color: Color(0xFF3D47D1),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: textSecondaryColor, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(color: textSecondaryColor, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  'Name:',
                  style: GoogleFonts.poppins(
                    color: textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _userData!['username'] ?? 'Not provided',
                  style: GoogleFonts.poppins(color: textPrimaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Email
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  'Email:',
                  style: GoogleFonts.poppins(
                    color: textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _userData!['email'] ?? 'Not provided',
                  style: GoogleFonts.poppins(color: textPrimaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Phone
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  'Phone:',
                  style: GoogleFonts.poppins(
                    color: textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _userData!['phone'] ?? 'Not provided',
                  style: GoogleFonts.poppins(color: textPrimaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  'Location:',
                  style: GoogleFonts.poppins(
                    color: textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _userData!['location'] ?? 'Not provided',
                  style: GoogleFonts.poppins(color: textPrimaryColor),
                ),
              ),
            ],
          ),

          // About
          if (_userData!['about'] != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    'About:',
                    style: GoogleFonts.poppins(
                      color: textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _userData!['about'],
                    style: GoogleFonts.poppins(color: textPrimaryColor),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResumeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resume',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: Color(0xFF3D47D1), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _userData!['resumeName'] ?? 'Resume',
                      style: GoogleFonts.poppins(
                        color: textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ResumeViewerPage(
                                url: _userData!['resumeUrl'],
                              ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.visibility,
                      color: Color(0xFF3D47D1),
                      size: 18,
                    ),
                    label: Text(
                      'View',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF3D47D1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEducationSection() {
    final educationData = _userData!['educationHistory'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Education',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < educationData.length; i++) ...[
                if (i > 0) const Divider(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      educationData[i]['university'] ?? 'Not specified',
                      style: GoogleFonts.poppins(
                        color: textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      educationData[i]['degree'] ?? 'Not specified',
                      style: GoogleFonts.poppins(
                        color: textPrimaryColor,
                        fontSize: 14,
                      ),
                    ),
                    if (educationData[i]['fieldOfStudy'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        educationData[i]['fieldOfStudy'],
                        style: GoogleFonts.poppins(
                          color: textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (educationData[i]['startYear'] != null ||
                        educationData[i]['endYear'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${educationData[i]['startYear'] ?? ''} - ${educationData[i]['endYear'] ?? 'Present'}',
                        style: GoogleFonts.poppins(
                          color: textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (educationData[i]['grade'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Grade: ${educationData[i]['grade']}',
                        style: GoogleFonts.poppins(
                          color: textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkExperienceSection() {
    final workExperiences = _userData!['workExperiences'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work Experience',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < workExperiences.length; i++) ...[
                if (i > 0) const Divider(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workExperiences[i]['employmentType'] ?? 'Not specified',
                      style: GoogleFonts.poppins(
                        color: textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workExperiences[i]['company'] ?? 'Not specified',
                      style: GoogleFonts.poppins(
                        color: textPrimaryColor,
                        fontSize: 14,
                      ),
                    ),
                    if (workExperiences[i]['startDate'] != null ||
                        workExperiences[i]['endDate'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${workExperiences[i]['startDate'] ?? ''} - ${workExperiences[i]['endDate'] ?? 'Present'}',
                        style: GoogleFonts.poppins(
                          color: textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (workExperiences[i]['location'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        workExperiences[i]['location'],
                        style: GoogleFonts.poppins(
                          color: textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (workExperiences[i]['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        workExperiences[i]['description'],
                        style: GoogleFonts.poppins(
                          color: textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
