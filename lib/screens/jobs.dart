import 'package:appliedjobs/services/api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  late Future<List<dynamic>> _jobsFuture;
  Set<String> bookmarkedJobIds = {};

  @override
  void initState() {
    super.initState();
    _jobsFuture = _loadJobs();
    _loadBookmarkedJobs();
  }

  Future<List<dynamic>> _loadJobs() async {
    try {
      final jobs = await ApiService().fetchJobs(pages: 5);
      if (kDebugMode) {
        print("Jobs Fetched (${jobs.length} jobs):");
        for (var job in jobs) {
          print("🔹 ${job['job_title']} at ${job['employer_name']}");
        }
      }
      return jobs;
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching jobs: $e");
      return [];
    }
  }

  Future<void> _loadBookmarkedJobs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('bookmarks')
            .get();

    setState(() {
      bookmarkedJobIds = snapshot.docs.map((doc) => doc.id.toString()).toSet();
    });
  }

  void _bookmarkJob(Map<String, dynamic> job) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to bookmark jobs")),
      );
      return;
    }

    final docId = job['job_id'] ?? job['job_title'];
    final docRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(docId);

    try {
      if (bookmarkedJobIds.contains(docId)) {
        await docRef.delete();
        setState(() {
          bookmarkedJobIds.remove(docId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Removed from bookmarks")));
      } else {
        await docRef.set({
          'job_title': job['job_title'],
          'company': job['employer_name'],
          'job_description': job['job_description'],
          'job_apply_link': job['job_apply_link'],
          'employer_logo': job['employer_logo'],
          'job_publisher': job['job_publisher'],
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() {
          bookmarkedJobIds.add(docId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job bookmarked successfully")),
        );
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error bookmarking job: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update bookmark")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: FutureBuilder<List<dynamic>>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No jobs found.',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
            );
          }

          final jobs = snapshot.data!;
          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              final platform = job['job_publisher'] ?? 'Unknown Platform';
              final companyLogo = job['employer_logo'];
              final company = job['employer_name'] ?? 'Unknown Company';
              final jobId = job['job_id'] ?? job['job_title'];

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading:
                      companyLogo != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              companyLogo,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/office.jpg',
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                          ),
                  title: Text(
                    job['job_title'] ?? 'No Title',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company,
                        style: GoogleFonts.poppins(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "Platform: $platform",
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          bookmarkedJobIds.contains(jobId)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: Colors.green,
                        ),
                        onPressed: () => _bookmarkJob(job),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.green,
                        size: 18,
                      ),
                    ],
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            backgroundColor: Colors.black,
                            title: Text(
                              job['job_title'] ?? 'Job Details',
                              style: GoogleFonts.poppins(color: Colors.green),
                            ),
                            content: SizedBox(
                              height: 300,
                              child: SingleChildScrollView(
                                child: Text(
                                  job['job_description'] ?? 'No Description',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Close',
                                  style: GoogleFonts.poppins(
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  final url = job['job_apply_link'];
                                  if (url != null) {
                                    Navigator.pop(context);
                                    _launchURL(url);
                                  }
                                },
                                child: Text(
                                  'Apply',
                                  style: GoogleFonts.poppins(
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not launch URL")));
    }
  }
}
