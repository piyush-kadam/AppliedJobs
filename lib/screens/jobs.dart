import 'package:appliedjobs/screens/apply.dart';
import 'package:appliedjobs/screens/platformapply.dart';
import 'package:appliedjobs/services/api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Global cache to persist API jobs and page state during app session
List<dynamic>? cachedApiJobs;
int cachedCurrentPage = 1;
bool cachedHasMore = true;
bool _isRestoringFromCache = false;

// Add cache for local jobs too
List<Map<String, dynamic>>? cachedLocalJobs;

// Flag to track if initial loading has been done
bool hasInitiallyLoaded = false;

// Job types enum to differentiate between job sources
enum JobType {
  api, // Jobs from external API (Type A)
  local, // Jobs from Firestore (Type B)
}

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage>
    with AutomaticKeepAliveClientMixin {
  // For API jobs (Type A)
  final List<dynamic> _apiJobs = [];
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingApi = false;
  bool _hasMore = true;
  Set<String> bookmarkedJobIds = {};
  List<String> appliedJobIds = []; // To track applied jobs for both types

  // For local jobs from Firestore
  List<Map<String, dynamic>> _localJobs = [];
  bool _isLoadingLocal = false;

  // For search and filtering
  final TextEditingController _searchController = TextEditingController();
  String? _selectedPlatform;

  // Combined jobs list for display
  List<Map<String, dynamic>> _combinedJobs = [];
  List<Map<String, dynamic>> _filteredJobs = [];
  bool _isLoadingCombined = false;

  // ✅ New variable to show immediate loading state when tab is switched to
  bool _showLoadingScreen = true;

  // Flag to track if the component is mounted
  bool _isMounted = false;

  // List of platforms for the filter
  final List<String> _platforms = [
    'All',
    'AppliedPlus', // New option for Firebase jobs
    'LinkedIn',
    'Cognizant',
    'Glassdoor',
    'P & G',
    'Trakstar',
    'Abbott Jobs',
    'OLX',
  ];

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    _isMounted = true;

    // Always show loading screen immediately on init
    setState(() {
      _showLoadingScreen = true;
    });

    // Only load data if not already loaded
    _initializeData();

    _scrollController.addListener(_onScroll);
  }

  Future<void> _initializeData() async {
    if (!_isMounted) return;

    // Check if we already have cached data
    if (hasInitiallyLoaded &&
        cachedApiJobs != null &&
        cachedLocalJobs != null) {
      _isRestoringFromCache = true;
      setState(() {
        _apiJobs.clear();
        _apiJobs.addAll(cachedApiJobs!);
        _currentPage = cachedCurrentPage;
        _hasMore = cachedHasMore;
        _localJobs = List.from(cachedLocalJobs!);
        _isLoadingCombined = true; // Show loading while restoring
      });

      await _loadBookmarkedJobs();
      await _fetchAppliedJobs();
      _combineAndShuffleJobs();

      _isRestoringFromCache = false;

      // ✅ Hide loading indicator once data is ready
      if (_isMounted) {
        setState(() {
          _isLoadingCombined = false;
          _showLoadingScreen = false;
        });
      }
    } else {
      // First time load - fetch everything
      setState(() {
        _isLoadingCombined = true;
      });

      await _loadBookmarkedJobs();
      await _fetchAppliedJobs();
      await _loadJobs();

      // Mark as initially loaded
      hasInitiallyLoaded = true;

      // ✅ Hide loading indicator once data is ready
      if (_isMounted) {
        setState(() {
          _showLoadingScreen = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    if (!_isMounted) return;

    setState(() {
      _isLoadingCombined = true;
    });

    // Load API jobs
    await _fetchNextPage();

    // Load local jobs
    await _fetchLocalJobs();

    // Combine and shuffle jobs for interleaved display
    _combineAndShuffleJobs();

    if (_isMounted) {
      setState(() {
        _isLoadingCombined = false;
      });
    }
  }

  Future<void> _fetchLocalJobs() async {
    if (!_isMounted) return;

    setState(() => _isLoadingLocal = true);
    try {
      // Check if we have cached local jobs
      if (cachedLocalJobs != null && cachedLocalJobs!.isNotEmpty) {
        _localJobs = List.from(cachedLocalJobs!);
      } else {
        final snapshot =
            await FirebaseFirestore.instance.collection('jobs').get();
        final jobs =
            snapshot.docs.where((doc) => !appliedJobIds.contains(doc.id)).map((
              doc,
            ) {
              final data = doc.data();
              return {...data, 'id': doc.id, 'type': JobType.local};
            }).toList();

        _localJobs = jobs;

        // Cache the local jobs
        cachedLocalJobs = List.from(_localJobs);
      }

      if (_isMounted) {
        setState(() {
          _isLoadingLocal = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching local jobs: $e");
      if (_isMounted) {
        setState(() => _isLoadingLocal = false);
      }
    }
  }

  void _combineAndShuffleJobs() {
    // Convert API jobs to the same format as local jobs
    final formattedApiJobs =
        _apiJobs
            .map(
              (job) => {...Map<String, dynamic>.from(job), 'type': JobType.api},
            )
            .toList();

    // Create interleaved list with 2 API jobs followed by 1-2 local jobs
    _combinedJobs = [];
    int apiIndex = 0;
    int localIndex = 0;

    while (apiIndex < formattedApiJobs.length ||
        localIndex < _localJobs.length) {
      // Add up to 2 API jobs
      for (int i = 0; i < 2 && apiIndex < formattedApiJobs.length; i++) {
        _combinedJobs.add(formattedApiJobs[apiIndex]);
        apiIndex++;
      }

      // Add 1-2 local jobs (or whatever is available)
      int localJobsToAdd = _localJobs.length - localIndex >= 2 ? 2 : 1;
      for (
        int i = 0;
        i < localJobsToAdd && localIndex < _localJobs.length;
        i++
      ) {
        _combinedJobs.add(_localJobs[localIndex]);
        localIndex++;
      }
    }

    // Apply filters to the combined jobs
    _applyFilters();
  }

  void _applyFilters() {
    // Start with all jobs
    _filteredJobs = List.from(_combinedJobs);

    final searchQuery = _searchController.text.toLowerCase();

    // Apply platform filter
    if (_selectedPlatform != null && _selectedPlatform != 'All') {
      if (_selectedPlatform == 'AppliedPlus') {
        // Filter for local jobs only
        _filteredJobs =
            _filteredJobs.where((job) => job['type'] == JobType.local).toList();
      } else {
        // Filter for API jobs with matching platform
        _filteredJobs =
            _filteredJobs.where((job) {
              if (job['type'] == JobType.api) {
                final jobPublisher =
                    (job['job_publisher'] ?? '').toString().toLowerCase();
                return jobPublisher.contains(_selectedPlatform!.toLowerCase());
              }
              return false;
            }).toList();
      }
    }

    // Apply search filter if there's a search query
    if (searchQuery.isNotEmpty) {
      _filteredJobs =
          _filteredJobs.where((job) {
            if (job['type'] == JobType.api) {
              final title = (job['job_title'] ?? '').toString().toLowerCase();
              final company =
                  (job['employer_name'] ?? '').toString().toLowerCase();
              return title.contains(searchQuery) ||
                  company.contains(searchQuery);
            } else {
              final title = (job['title'] ?? '').toString().toLowerCase();
              final company =
                  (job['companyName'] ?? '').toString().toLowerCase();
              final location = (job['location'] ?? '').toString().toLowerCase();
              return title.contains(searchQuery) ||
                  company.contains(searchQuery) ||
                  location.contains(searchQuery);
            }
          }).toList();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingApi &&
        _hasMore) {
      _fetchNextPage().then((_) {
        _combineAndShuffleJobs();
        if (_isMounted) setState(() {});
      });
    }
  }

  Future<void> _fetchNextPage() async {
    if (_isLoadingApi) return;

    setState(() => _isLoadingApi = true);
    try {
      final newJobs = await ApiService().fetchJobsPage(page: _currentPage);
      if (newJobs.isEmpty) {
        _hasMore = false;
      } else {
        if (_isMounted) {
          setState(() {
            _apiJobs.addAll(newJobs);
            _currentPage++;

            // ✅ Update global cache
            cachedApiJobs = List.from(_apiJobs);
            cachedCurrentPage = _currentPage;
            cachedHasMore = _hasMore;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching jobs: $e");
    } finally {
      if (_isMounted) {
        setState(() => _isLoadingApi = false);
      }
    }
  }

  // Function to clear cache - call this when user wants to refresh
  void _clearCache() {
    cachedApiJobs = null;
    cachedLocalJobs = null;
    cachedCurrentPage = 1;
    cachedHasMore = true;
    hasInitiallyLoaded = false;

    // ✅ Show loading indicator immediately when refreshing
    setState(() {
      _showLoadingScreen = true;
    });

    _initializeData();
  }

  // ✅ New loading indicator widget with branded styling
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.deepPurple,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            "Discovering jobs for you...",
            style: GoogleFonts.poppins(
              color: Colors.deepPurple,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedJobsList() {
    // ✅ Show loading indicator when either explicitly showing loading screen
    //    or during combined loading operation
    if (_showLoadingScreen || _isLoadingCombined) {
      return _buildLoadingIndicator();
    }

    // Only show "no jobs" message AFTER loading is finished
    if (_filteredJobs.isEmpty &&
        !_isRestoringFromCache &&
        !_isLoadingCombined) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 200),
          Center(
            child: Text(
              'No matching jobs found',
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _filteredJobs.length + (_isLoadingApi && _hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredJobs.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
          );
        }

        final job = _filteredJobs[index];
        final isApiJob = job['type'] == JobType.api;

        if (isApiJob) {
          return _buildApiJobCard(job);
        } else {
          return _buildLocalJobCard(job);
        }
      },
    );
  }

  Future<void> _loadBookmarkedJobs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .collection('bookmarks')
              .get();

      if (mounted) {
        setState(() {
          bookmarkedJobIds =
              snapshot.docs.map((doc) => doc.id.toString()).toSet();
        });
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error loading bookmarks: $e");
    }
  }

  Future<void> _fetchAppliedJobs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final appliedJobsSnapshot =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .collection('appliedjobs')
              .get();

      if (mounted) {
        setState(() {
          appliedJobIds =
              appliedJobsSnapshot.docs.map((doc) => doc.id).toList();
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching applied jobs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFE0E0E0),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Big title text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Find Your Dream ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: 'Job!!',
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ],
                ),
              ),
            ),

            // Search and filter section
            Container(
              color: const Color(0xFFE0E0E0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search jobs or companies',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.deepPurple,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _applyFilters();
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Platform filter
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children:
                          _platforms.map((platform) {
                            final isSelected =
                                _selectedPlatform == platform ||
                                (platform == 'All' &&
                                    _selectedPlatform == null);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    platform,
                                    style: GoogleFonts.poppins(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.deepPurple,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: Colors.deepPurple,
                                backgroundColor: Colors.grey[100],
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedPlatform =
                                        selected
                                            ? (platform == 'All'
                                                ? null
                                                : platform)
                                            : null;
                                    _applyFilters();
                                  });
                                },
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs: Recent Jobs and Best For You
            TabBar(
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.black54,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.poppins(),
              indicatorColor: Colors.deepPurple,
              tabs: const [Tab(text: "Recent Jobs"), Tab(text: "Best For You")],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  // 🔹 Recent Jobs Tab
                  RefreshIndicator(
                    onRefresh: () async {
                      _clearCache();
                    },
                    child: _buildCombinedJobsList(),
                  ),

                  // 🔹 Best For You Tab (filtered jobs)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getMatchedJobs(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 200),
                            Center(
                              child: Text(
                                'No matching jobs found',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        final matchedJobs = snapshot.data!;
                        return RefreshIndicator(
                          onRefresh: () async {
                            _clearCache();
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: matchedJobs.length,
                            itemBuilder: (context, index) {
                              final job = matchedJobs[index];
                              final isApiJob = job['type'] == JobType.api;
                              return isApiJob
                                  ? _buildApiJobCard(job)
                                  : _buildLocalJobCard(job);
                            },
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bookmarkApiJob(Map<String, dynamic> job) async {
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
        setState(() => bookmarkedJobIds.remove(docId));
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
        setState(() => bookmarkedJobIds.add(docId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Job bookmarked successfully',
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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error bookmarking job: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update bookmark")),
      );
    }
  }

  void _bookmarkLocalJob(String jobId, Map<String, dynamic> job) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to bookmark jobs")),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(jobId);

    final isBookmarked = bookmarkedJobIds.contains(jobId);

    try {
      if (isBookmarked) {
        await docRef.delete();
        setState(() => bookmarkedJobIds.remove(jobId));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Removed from bookmarks")));
      } else {
        await docRef.set({
          'jobId': jobId,
          'title': job['title'],
          'companyName': job['companyName'],
          'salaryRange': job['salaryRange'] ?? 'Salary not specified',
          'location': job['location'],
          'employmentType': job['employmentType'],
          'experienceLevel': job['experienceLevel'] ?? 'Not specified',
          'time': job['datePosted'] ?? FieldValue.serverTimestamp(),
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() => bookmarkedJobIds.add(jobId));
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

  Widget _buildInfoPills(Map<String, dynamic> job) {
    final List<Widget> pills = [];

    if (job['type'] == JobType.api) {
      // Extract key information for API jobs
      final jobType = _extractJobType(job['job_description']);
      final location = _extractLocation(job);
      final salary = _extractSalary(job['job_description']);
      final experience = _extractExperience(job['job_description']);

      // Add job type pill if available
      if (jobType != null) {
        pills.add(_buildInfoPill(jobType, Icons.work));
      }

      // Add location pill if available
      if (location != null) {
        pills.add(_buildInfoPill(location, Icons.location_on));
      }

      // Add salary pill if available
      if (salary != null) {
        pills.add(_buildInfoPill(salary, Icons.attach_money));
      }

      // Add experience pill if available
      if (experience != null) {
        pills.add(_buildInfoPill(experience, Icons.star));
      }
    } else {
      // For local jobs
      pills.add(
        _buildInfoPill(job['employmentType'] ?? 'Full-time', Icons.work),
      );
      pills.add(_buildInfoPill(job['location'] ?? 'Remote', Icons.location_on));
      pills.add(
        _buildInfoPill(
          job['salaryRange'] ?? 'Salary not specified',
          Icons.attach_money,
        ),
      );
      if (job['experienceLevel'] != null) {
        pills.add(_buildInfoPill(job['experienceLevel'], Icons.star));
      }
    }

    if (pills.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: pills),
    );
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

  // Widget to display info pills for API jobs
  Future<List<Map<String, dynamic>>> _getMatchedJobs() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final userDoc =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.uid)
            .get();

    final about = userDoc.data()?['about']?.toString().toLowerCase() ?? '';
    final skills = List<String>.from(userDoc.data()?['skills'] ?? []);

    final keywords = {
      ...skills.map((s) => s.toLowerCase()),
      ...about.toLowerCase().split(' '),
    };

    return _filteredJobs.where((job) {
      final jobTitle =
          (job['title'] ?? job['job_title'])?.toString().toLowerCase() ?? '';
      return keywords.any((keyword) => jobTitle.contains(keyword));
    }).toList();
  }

  String _cleanTitle(String title) {
    // Removes non-alphanumeric characters except basic punctuation and spaces
    return title.replaceAll(RegExp(r'[^\w\s.,!&()\-]'), '').trim();
  }

  Widget _buildApiJobCard(Map<String, dynamic> job) {
    final platform = job['job_publisher'] ?? 'Unknown Platform';
    final companyLogo = job['employer_logo'];
    final company = job['employer_name'] ?? 'Unknown Company';
    final jobId = job['job_id'] ?? job['job_title'];

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlatformApplyPage(job: job, isTypeA: true),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1st Row - Info Pills
              _buildInfoPills(job),
              const SizedBox(height: 12),

              // 2nd Row - Logo + Title + Company
              Row(
                children: [
                  // Company Logo with Border
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepPurple, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          companyLogo != null
                              ? Image.network(
                                companyLogo,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (ctx, obj, stack) => Image.asset(
                                      'assets/images/office.jpg',
                                      fit: BoxFit.contain,
                                    ),
                              )
                              : Image.asset(
                                'assets/images/office.jpg',
                                fit: BoxFit.contain,
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and Company
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _cleanTitle(job['job_title'] ?? 'No Title'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 4),
                        Text(
                          company,
                          style: GoogleFonts.poppins(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3rd Row - Platform Info + Bookmark + Apply
              Row(
                children: [
                  // Platform Info (Bold "Platform:")
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: 'Platform: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: platform,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bookmark Icon
                  IconButton(
                    icon: Icon(
                      bookmarkedJobIds.contains(jobId)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: Colors.deepPurple,
                    ),
                    onPressed: () => _bookmarkApiJob(job),
                  ),

                  // Apply Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  PlatformApplyPage(job: job, isTypeA: true),
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
                        vertical: 12,
                      ),
                    ),
                    child: const Text("Apply"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalJobCard(Map<String, dynamic> job) {
    final jobId = job['id'];
    final isBookmarked = bookmarkedJobIds.contains(jobId);

    return FutureBuilder<int>(
      future: _getApplicantCount(jobId),
      builder: (context, snapshot) {
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Apply(jobId: jobId)),
            );
          },
          child: Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First Row: Info Pills
                  _buildInfoPills(job),
                  const SizedBox(height: 12),

                  // Second Row: Title and Company
                  Text(
                    job['title'] ?? 'No Title',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    job['companyName'] ?? 'Unknown Company',
                    style: GoogleFonts.poppins(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Third Row: Platform, TimeAgo, Applicants, Bookmark, Apply
                  Row(
                    children: [
                      Text(
                        'Platform: AppliedPlus',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),

                      // Time Ago
                      SizedBox(width: 24),
                      // Bookmark Icon
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: Colors.deepPurple,
                        ),
                        onPressed: () => _bookmarkLocalJob(jobId, job),
                      ),

                      // Apply Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Apply(jobId: jobId),
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
                            vertical: 12,
                          ),
                        ),
                        child: const Text("Apply"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<int> _getApplicantCount(String jobId) async {
    // First try to get from SharedPreferences for faster loading
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedCount = prefs.getString('applicantCount_$jobId');
      if (cachedCount != null) {
        return int.parse(cachedCount);
      }
    } catch (e) {
      if (kDebugMode) print('Error reading cached applicant count: $e');
    }

    // If no cache or error reading cache, fetch from Firestore
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(jobId)
              .collection('applications')
              .get();
      final count = snapshot.docs.length;

      // Cache the result
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('applicantCount_$jobId', count.toString());
      } catch (e) {
        if (kDebugMode) print('Error caching applicant count: $e');
      }

      return count;
    } catch (e) {
      if (kDebugMode) print('Error getting applicant count: $e');
      return 0;
    }
  }

  Widget _buildInfoPill(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.deepPurple),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.deepPurple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
