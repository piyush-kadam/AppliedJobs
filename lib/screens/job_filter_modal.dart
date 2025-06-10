import 'package:flutter/material.dart';
import 'package:appliedjobs/models/filter_model.dart';

class JobFilterBox extends StatefulWidget {
  final JobFilters currentFilters;
  final void Function(JobFilters) onApply;
  final VoidCallback onClear;
  final List<String> jobRoles;
  final List<String> locations; // merged: from jobs + static/geonames
  final List<String> companies; // merged: from jobs + gist
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

class _JobFilterBoxState extends State<JobFilterBox> {
  late TextEditingController jobRoleController;
  late TextEditingController locationController;
  late TextEditingController companyController;
  late Set<String> selectedJobTypes;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    jobRoleController.dispose();
    locationController.dispose();
    companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(28),
        elevation: 18,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title and close icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24), // for symmetry
                    Text(
                      'Filter Jobs',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Colors.black,
                        letterSpacing: 0.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        }
                      },
                      child: Icon(Icons.close, color: Colors.black54, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Job Role Field with Dropdown and Manual Input
                _ComboField(
                  label: 'Job Role',
                  hintText: 'Search for job role',
                  controller: jobRoleController,
                  suggestions: widget.jobRoles,
                  borderColor: Color(0xFF6C63FF),
                ),
                const SizedBox(height: 16),

                // Location Field with Dropdown and Manual Input
                _ComboField(
                  label: 'Location',
                  hintText: 'Search for location',
                  controller: locationController,
                  suggestions: widget.locations,
                  borderColor: Colors.transparent,
                ),
                const SizedBox(height: 16),

                // Company Field with Dropdown and Manual Input
                _ComboField(
                  label: 'Company',
                  hintText: 'Search for company',
                  controller: companyController,
                  suggestions: widget.companies,
                  borderColor: Colors.transparent,
                ),
                const SizedBox(height: 18),

                // Job Type (chips)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Job Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      widget.jobTypes.map((type) {
                        final selected = selectedJobTypes.contains(type);
                        return ChoiceChip(
                          label: Text(
                            type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : Colors.black87,
                            ),
                          ),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                selectedJobTypes.add(type);
                              } else {
                                selectedJobTypes.remove(type);
                              }
                            });
                          },
                          selectedColor: Color(0xFF6C63FF),
                          backgroundColor: Color(0xFFEDEFFD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          visualDensity: VisualDensity(
                            horizontal: -2,
                            vertical: -2,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 0,
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 26),

                // Apply Filters Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
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
                    child: Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Clear Filters Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF6C63FF),
                      side: BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      backgroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() {
                        jobRoleController.clear();
                        locationController.clear();
                        companyController.clear();
                        selectedJobTypes.clear();
                      });
                      widget.onClear();
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Clear Filters',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget for combo fields (text input with dropdown suggestions)
class _ComboField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final List<String> suggestions;
  final Color borderColor;

  const _ComboField({
    required this.label,
    this.hintText,
    required this.controller,
    required this.suggestions,
    this.borderColor = Colors.transparent,
  });

  @override
  State<_ComboField> createState() => _ComboFieldState();
}

class _ComboFieldState extends State<_ComboField> {
  bool _showSuggestions = false;
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = widget.suggestions;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black,
            ),
            hintStyle: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Colors.black45,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: widget.borderColor, width: 1.6),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: widget.borderColor, width: 1.6),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: widget.borderColor, width: 1.6),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            fillColor: Colors.white,
            filled: true,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clear button - only show when field has text
                if (widget.controller.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.black54, size: 20),
                    onPressed: () {
                      setState(() {
                        widget.controller.clear();
                        _filteredSuggestions = widget.suggestions;
                        _showSuggestions = false;
                      });
                    },
                  ),
                // Dropdown arrow button
                IconButton(
                  icon: Icon(
                    _showSuggestions
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSuggestions = !_showSuggestions;
                      if (_showSuggestions) {
                        _filterSuggestions(widget.controller.text);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          onChanged: (value) {
            _filterSuggestions(value);
            if (!_showSuggestions && value.isNotEmpty) {
              setState(() {
                _showSuggestions = true;
              });
            }
            // Trigger rebuild to show/hide clear button
            setState(() {});
          },
          onTap: () {
            setState(() {
              _showSuggestions = true;
              _filterSuggestions(widget.controller.text);
            });
          },
        ),
        if (_showSuggestions && _filteredSuggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4),
            constraints: BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _filteredSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _filteredSuggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    widget.controller.text = suggestion;
                    setState(() {
                      _showSuggestions = false;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
