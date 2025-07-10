import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appliedjobs/models/filter_model.dart';

class JobFilterBox extends StatefulWidget {
  final JobFilters currentFilters;
  final void Function(JobFilters) onApply;
  final VoidCallback onClear;
  final List<String> jobRoles;
  final List<String> locations;
  final List<String> companies;
  final List<String> jobTypes;
  final VoidCallback? onClose;

  const JobFilterBox({
    Key? key,
    required this.currentFilters,
    required this.onApply,
    required this.onClear,
    required this.jobRoles,
    required this.locations,
    required this.companies,
    required this.jobTypes,
    this.onClose,
  }) : super(key: key);

  @override
  State<JobFilterBox> createState() => _JobFilterBoxState();
}

class _JobFilterBoxState extends State<JobFilterBox>
    with TickerProviderStateMixin {
  late TextEditingController jobRoleController;
  late TextEditingController locationController;
  late TextEditingController companyController;
  late Set<String> selectedJobTypes;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    jobRoleController = TextEditingController(
      text: widget.currentFilters.jobRole ?? '',
    );
    locationController = TextEditingController(
      text: widget.currentFilters.location ?? '',
    );
    companyController = TextEditingController(
      text:
          widget.currentFilters.companies.isNotEmpty
              ? widget.currentFilters.companies.first
              : '',
    );
    selectedJobTypes = Set<String>.from(widget.currentFilters.jobTypes);

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    jobRoleController.dispose();
    locationController.dispose();
    companyController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      jobRoleController.clear();
      locationController.clear();
      companyController.clear();
      selectedJobTypes.clear();
    });
  }

  bool get _hasActiveFilters {
    return jobRoleController.text.isNotEmpty ||
        locationController.text.isNotEmpty ||
        companyController.text.isNotEmpty ||
        selectedJobTypes.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.92,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.85,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(),
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFilterSection(
                                    'Job Role',
                                    Icons.work_outline_rounded,
                                    _EnhancedComboField(
                                      hintText:
                                          'Enter Desired Job Role or Keyword',
                                      controller: jobRoleController,
                                      suggestions: widget.jobRoles,
                                      prefixIcon: Icons.search_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  _buildFilterSection(
                                    'Location',
                                    Icons.location_on_outlined,
                                    _EnhancedComboField(
                                      hintText: 'Enter Desired Job Location',
                                      controller: locationController,
                                      suggestions: widget.locations,
                                      prefixIcon: Icons.place_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  _buildFilterSection(
                                    'Company',
                                    Icons.business_outlined,
                                    _EnhancedComboField(
                                      hintText: 'Enter Desired Company Name',
                                      controller: companyController,
                                      suggestions: widget.companies,
                                      prefixIcon: Icons.business_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  _buildJobTypeSection(),
                                  const SizedBox(height: 32),

                                  _buildActionButtons(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFD),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE8E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF6C63FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Jobs',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: -0.2,
                  ),
                ),
                if (_hasActiveFilters)
                  Text(
                    '${_getActiveFiltersCount()} filters active',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6C63FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (_hasActiveFilters)
            TextButton(
              onPressed: _resetFilters,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
              child: Text(
                'Reset',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFF666666),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, IconData icon, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF666666)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        field,
      ],
    );
  }

  Widget _buildJobTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 18,
              color: Color(0xFF666666),
            ),
            const SizedBox(width: 8),
            Text(
              'Job Type',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.1,
              ),
            ),
            if (selectedJobTypes.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedJobTypes.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8F0), width: 1),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children:
                widget.jobTypes.map((type) {
                  final selected = selectedJobTypes.contains(type);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              selectedJobTypes.remove(type);
                            } else {
                              selectedJobTypes.add(type);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? const Color(0xFF6C63FF)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color:
                                  selected
                                      ? const Color(0xFF6C63FF)
                                      : const Color(0xFFE0E0E6),
                              width: selected ? 0 : 1.5,
                            ),
                            boxShadow:
                                selected
                                    ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF6C63FF,
                                        ).withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                        spreadRadius: 0,
                                      ),
                                    ]
                                    : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                        spreadRadius: 0,
                                      ),
                                    ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child:
                                    selected
                                        ? Container(
                                          key: const ValueKey('check'),
                                          width: 18,
                                          height: 18,
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        )
                                        : const SizedBox(
                                          key: ValueKey('empty'),
                                        ),
                              ),
                              Text(
                                type,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      selected
                                          ? Colors.white
                                          : const Color(0xFF333333),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: const Color(0xFF6C63FF).withOpacity(0.3),
            ),
            onPressed: () {
              widget.onApply(
                JobFilters(
                  jobRole:
                      jobRoleController.text.isNotEmpty
                          ? jobRoleController.text
                          : null,
                  location:
                      locationController.text.isNotEmpty
                          ? locationController.text
                          : null,
                  companies:
                      companyController.text.isNotEmpty
                          ? {companyController.text}
                          : {},
                  jobTypes: selectedJobTypes,
                ),
              );
              Navigator.of(context).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  _hasActiveFilters
                      ? 'Apply ${_getActiveFiltersCount()} Filters'
                      : 'Apply Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
              side: const BorderSide(color: Color(0xFFE0E0E6), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              _resetFilters();
              widget.onClear();
              Navigator.of(context).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.clear_all_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Clear All',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (jobRoleController.text.isNotEmpty) count++;
    if (locationController.text.isNotEmpty) count++;
    if (companyController.text.isNotEmpty) count++;
    if (selectedJobTypes.isNotEmpty) count++;
    return count;
  }
}

class _EnhancedComboField extends StatefulWidget {
  final String? hintText;
  final TextEditingController controller;
  final List<String> suggestions;
  final IconData? prefixIcon;

  const _EnhancedComboField({
    this.hintText,
    required this.controller,
    required this.suggestions,
    this.prefixIcon,
  });

  @override
  State<_EnhancedComboField> createState() => _EnhancedComboFieldState();
}

class _EnhancedComboFieldState extends State<_EnhancedComboField>
    with SingleTickerProviderStateMixin {
  bool _showSuggestions = false;
  List<String> _filteredSuggestions = [];
  late AnimationController _dropdownAnimationController;
  late Animation<double> _dropdownAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = widget.suggestions;

    _dropdownAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _dropdownAnimation = CurvedAnimation(
      parent: _dropdownAnimationController,
      curve: Curves.easeOut,
    );

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            setState(() {
              _showSuggestions = false;
            });
            _dropdownAnimationController.reverse();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dropdownAnimationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterSuggestions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuggestions = widget.suggestions;
      } else {
        _filteredSuggestions =
            widget.suggestions
                .where(
                  (item) => item.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _toggleDropdown() {
    setState(() {
      _showSuggestions = !_showSuggestions;
      if (_showSuggestions) {
        _filterSuggestions(widget.controller.text);
        _dropdownAnimationController.forward();
        _focusNode.requestFocus();
      } else {
        _dropdownAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _focusNode.hasFocus
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFFE0E0E6),
              width: _focusNode.hasFocus ? 2 : 1.5,
            ),
            color: Colors.white,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 15,
                color: const Color(0xFFA0A0A8),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon:
                  widget.prefixIcon != null
                      ? Icon(
                        widget.prefixIcon,
                        color: const Color(0xFF999999),
                        size: 20,
                      )
                      : null,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.controller.clear();
                          _filteredSuggestions = widget.suggestions;
                          _showSuggestions = false;
                        });
                        _dropdownAnimationController.reverse();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF666666),
                          size: 16,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: _toggleDropdown,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 8),
                      child: AnimatedRotation(
                        turns: _showSuggestions ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF999999),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
            ),
            onChanged: (value) {
              _filterSuggestions(value);
              if (!_showSuggestions && value.isNotEmpty) {
                setState(() {
                  _showSuggestions = true;
                });
                _dropdownAnimationController.forward();
              }
              setState(() {});
            },
            onTap: () {
              if (!_showSuggestions) {
                setState(() {
                  _showSuggestions = true;
                  _filterSuggestions(widget.controller.text);
                });
                _dropdownAnimationController.forward();
              }
            },
          ),
        ),
        AnimatedBuilder(
          animation: _dropdownAnimation,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _dropdownAnimation.value,
                child: child,
              ),
            );
          },
          child:
              _showSuggestions && _filteredSuggestions.isNotEmpty
                  ? Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE0E0E6),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filteredSuggestions.length,
                      separatorBuilder:
                          (context, index) => const Divider(
                            height: 1,
                            color: Color(0xFFF0F0F2),
                          ),
                      itemBuilder: (context, index) {
                        final suggestion = _filteredSuggestions[index];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          title: Text(
                            suggestion,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          onTap: () {
                            widget.controller.text = suggestion;
                            setState(() {
                              _showSuggestions = false;
                            });
                            _dropdownAnimationController.reverse();
                            _focusNode.unfocus();
                          },
                          trailing: const Icon(
                            Icons.arrow_outward_rounded,
                            size: 16,
                            color: Color(0xFFCCCCCC),
                          ),
                          hoverColor: const Color(0xFFF8F8FC),
                        );
                      },
                    ),
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
