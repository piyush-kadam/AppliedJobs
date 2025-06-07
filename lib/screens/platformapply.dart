import 'package:appliedjobs/screens/apply.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';

class PlatformApplyPage extends StatefulWidget {
  final Map<String, dynamic> job;
  final bool isTypeA;

  const PlatformApplyPage({
    super.key,
    required this.job,
    required this.isTypeA,
  });

  @override
  State<PlatformApplyPage> createState() => _PlatformApplyPageState();
}

class _PlatformApplyPageState extends State<PlatformApplyPage>
    with WidgetsBindingObserver {
  bool _isApplicationInProgress = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    // Register this widget as an observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove the observer when disposing the widget
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is resumed after being paused (user comes back from browser)
    if (state == AppLifecycleState.resumed && _isApplicationInProgress) {
      _showApplicationFollowUpDialog();
      // Reset the flag
      _isApplicationInProgress = false;
    }
  }

  // Clean unwanted characters from description
  String cleanDescription(String text) {
    return text.replaceAll(RegExp(r'[^\x20-\x7E\n]'), '').trim();
  }

  List<Widget> formatDescription(String rawText) {
    final lines = cleanDescription(rawText).split('\n');
    List<Widget> widgets = [];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.contains(':')) {
        // If line has ":", split and bold the first part
        final parts = trimmed.split(':');
        final title = parts[0].trim();
        final rest = parts.sublist(1).join(':').trim();

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.6,
                ),
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: rest),
                ],
              ),
            ),
          ),
        );
      } else {
        // Else, show it as a bullet point
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("•  ", style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    trimmed,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  // Show follow-up dialog when user returns to the app
  Future<void> _showApplicationFollowUpDialog() async {
    // Add a slight delay to ensure the context is fully built
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    print('Showing application follow-up dialog');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Did you apply?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Did you complete the job application?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              child: Text(
                'No',
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
              onPressed: () {
                print('User indicated they did NOT apply');
                Navigator.of(context).pop();
                // Reset the swipe button
                setState(() {
                  _isFinished = false;
                });
              },
            ),
            TextButton(
              child: Text(
                'Yes',
                style: GoogleFonts.poppins(color: Color(0xFF3D47D1)),
              ),
              onPressed: () async {
                print('User indicated they DID apply');
                Navigator.of(context).pop();

                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Saving your application...',
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );

                // Add a slight delay before saving
                await Future.delayed(const Duration(milliseconds: 500));

                // Add to applied jobs
                await _addToAppliedJobs();

                if (mounted) {
                  _showSuccessSnackbar();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Handle swipe action for external applications
  Future<void> _handleExternalApply() async {
    final applyLink = widget.isTypeA ? widget.job['job_apply_link'] : null;

    if (applyLink != null) {
      // Set flag to indicate application in progress
      _isApplicationInProgress = true;

      final Uri uri = Uri.parse(applyLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _isApplicationInProgress = false; // Reset flag if URL launch fails
        setState(() {
          _isFinished = false; // Reset swipe button
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not launch application URL',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle swipe action for platform applications
  Future<void> _handlePlatformApply() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Apply(jobId: widget.job['id'])),
    );

    // Reset the swipe button after navigation
    setState(() {
      _isFinished = false;
    });
  }

  // Add job to user's applied jobs collection
  Future<void> _addToAppliedJobs() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Cannot add to applied jobs: User is not logged in');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: You need to be logged in to track applications',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final job = widget.job;

      // Extract fields
      final jobType = _extractJobType(job['job_description'] ?? '');
      final location = _extractLocation(job);
      final salary = _extractSalary(job['job_description'] ?? '');
      final experience = _extractExperience(job['job_description'] ?? '');
      final companyLogo = job['employer_logo'] ?? '';

      final jobId =
          job['id'] ??
          job['job_id'] ??
          job['_id'] ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final jobData = {
        'jobId': jobId,
        'title': widget.isTypeA ? job['job_title'] : job['title'] ?? 'No Title',
        'companyName':
            widget.isTypeA
                ? (job['employer_name'] ?? 'Unknown Company')
                : (job['company_name'] ?? 'Unknown Company'),
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'Applied',
        'applicationMethod': 'External',
        // Fixed field names to match AppliedJobCard expectations
        'employmentType': jobType, // Changed from 'jobType' to 'employmentType'
        'location': location,
        'salaryRange': salary, // Changed from 'salary' to 'salaryRange'
        'experienceLevel':
            experience, // Changed from 'experience' to 'experienceLevel'
        'companyLogo': companyLogo,
        'jobData': _sanitizeJobData(job),
      };

      final docRef =
          FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .collection('appliedjobs')
              .doc(); // auto-ID

      await docRef.set(jobData);
      print('Job saved with extracted fields.');
    } catch (e, stackTrace) {
      print('Error adding to applied jobs: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving your application: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String? _extractJobType(String? description) {
    if (description == null) return null;

    final lowercaseDesc = description.toLowerCase();
    if (lowercaseDesc.contains('full-time') ||
        lowercaseDesc.contains('full time')) {
      return 'Full-time';
    } else if (lowercaseDesc.contains('part-time') ||
        lowercaseDesc.contains('part time')) {
      return 'Part-time';
    } else if (lowercaseDesc.contains('contract')) {
      return 'Contract';
    } else if (lowercaseDesc.contains('internship')) {
      return 'Internship';
    } else if (lowercaseDesc.contains('remote')) {
      return 'Remote';
    }
    return null;
  }

  // Helper function to extract location from job data
  String? _extractLocation(Map<String, dynamic> job) {
    return job['job_city'] ??
        job['job_country'] ??
        (job['job_description'] != null &&
                job['job_description'].toString().contains('Location:')
            ? _extractLocationFromDesc(job['job_description'])
            : null);
  }

  String? _extractLocationFromDesc(String description) {
    final locationMatch = RegExp(
      r'Location:\s*([^,\n]+)',
    ).firstMatch(description);
    return locationMatch?.group(1)?.trim();
  }

  // Helper function to extract salary from description
  String? _extractSalary(String? description) {
    if (description == null) return null;

    final salaryRegex = RegExp(
      r'(\$\d+[\d,.]*\s*[-–]\s*\$?\d+[\d,.]*\s*(k|K|thousand|million)?|(\$\d+[\d,.]*\s*(k|K|thousand|million)?(\s*per\s*(year|month|hour|annum)))|(salary:?\s*\$\d+[\d,.]*\s*[-–]\s*\$?\d+[\d,.]*))',
      caseSensitive: false,
    );
    final match = salaryRegex.firstMatch(description);
    return match?.group(0);
  }

  // Helper function to extract experience level
  String? _extractExperience(String? description) {
    if (description == null) return null;

    final lowercaseDesc = description.toLowerCase();
    if (lowercaseDesc.contains('entry level') ||
        lowercaseDesc.contains('0-1 year') ||
        lowercaseDesc.contains('junior') ||
        lowercaseDesc.contains('no experience')) {
      return 'Entry Level';
    } else if (lowercaseDesc.contains('mid level') ||
        lowercaseDesc.contains('2-5 years') ||
        lowercaseDesc.contains('intermediate')) {
      return 'Mid Level';
    } else if (lowercaseDesc.contains('senior') ||
        lowercaseDesc.contains('5+ years') ||
        lowercaseDesc.contains('experienced')) {
      return 'Senior';
    }

    // Try to extract years of experience
    final expRegex = RegExp(
      r'(\d+)[\+]?\s*[\-]?\s*(\d+)?\s+years?\s+(?:of\s+)?experience',
      caseSensitive: false,
    );
    final match = expRegex.firstMatch(lowercaseDesc);
    if (match != null) {
      final minYears = int.tryParse(match.group(1) ?? '0') ?? 0;
      if (minYears <= 1) {
        return 'Entry Level';
      } else if (minYears <= 5) {
        return 'Mid Level';
      } else {
        return 'Senior';
      }
    }

    return null;
  }

  // Sanitize job data to ensure it can be stored in Firestore
  Map<String, dynamic> _sanitizeJobData(Map<String, dynamic> job) {
    // Create a new map to hold sanitized data
    final Map<String, dynamic> sanitized = {};

    // Process each entry
    job.forEach((key, value) {
      // Skip null values
      if (value == null) return;

      // Handle different types appropriately
      if (value is String ||
          value is num ||
          value is bool ||
          value is List ||
          value is Map) {
        sanitized[key] = value;
      } else {
        // Convert other types to string
        sanitized[key] = value.toString();
      }
    });

    return sanitized;
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added to your applied jobs!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobTitle =
        (widget.isTypeA ? widget.job['job_title'] : widget.job['title']) ??
        'No Title';
    final description =
        widget.job['job_description'] ??
        widget.job['description'] ??
        'No Description';
    final applyLink = widget.isTypeA ? widget.job['job_apply_link'] : null;
    final hasLogo = widget.isTypeA && widget.job['employer_logo'] != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF3D47D1),
        elevation: 0,
        title: Text(
          'Job Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Company Logo
                  hasLogo
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.job['employer_logo'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/ap.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                  const SizedBox(height: 16),

                  // Job Title
                  Text(
                    jobTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Job Description Section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Description',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...formatDescription(description),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SwipeableButtonView(
          buttonText:
              widget.isTypeA && applyLink != null
                  ? '      Apply for this position'
                  : 'Swipe to apply through platform',
          buttonWidget: Container(
            child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
          ),
          activeColor: Color(0xFF3D47D1),
          isFinished: _isFinished,
          onWaitingProcess: () {
            // Immediately finish without delay to remove animation
            setState(() {
              _isFinished = true;
            });
          },
          onFinish: () async {
            if (widget.isTypeA && applyLink != null) {
              await _handleExternalApply();
            } else {
              await _handlePlatformApply();
            }
            // Reset the button state after action
            setState(() {
              _isFinished = false;
            });
          },
          buttonColor: Colors.white,
          buttontextstyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
