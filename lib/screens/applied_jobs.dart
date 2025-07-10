import 'package:appliedjobs/screens/platformapply.dart';
import 'package:auto_size_text/auto_size_text.dart';
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
        backgroundColor: Color(0xFF3D47D1),
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
                prefixIcon: const Icon(Icons.search, color: Color(0xFF3D47D1)),
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

// BookmarksTab widget
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
            child: CircularProgressIndicator(color: Color(0xFF3D47D1)),
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
                          : 'applied plus';

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
                    ? 'Platform: ${(job['job_publisher'] ?? '').toString().toLowerCase()}'
                    : 'Platform: AppliedPlus';
            final hasLogo =
                isTypeA
                    ? (job['employer_logo'] != null)
                    : (job['companyLogoUrl'] != null);

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

  // Helper function to extract job type
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
        job['location'] ??
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
      r'(\$\d+[\d,.]\s[-–]\s*\$?\d+[\d,.]\s(k|K|thousand|million)?|(\$\d+[\d,.]\s(k|K|thousand|million)?(\s*per\s*(year|month|hour|annum)))|(salary:?\s*\$\d+[\d,.]\s[-–]\s*\$?\d+[\d,.]*))',
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

  // Method to build info pills using the extraction methods
  Widget _buildInfoPills(Map<String, dynamic> job) {
    // Use provided extraction methods
    final jobDescription = job['job_description'] ?? job['description'];
    final jobType =
        isTypeA
            ? (job['employment_type'] ??
                job['job_employment_type'] ??
                _extractJobType(jobDescription))
            : (job['employmentType'] ?? _extractJobType(jobDescription));

    final location = _extractLocation(job);

    final salary =
        isTypeA
            ? (job['job_min_salary'] != null && job['job_max_salary'] != null
                ? '${job['job_min_salary']}-${job['job_max_salary']} ${job['job_salary_currency'] ?? ''}'
                : _extractSalary(jobDescription))
            : (job['salaryRange'] != null &&
                    job['salaryRange'] != 'Not specified'
                ? job['salaryRange']
                : _extractSalary(jobDescription));

    final experience =
        isTypeA
            ? (job['experienceLevel'] ?? _extractExperience(jobDescription))
            : (job['experienceLevel'] != null &&
                    job['experienceLevel'] != 'Not Specified'
                ? job['experienceLevel']
                : _extractExperience(jobDescription));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (jobType != null && jobType.isNotEmpty)
            _buildInfoPill(jobType, Icons.work),
          if (location != null && location.isNotEmpty)
            _buildInfoPill(location, Icons.location_on),
          if (salary != null && salary.isNotEmpty)
            _buildInfoPill(salary, Icons.currency_rupee),
          if (experience != null && experience.isNotEmpty)
            _buildInfoPill(experience, Icons.star),
        ],
      ),
    );
  }

  // Method to build individual info pill
  Widget _buildInfoPill(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // Method to clean job title if needed
  String _cleanTitle(String title) {
    // You can implement the same title cleaning logic as in your API job card
    return title;
  }

  @override
  Widget build(BuildContext context) {
    // Get the appropriate logo URL based on job type
    final logoUrl = isTypeA ? job['employer_logo'] : job['companyLogoUrl'];

    return InkWell(
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
          // For local jobs, use the actual job ID from the bookmarked data
          final jobId = job['id'] ?? docId;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Apply(jobId: jobId)),
          );
        }
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoPills(job),
              const SizedBox(height: 8),
              Text(
                _cleanTitle(jobTitle),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF3D47D1), width: 2),
                    ),
                    child: ClipOval(
                      child:
                          (logoUrl ?? '').isNotEmpty
                              ? Image.network(
                                logoUrl!,
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
                  const SizedBox(width: 5),
                  Expanded(
                    child: AutoSizeText(
                      company,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      minFontSize: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      publisher,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark, color: Color(0xFF3D47D1)),
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
                  ElevatedButton(
                    onPressed: () {
                      if (isTypeA) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PlatformApplyPage(
                                  job: job,
                                  isTypeA: isTypeA,
                                ),
                          ),
                        );
                      } else {
                        // For local jobs, use the actual job ID from the bookmarked data
                        final jobId = job['id'] ?? docId;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Apply(jobId: jobId),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3D47D1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      "Apply",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            child: CircularProgressIndicator(color: Color(0xFF3D47D1)),
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

        // final docs = snapshot.data?.docs ?? [];
        final docs =
            snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['deleted'] != true;
            }).toList() ??
            [];

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
          padding: const EdgeInsets.fromLTRB(
            12,
            12,
            12,
            100,
          ), // Added extra bottom padding
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

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'applied':
        return Colors.orange;
      case 'shortlisted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get the company logo URL
  String _getCompanyLogoUrl() {
    // Check for both possible logo field names
    final companyLogo = job['companyLogo'] ?? '';
    final companyLogoUrl = job['companyLogoUrl'] ?? '';

    // Return whichever one has a value, prioritizing companyLogoUrl
    if (companyLogoUrl.isNotEmpty) {
      return companyLogoUrl;
    } else if (companyLogo.isNotEmpty) {
      return companyLogo;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final title = job['title'] ?? 'No Title';
    final companyName = job['companyName'] ?? 'Unknown Company';
    final employmentType = job['employmentType'] ?? '';
    final salaryRange = job['salaryRange'] ?? '';
    final location = job['location'] ?? '';
    final appliedAt = job['appliedAt'];
    final logoUrl = _getCompanyLogoUrl();
    // Get the status from the job data
    final status =
        (job['status'] == 'pending' ? 'Applied' : job['status']) ?? 'Applied';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top status bar
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.circle, size: 12, color: _getStatusColor(status)),
                const SizedBox(width: 6),
                Text(
                  'Status: $status',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(status),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info tags row
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

                const SizedBox(height: 8),

                // Row 1: Job Title
                AutoSizeText(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  minFontSize: 12,
                  overflow: TextOverflow.visible,
                ),

                const SizedBox(height: 8),

                // Row 2: Logo + Company
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular logo
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFF3D47D1), width: 2),
                      ),
                      child: ClipOval(
                        child:
                            logoUrl.isNotEmpty
                                ? Image.network(
                                  logoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/lo.jpg',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                                : Image.asset(
                                  'assets/images/lo.jpg',
                                  fit: BoxFit.cover,
                                ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AutoSizeText(
                        companyName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),

                // Footer Row
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
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                      ),
                      onPressed: () async {
                        try {
                          // await collectionRef.doc(docId).delete();
                          await collectionRef.doc(docId).update({
                            'deleted': true,
                          });
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
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
