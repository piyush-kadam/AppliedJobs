import 'dart:convert';
import 'package:appliedjobs/models/filter_model.dart';
import 'package:appliedjobs/screens/apply.dart';
import 'package:appliedjobs/screens/job_filter_modal.dart';
import 'package:appliedjobs/screens/platformapply.dart';
import 'package:appliedjobs/services/api.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
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
  final void Function({
    required JobFilters currentFilters,
    required void Function(JobFilters) onApply,
    required void Function() onClear,
    required List<String> uniqueRoles,
    required List<String> uniqueLocations,
    required List<String> uniqueCompanies,
  })?
  showFilterBox;
  final JobFilters currentFilters;
  const JobsPage({Key? key, this.showFilterBox, required this.currentFilters})
    : super(key: key);

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage>
    with AutomaticKeepAliveClientMixin {
  JobFilters _currentFilters = JobFilters();

  List<String> _cachedStaticCompanies = [];
  List<String> _cachedGeoNamesCities = [];
  bool _isLoadingFilterData = true;

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
  static const List<String> staticJobTypes = [
    "Full-time",
    "Part-time",
    "Internship",
    "Contract",
    "Temporary",
    "Freelance",
    "Remote",
  ];

  // Changed from 'late' to nullable with default initialization
  Future<List<Map<String, dynamic>>>? _matchedJobsFuture;

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
    'OLX',
  ];

  // ✅ New variables to limit the number of fetches for the "Best For You" tab
  int _bestForYouFetchCount = 0;
  final int _maxBestForYouFetches = 2;
  List<Map<String, dynamic>>? _cachedMatchedJobs;

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
    // Fetch filter data once
    _fetchFilterData();
    // Initialize with an empty list to prevent LateInitializationError
    _matchedJobsFuture = Future.value([]);

    // Only load data if not already loaded
    _initializeData();

    _scrollController.addListener(_onScroll);
    // Don't fetch matched jobs immediately, we'll do it after jobs are loaded
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFE0E0E0),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Find Your Dream ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: 'Job!!',
                      style: TextStyle(color: Color(0xFF3D47D1)),
                    ),
                  ],
                ),
              ),
            ),

            // Search bar and filter button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40, // Reduced height
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search jobs or companies',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF3D47D1),
                            size: 20, // Slightly smaller icon
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, // Reduced padding
                            horizontal: 12,
                          ),
                        ),
                        style: GoogleFonts.poppins(fontSize: 13),
                        onChanged: (value) {
                          setState(() {
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      if (_isLoadingFilterData) {
                        // Optionally show a loading indicator or snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Loading filter options, please wait...",
                            ),
                          ),
                        );
                        return;
                      }

                      final companiesFromJobs = _getUniqueCompanies().toSet();
                      final allCompanies =
                          {
                              ...companiesFromJobs,
                              ..._cachedStaticCompanies,
                            }.toList()
                            ..sort();

                      final locationsFromJobs = _getUniqueLocations().toSet();
                      final allLocations =
                          {
                              ...locationsFromJobs,
                              ..._cachedGeoNamesCities,
                            }.toList()
                            ..sort();

                      showDialog(
                        context: context,
                        builder:
                            (_) => JobFilterBox(
                              currentFilters: _currentFilters,
                              onApply: (filters) {
                                setState(() {
                                  _currentFilters = filters;
                                  _applyFilters();
                                });
                              },
                              onClear: () {
                                setState(() {
                                  _currentFilters = JobFilters();
                                  _applyFilters();
                                });
                              },
                              jobRoles: _getUniqueRoles(),
                              locations: allLocations,

                              companies: allCompanies,
                              jobTypes: staticJobTypes,
                              onClose: () => Navigator.of(context).pop(),
                            ),
                      );
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Color(0xFF3D47D1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.filter_alt_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // The rest scrolls (Platform chips, TabBar, and content)
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder:
                    (context, innerBoxIsScrolled) => [
                      SliverAppBar(
                        backgroundColor: const Color(0xFFE0E0E0),
                        floating: true,
                        snap: true,
                        pinned: false,
                        automaticallyImplyLeading: false,
                        expandedHeight:
                            100, // Height for platform chips + tab bar + spacing
                        toolbarHeight: 0,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Column(
                            children: [
                              // Platform chips
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
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
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: ChoiceChip(
                                              label: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  platform,
                                                  style: GoogleFonts.poppins(
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : Color(0xFF3D47D1),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              selected: isSelected,
                                              selectedColor: Color(0xFF3D47D1),
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
                              ),
                              // Add spacing between platform chips and tab bar
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        bottom: PreferredSize(
                          preferredSize: Size.fromHeight(kToolbarHeight),
                          child: Container(
                            color: const Color(0xFFE0E0E0),
                            child: TabBar(
                              padding: EdgeInsets.only(top: 0),
                              labelColor: const Color(0xFF3D47D1),
                              unselectedLabelColor: Colors.black54,
                              labelStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                              unselectedLabelStyle: GoogleFonts.poppins(),
                              indicatorColor: const Color(0xFF3D47D1),
                              tabs: const [
                                Tab(text: "Recent Jobs"),
                                Tab(text: "Best For You"),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                body: TabBarView(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        _clearCache();
                      },
                      child: _buildCombinedJobsList(),
                    ),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _matchedJobsFuture ?? Future.value([]),
                      builder: (context, snapshot) {
                        if (_filteredJobs.isEmpty || _isLoadingCombined) {
                          return _buildLoadingIndicator();
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
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
                            onRefresh: _refreshMatchedJobs,
                            child: ListView.builder(
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
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods to extract unique filter values

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

      // Initialize the matched jobs future after data is loaded
      // Wrap in setState to ensure UI updates
      setState(() {
        _matchedJobsFuture = _getMatchedJobs();
      });

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

      // Initialize the matched jobs future after data is loaded
      // Wrap in setState to ensure UI updates
      setState(() {
        _matchedJobsFuture = _getMatchedJobs();
      });

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
    _cachedMatchedJobs = null;
    _bestForYouFetchCount = 0;

    // ✅ Show loading indicator immediately when refreshing
    setState(() {
      _showLoadingScreen = true;
    });

    _initializeData();
  }

  // ✅ New loading indicator widget with branded styling

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

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // 🎯 THIS HANDLES YOUR PAGINATION - Same logic as your _onScroll method!
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200 &&
            !_isLoadingApi &&
            _hasMore) {
          print("🔄 Fetching next page..."); // Debug log

          _fetchNextPage().then((_) {
            _combineAndShuffleJobs();
            if (_isMounted) setState(() {});
          });
        }
        return false; // Allow the scroll event to continue
      },
      child: ListView.builder(
        // ✅ No ScrollController - this allows NestedScrollView to work properly
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredJobs.length + (_isLoadingApi && _hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredJobs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF3D47D1)),
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
      ),
    );
  }

  void _applyFilters() {
    _filteredJobs = List.from(_combinedJobs);

    final searchQuery = _searchController.text.toLowerCase();

    // Job Role filter
    if (_currentFilters.jobRole != null &&
        _currentFilters.jobRole!.isNotEmpty &&
        _currentFilters.jobRole != 'All Roles') {
      _filteredJobs =
          _filteredJobs.where((job) {
            final title =
                (job['title'] ?? job['job_title'] ?? '')
                    .toString()
                    .toLowerCase();
            return title.contains(_currentFilters.jobRole!.toLowerCase());
          }).toList();
    }

    // Location filter
    if (_currentFilters.location != null &&
        _currentFilters.location!.isNotEmpty &&
        _currentFilters.location != 'All Cities') {
      _filteredJobs =
          _filteredJobs.where((job) {
            // Try all possible location fields and also try to extract from description
            final locationFields = [
              (job['location'] ?? '').toString().toLowerCase(),
              (job['job_city'] ?? '').toString().toLowerCase(),
              (job['job_country'] ?? '').toString().toLowerCase(),
              job['job_description'] != null
                  ? _extractLocationFromDesc(
                        job['job_description'].toString().toLowerCase(),
                      ) ??
                      ''
                  : '',
            ];
            return locationFields.any(
              (loc) => loc.contains(_currentFilters.location!.toLowerCase()),
            );
          }).toList();
    }

    // Application Status filter
    if (_currentFilters.applicationStatus != null &&
        _currentFilters.applicationStatus != 'All Jobs') {
      if (_currentFilters.applicationStatus == 'Applied') {
        _filteredJobs =
            _filteredJobs
                .where(
                  (job) => appliedJobIds.contains(job['id'] ?? job['job_id']),
                )
                .toList();
      } else if (_currentFilters.applicationStatus == 'Not Applied') {
        _filteredJobs =
            _filteredJobs
                .where(
                  (job) => !appliedJobIds.contains(job['id'] ?? job['job_id']),
                )
                .toList();
      }
    }

    // Companies filter
    if (_currentFilters.companies.isNotEmpty) {
      _filteredJobs =
          _filteredJobs.where((job) {
            final company =
                (job['companyName'] ?? job['employer_name'] ?? '').toString();
            return _currentFilters.companies.contains(company);
          }).toList();
    }

    // Job Type filter
    if (_currentFilters.jobTypes.isNotEmpty) {
      _filteredJobs =
          _filteredJobs.where((job) {
            // Try all possible job type fields, including extracting from description
            final jobTypeFields = [
              (job['employmentType'] ?? '').toString().toLowerCase(),
              (job['job_type'] ?? '').toString().toLowerCase(),
              job['job_description'] != null
                  ? (_extractJobType(job['job_description'].toString()) ?? '')
                      .toLowerCase()
                  : '',
            ];
            return _currentFilters.jobTypes.any(
              (t) =>
                  jobTypeFields.any((field) => field.contains(t.toLowerCase())),
            );
          }).toList();
    }

    // Platform filter
    if (_selectedPlatform != null && _selectedPlatform != 'All') {
      if (_selectedPlatform == 'AppliedPlus') {
        _filteredJobs =
            _filteredJobs.where((job) => job['type'] == JobType.local).toList();
      } else {
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

    // Search query
    if (searchQuery.isNotEmpty) {
      _filteredJobs =
          _filteredJobs.where((job) {
            if (job['type'] == JobType.api) {
              final title = (job['job_title'] ?? '').toString().toLowerCase();
              final company =
                  (job['employer_name'] ?? '').toString().toLowerCase();
              final location =
                  (job['job_city'] ?? job['job_country'] ?? '')
                      .toString()
                      .toLowerCase();
              return title.contains(searchQuery) ||
                  company.contains(searchQuery) ||
                  location.contains(searchQuery);
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

  Future<List<Map<String, dynamic>>> _getMatchedJobs() async {
    // If we've already fetched the maximum number of times, return the cached results
    if (_bestForYouFetchCount >= _maxBestForYouFetches &&
        _cachedMatchedJobs != null) {
      if (kDebugMode) {
        print(
          "✅ Using cached Best For You results (fetch count: $_bestForYouFetchCount)",
        );
      }
      return _cachedMatchedJobs!;
    }

    // Make sure we have filtered jobs before proceeding
    if (_filteredJobs.isEmpty) {
      if (kDebugMode) {
        print("⚠️ No filtered jobs available yet, returning empty list");
      }
      return [];
    }

    // Increment the fetch count
    _bestForYouFetchCount++;
    if (kDebugMode) {
      print(
        "⏳ Fetching Best For You jobs (fetch count: $_bestForYouFetchCount)",
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    try {
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

      // Filter out empty strings or very short keywords
      final filteredKeywords = keywords.where((k) => k.length > 2).toSet();

      final matchedJobs =
          _filteredJobs.where((job) {
            final jobTitle =
                (job['title'] ?? job['job_title'])?.toString().toLowerCase() ??
                '';
            return filteredKeywords.any(
              (keyword) => jobTitle.contains(keyword),
            );
          }).toList();

      final result = matchedJobs.take(10).toList(); // Limit to 10 results

      // Cache the results
      _cachedMatchedJobs = result;

      if (kDebugMode) print("✅ Found ${result.length} matched jobs");
      return result;
    } catch (e) {
      if (kDebugMode) print("❌ Error in _getMatchedJobs: $e");
      return [];
    }
  }

  Future<void> _refreshMatchedJobs() async {
    // Reset the fetch counter when manually refreshing
    _bestForYouFetchCount = 0;
    _cachedMatchedJobs = null;
    _clearCache();
    setState(() {
      _matchedJobsFuture = _getMatchedJobs(); // Re-fetch on pull-to-refresh
    });
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

  @override
  void dispose() {
    _isMounted = false;
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF3D47D1),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            "Discovering jobs for you...",
            style: GoogleFonts.poppins(
              color: Color(0xFF3D47D1),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getUniqueRoles() {
    final roles = <String>{};
    for (final job in _combinedJobs) {
      final title = (job['title'] ?? job['job_title'] ?? '').toString();
      if (title.isNotEmpty) roles.add(title);
    }
    return roles.toList();
  }

  List<String> _getUniqueLocations() {
    final locations = <String>{};
    for (final job in _combinedJobs) {
      final location =
          (job['location'] ?? job['job_city'] ?? job['job_country'] ?? '')
              .toString();
      if (location.isNotEmpty) locations.add(location);
    }
    return locations.toList();
  }

  List<String> _getUniqueCompanies() {
    final companies = <String>{};
    for (final job in _combinedJobs) {
      final company =
          (job['companyName'] ?? job['employer_name'] ?? '').toString();
      if (company.isNotEmpty) companies.add(company);
    }
    return companies.toList();
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
          'job_city': job['job_city'], // ✅ add if exists
          'job_country': job['job_country'], // ✅ add if exists
          'location': job['location'], // ✅ fallback, if provided
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
          'id': job['id'], // Unique Job ID
          'title': job['title'],
          'companyName': job['companyName'],
          'companyLogoUrl': job['companyLogoUrl'],
          'description': job['description'],
          'location': job['location'],
          'salaryRange': job['salaryRange'] ?? 'Not specified',
          'employmentType': job['employmentType'],
          'experienceLevel': job['experienceLevel'] ?? 'Not Specified',
          'genderPreference': job['genderPreference'] ?? 'Any',
          'industry': job['industry'] ?? 'Not Specified',
          'skills': job['skills'] ?? [],
          'postedBy': job['postedBy'],
          'isClosed': job['isClosed'] ?? false,
          'isDraft': job['isDraft'] ?? false,
          'datePosted': job['datePosted'] ?? FieldValue.serverTimestamp(),
          'timestamp': FieldValue.serverTimestamp(), // Time of bookmarking
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
        pills.add(_buildInfoPill(jobType));
      }

      // Add location pill if available
      if (location != null) {
        pills.add(_buildInfoPill(location));
      }

      // Add salary pill if available
      if (salary != null) {
        pills.add(_buildInfoPill(salary));
      }

      // Add experience pill if available
      if (experience != null) {
        pills.add(_buildInfoPill(experience));
      }
    } else {
      // For local jobs
      pills.add(_buildInfoPill(job['employmentType'] ?? 'Full-time'));
      pills.add(_buildInfoPill(job['location'] ?? 'Remote'));
      pills.add(_buildInfoPill(job['salaryRange'] ?? 'Salary not specified'));

      if (job['experienceLevel'] != null) {
        pills.add(_buildInfoPill(job['experienceLevel']));
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

  Widget _buildInfoPill(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
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
      r'location:\s*([^,\n]+)',
      caseSensitive: false,
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

  Future<void> _fetchFilterData() async {
    try {
      final companies = await fetchStaticCompanies();
      final cities = await fetchGeoNamesCities(country: "IN", limit: 100);
      if (_isMounted) {
        setState(() {
          _cachedStaticCompanies = companies;
          _cachedGeoNamesCities = cities;
          _isLoadingFilterData = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching filter data: $e');
      if (_isMounted) {
        setState(() {
          _isLoadingFilterData = false;
        });
      }
    }
  }

  Future<List<String>> fetchStaticCompanies() async {
    final response = await http.get(
      Uri.parse(
        'https://gist.githubusercontent.com/Anshhb/c1514a5849014d0934659176c98ed8df/raw/f12e1ba4ad14c3699265f95ba3700004d7fda23b/dropdown_options.json',
      ),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['companies'] ?? []);
    } else {
      throw Exception('Failed to load companies from gist');
    }
  }

  Future<List<String>> fetchGeoNamesCities({
    String country = "IN",
    int limit = 100,
  }) async {
    const geoNamesUser = "ab3003"; // Replace with your GeoNames username
    final response = await http.get(
      Uri.parse(
        'http://api.geonames.org/searchJSON?formatted=true&country=$country&featureClass=P&maxRows=$limit&username=$geoNamesUser',
      ),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List cities = data['geonames'];
      return cities.map<String>((city) => city['name'] as String).toList();
    } else {
      throw Exception('Failed to load cities from GeoNames');
    }
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1st Row - Info Pills
              _buildInfoPills(job),
              const SizedBox(height: 8),

              // 2nd Row - Title
              AutoSizeText(
                _cleanTitle(job['job_title'] ?? 'No Title'),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: 8),

              // 3rd Row - Circular Logo and Company Name
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF3D47D1), width: 1.2),
                    ),
                    child: ClipOval(
                      child:
                          companyLogo != null
                              ? Image.network(
                                companyLogo,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (ctx, obj, stack) => Image.asset(
                                      'assets/images/lo.jpg',
                                      fit: BoxFit.cover,
                                    ),
                              )
                              : Image.asset(
                                'assets/images/lo.jpg',
                                fit: BoxFit.cover,
                              ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AutoSizeText(
                      company,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 4th Row - Platform + Bookmark + Apply
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Platform Info
                      Expanded(
                        child: Text(
                          'Platform: $platform',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // Fixed width for action buttons area for consistent layout
                      Container(
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Bookmark Icon - fixed position
                            IconButton(
                              icon: Icon(
                                bookmarkedJobIds.contains(jobId)
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: Color(0xFF3D47D1),
                              ),
                              constraints: BoxConstraints(minWidth: 40),
                              padding: EdgeInsets.zero,
                              iconSize: 24,
                              onPressed: () => _bookmarkApiJob(job),
                            ),

                            // Apply Button - fixed position
                            SizedBox(
                              width: 70,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => PlatformApplyPage(
                                            job: job,
                                            isTypeA: true,
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF3D47D1),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const FittedBox(child: Text("Apply")),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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
              padding: const EdgeInsets.all(12), // Match padding with API card
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First Row: Info Pills
                  _buildInfoPills(job),
                  const SizedBox(height: 8),

                  // Second Row: Title
                  AutoSizeText(
                    // Use same AutoSizeText as API card
                    job['title'] ?? 'No Title',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 8), // Consistent spacing
                  // Third Row: Logo and Company Name
                  Row(
                    children: [
                      // Company Logo with circular border
                      if (job['companyLogoUrl'] != null &&
                          job['companyLogoUrl'].toString().isNotEmpty)
                        Container(
                          height: 28, // Match API card size
                          width: 28, // Match API card size
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFF3D47D1),
                              width: 1.2, // Match API card border width
                            ),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              job['companyLogoUrl'],
                              fit: BoxFit.contain, // Match API card fit
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 24),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 28, // Match API card size
                          width: 28, // Match API card size
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFF3D47D1),
                              width: 1.2, // Match API card border width
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey,
                            child: Icon(
                              Icons.business,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),

                      // Company Name
                      Expanded(
                        child: AutoSizeText(
                          job['companyName'] ?? 'Unknown Company',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8), // Consistent spacing
                  // Last Row: Platform, Bookmark, Apply - using the same structure as API card
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Platform Info
                          Expanded(
                            child: Text(
                              'Platform: AppliedPlus',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          // Fixed width for action buttons area for consistent layout
                          Container(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Bookmark Icon - fixed position
                                IconButton(
                                  icon: Icon(
                                    isBookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: Color(0xFF3D47D1),
                                  ),
                                  constraints: BoxConstraints(minWidth: 40),
                                  padding: EdgeInsets.zero,
                                  iconSize: 24,
                                  onPressed:
                                      () => _bookmarkLocalJob(jobId, job),
                                ),

                                // Apply Button - fixed position
                                SizedBox(
                                  width: 70,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => Apply(jobId: jobId),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF3D47D1),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const FittedBox(
                                      child: Text("Apply"),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
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
}
