import 'package:appliedjobs/screens/platformapply.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appliedjobs/screens/apply.dart';
import 'package:intl/intl.dart';

class AppliedPage extends StatefulWidget {
  const AppliedPage({super.key});

  @override
  State<AppliedPage> createState() => _AppliedPageState();
}

class _AppliedPageState extends State<AppliedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFE0E0E0),
        body: Center(
          child: Text(
            "Please log in to view your jobs",
            style: GoogleFonts.poppins(color: Colors.black),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.all(9.0),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                child: Text(
                  'Bookmarks',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  'Applied Jobs',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search jobs...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
              ),
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Bookmarks Tab
                BookmarksTab(userId: user.uid, searchQuery: _searchQuery),

                // Applied Jobs Tab
                AppliedJobsTab(userId: user.uid, searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BookmarksTab extends StatelessWidget {
  final String userId;
  final String searchQuery;

  const BookmarksTab({
    super.key,
    required this.userId,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final bookmarksRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('bookmarks');

    return StreamBuilder<QuerySnapshot>(
      stream: bookmarksRef.orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No bookmarked jobs.',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
          );
        }

        // Filter jobs based on search query
        final filteredDocs =
            searchQuery.isEmpty
                ? docs
                : docs.where((doc) {
                  final job = doc.data() as Map<String, dynamic>;
                  final isTypeA = job.containsKey('job_title');
                  final jobTitle =
                      isTypeA
                          ? job['job_title'].toString().toLowerCase()
                          : (job['title'] ?? 'No Title')
                              .toString()
                              .toLowerCase();
                  final company =
                      isTypeA
                          ? (job['company'] ?? 'Unknown Company')
                              .toString()
                              .toLowerCase()
                          : (job['companyName'] ?? 'Unknown Company')
                              .toString()
                              .toLowerCase();
                  final publisher =
                      isTypeA
                          ? (job['job_publisher'] ?? '')
                              .toString()
                              .toLowerCase()
                          : (job['employmentType'] ?? '')
                              .toString()
                              .toLowerCase();

                  return jobTitle.contains(searchQuery) ||
                      company.contains(searchQuery) ||
                      publisher.contains(searchQuery);
                }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text(
              'No matching bookmarked jobs found.',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final job = filteredDocs[index].data() as Map<String, dynamic>;

            final isTypeA = job.containsKey('job_title');
            final jobTitle =
                isTypeA ? job['job_title'] : job['title'] ?? 'No Title';
            final company =
                isTypeA
                    ? job['company']
                    : job['companyName'] ?? 'Unknown Company';
            final publisher =
                isTypeA
                    ? "Platform: ${job['job_publisher'] ?? 'Unknown'}"
                    : "Type: ${job['employmentType'] ?? 'Unknown'}";
            final hasLogo = isTypeA && job['employer_logo'] != null;

            return BookmarkJobCard(
              job: job,
              docId: filteredDocs[index].id,
              jobTitle: jobTitle,
              company: company,
              publisher: publisher,
              hasLogo: hasLogo,
              isTypeA: isTypeA,
              collectionRef: bookmarksRef,
            );
          },
        );
      },
    );
  }
}

class AppliedJobsTab extends StatelessWidget {
  final String userId;
  final String searchQuery;

  const AppliedJobsTab({
    super.key,
    required this.userId,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final appliedJobsRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('appliedjobs');

    return StreamBuilder<QuerySnapshot>(
      stream: appliedJobsRef.orderBy('appliedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No applied jobs.',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
          );
        }

        // Filter jobs based on search query
        final filteredDocs =
            searchQuery.isEmpty
                ? docs
                : docs.where((doc) {
                  final job = doc.data() as Map<String, dynamic>;
                  final title =
                      (job['title'] ?? 'No Title').toString().toLowerCase();
                  final companyName =
                      (job['companyName'] ?? 'Unknown Company')
                          .toString()
                          .toLowerCase();
                  final employmentType =
                      (job['employmentType'] ?? '').toString().toLowerCase();
                  final location =
                      (job['location'] ?? '').toString().toLowerCase();
                  final experienceLevel =
                      (job['experienceLevel'] ?? '').toString().toLowerCase();

                  return title.contains(searchQuery) ||
                      companyName.contains(searchQuery) ||
                      employmentType.contains(searchQuery) ||
                      location.contains(searchQuery) ||
                      experienceLevel.contains(searchQuery);
                }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text(
              'No matching applied jobs found.',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final job = filteredDocs[index].data() as Map<String, dynamic>;
            return AppliedJobCard(
              job: job,
              docId: filteredDocs[index].id,
              collectionRef: appliedJobsRef,
            );
          },
        );
      },
    );
  }
}

class BookmarkJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final String docId;
  final String jobTitle;
  final String company;
  final String publisher;
  final bool hasLogo;
  final bool isTypeA;
  final CollectionReference collectionRef;

  const BookmarkJobCard({
    super.key,
    required this.job,
    required this.docId,
    required this.jobTitle,
    required this.company,
    required this.publisher,
    required this.hasLogo,
    required this.isTypeA,
    required this.collectionRef,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading:
            hasLogo
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    job['employer_logo'],
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
          jobTitle,
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
                color: Colors.deepPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              publisher,
              style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.bookmark, color: Colors.deepPurple),
              onPressed: () async {
                try {
                  await collectionRef.doc(docId).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bookmark removed',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to remove bookmark: $e',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            isTypeA
                ? ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                PlatformApplyPage(job: job, isTypeA: isTypeA),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                )
                : ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Apply(jobId: docId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
          ],
        ),
        onTap: () {
          if (isTypeA) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => PlatformApplyPage(job: job, isTypeA: isTypeA),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Apply(jobId: docId)),
            );
          }
        },
      ),
    );
  }
}

class AppliedJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final String docId;
  final CollectionReference collectionRef;

  const AppliedJobCard({
    super.key,
    required this.job,
    required this.docId,
    required this.collectionRef,
  });

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return "";

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        dateTime = DateTime.parse(timestamp);
      } catch (e) {
        return "";
      }
    } else {
      return "";
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = job['title'] ?? 'No Title';
    final companyName = job['companyName'] ?? 'Unknown Company';
    final employmentType = job['employmentType'] ?? '';
    final salaryRange = job['salaryRange'] ?? '';
    final location = job['location'] ?? '';
    final appliedAt = job['appliedAt'];
    final experienceLevel = job['experienceLevel'] ?? '';
    final companyLogo = job['companyLogo'] ?? '';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job tags row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTag(employmentType, icon: Icons.work),
                      if (salaryRange.isNotEmpty)
                        _buildTag(salaryRange, icon: Icons.currency_rupee),
                      if (location.isNotEmpty)
                        _buildTag(location, icon: Icons.location_on),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Company logo + title and name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepPurple, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child:
                            companyLogo.isNotEmpty
                                ? Image.network(
                                  companyLogo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/office.jpg',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                                : Image.asset(
                                  'assets/images/office.jpg',
                                  fit: BoxFit.cover,
                                ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            companyName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Footer with application details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeAgo(appliedAt),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.grey,
                          ),
                          onPressed: () async {
                            try {
                              await collectionRef.doc(docId).delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Application record removed',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to remove: $e',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, {required IconData icon}) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon ahead of text
          Icon(icon, size: 16, color: Colors.deepPurple),
          const SizedBox(width: 5), // Spacing between icon and text
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.deepPurple),
          ),
        ],
      ),
    );
  }
}
