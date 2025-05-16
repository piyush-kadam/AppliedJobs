// import 'package:flutter/material.dart';
// import 'package:appliedjobs/models/filter_model.dart';

// class JobFilterBox extends StatefulWidget {
//   final JobFilters currentFilters;
//   final void Function(JobFilters) onApply;
//   final VoidCallback onClear;

//   // Lists for dropdowns and options
//   final List<String> jobRoles;
//   final List<String> locations;
//   final List<String> applicationStatuses;
//   final List<String> companies;
//   final List<String> jobTypes;

//   const JobFilterBox({
//     Key? key,
//     required this.currentFilters,
//     required this.onApply,
//     required this.onClear,
//     required this.jobRoles,
//     required this.locations,
//     required this.applicationStatuses,
//     required this.companies,
//     required this.jobTypes,
//   }) : super(key: key);

//   @override
//   State<JobFilterBox> createState() => _JobFilterBoxState();
// }

// class _JobFilterBoxState extends State<JobFilterBox> {
//   late String? selectedJobRole;
//   late String? selectedLocation;
//   late String? selectedStatus;
//   late String? selectedCompany;
//   late Set<String> selectedJobTypes;

//   @override
//   void initState() {
//     super.initState();
//     selectedJobRole = widget.currentFilters.jobRole ?? widget.jobRoles.first;
//     selectedLocation = widget.currentFilters.location ?? widget.locations.first;
//     selectedStatus = widget.currentFilters.applicationStatus ?? widget.applicationStatuses.first;
//     selectedCompany = widget.currentFilters.companies.isNotEmpty
//         ? widget.currentFilters.companies.first
//         : null;
//     selectedJobTypes = Set<String>.from(widget.currentFilters.jobTypes);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Material(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         elevation: 16,
//         child: Container(
//           width: MediaQuery.of(context).size.width * 0.92,
//           padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Title
//                 Text(
//                   'Filter Jobs',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 20,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 SizedBox(height: 24),

//                 // Job Role Dropdown
//                 _DropdownField(
//                   label: 'Job Role',
//                   value: selectedJobRole,
//                   items: widget.jobRoles,
//                   onChanged: (val) => setState(() => selectedJobRole = val),
//                 ),
//                 SizedBox(height: 16),

//                 // Location Dropdown
//                 _DropdownField(
//                   label: 'Location',
//                   value: selectedLocation,
//                   items: widget.locations,
//                   onChanged: (val) => setState(() => selectedLocation = val),
//                 ),
//                 SizedBox(height: 16),

//                 // Application Status Dropdown
//                 _DropdownField(
//                   label: 'Application Status',
//                   value: selectedStatus,
//                   items: widget.applicationStatuses,
//                   onChanged: (val) => setState(() => selectedStatus = val),
//                 ),
//                 SizedBox(height: 16),

//                 // Companies (radio list)
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text('Companies', style: TextStyle(fontWeight: FontWeight.w500)),
//                 ),
//                 Container(
//                   height: 140,
//                   margin: const EdgeInsets.only(top: 8, bottom: 8),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: ListView(
//                     shrinkWrap: true,
//                     children: widget.companies.map((company) {
//                       return RadioListTile<String>(
//                         value: company,
//                         groupValue: selectedCompany,
//                         onChanged: (val) => setState(() => selectedCompany = val),
//                         title: Text(company),
//                         dense: true,
//                         contentPadding: EdgeInsets.symmetric(horizontal: 8),
//                         activeColor: Color(0xFF3D47D1),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//                 SizedBox(height: 12),

//                 // Job Type (chips)
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text('Job Type', style: TextStyle(fontWeight: FontWeight.w500)),
//                 ),
//                 Wrap(
//                   spacing: 8,
//                   children: widget.jobTypes.map((type) {
//                     final selected = selectedJobTypes.contains(type);
//                     return ChoiceChip(
//                       label: Text(type),
//                       selected: selected,
//                       onSelected: (val) {
//                         setState(() {
//                           if (val) {
//                             selectedJobTypes.add(type);
//                           } else {
//                             selectedJobTypes.remove(type);
//                           }
//                         });
//                       },
//                       selectedColor: Color(0xFF3D47D1),
//                       backgroundColor: Color(0xFFEDEFFD),
//                       labelStyle: TextStyle(
//                         color: selected ? Colors.white : Colors.black87,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     );
//                   }).toList(),
//                 ),
//                 SizedBox(height: 28),

//                 // Buttons
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Color(0xFF3D47D1),
//                           foregroundColor: Colors.white,
//                           padding: EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                         ),
//                         onPressed: () {
//                           widget.onApply(JobFilters(
//                             jobRole: selectedJobRole,
//                             location: selectedLocation,
//                             applicationStatus: selectedStatus,
//                             companies: selectedCompany != null ? {selectedCompany!} : {},
//                             jobTypes: selectedJobTypes,
//                           ));
//                         },
//                         child: Text('Apply Filters', style: TextStyle(fontSize: 16)),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: Color(0xFF3D47D1),
//                           side: BorderSide(color: Color(0xFF3D47D1)),
//                           padding: EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             selectedJobRole = widget.jobRoles.first;
//                             selectedLocation = widget.locations.first;
//                             selectedStatus = widget.applicationStatuses.first;
//                             selectedCompany = null;
//                             selectedJobTypes.clear();
//                           });
//                           widget.onClear();
//                         },
//                         child: Text('Clear Filters', style: TextStyle(fontSize: 16)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Helper widget for dropdown fields
// class _DropdownField extends StatelessWidget {
//   final String label;
//   final String? value;
//   final List<String> items;
//   final ValueChanged<String?> onChanged;

//   const _DropdownField({
//     required this.label,
//     required this.value,
//     required this.items,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return DropdownButtonFormField<String>(
//       value: value,
//       isExpanded: true,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
//         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       ),
//       items: items.map((item) {
//         return DropdownMenuItem<String>(
//           value: item,
//           child: Text(item),
//         );
//       }).toList(),
//       onChanged: onChanged,
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:appliedjobs/models/filter_model.dart';

class JobFilterBox extends StatefulWidget {
  final JobFilters currentFilters;
  final void Function(JobFilters) onApply;
  final VoidCallback onClear;
  final List<String> jobRoles;
  final List<String> locations;
  final List<String> applicationStatuses;
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
    required this.applicationStatuses,
    required this.companies,
    required this.jobTypes,
    this.onClose,
  }) : super(key: key);

  @override
  State<JobFilterBox> createState() => _JobFilterBoxState();
}

class _JobFilterBoxState extends State<JobFilterBox> {
  late String? selectedJobRole;
  late String? selectedLocation;
  late String? selectedStatus;
  late String? selectedCompany;
  late Set<String> selectedJobTypes;

  @override
  void initState() {
    super.initState();
    selectedJobRole = widget.currentFilters.jobRole ?? widget.jobRoles.first;
    selectedLocation = widget.currentFilters.location ?? widget.locations.first;
    selectedStatus =
        widget.currentFilters.applicationStatus ??
        widget.applicationStatuses.first;
    selectedCompany =
        widget.currentFilters.companies.isNotEmpty
            ? widget.currentFilters.companies.first
            : null;
    selectedJobTypes = Set<String>.from(widget.currentFilters.jobTypes);
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
                    // GestureDetector(
                    //   onTap: () => Navigator.of(context).maybePop(),
                    //   child: Icon(Icons.close, color: Colors.black54, size: 24),
                    // ),
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

                // Job Role Dropdown
                _DropdownField(
                  label: 'Job Role',
                  value: selectedJobRole,
                  items: widget.jobRoles,
                  onChanged: (val) => setState(() => selectedJobRole = val),
                  borderColor: Color(0xFF6C63FF),
                  fontSize: 15,
                  height: 54,
                ),
                const SizedBox(height: 16),

                // Location Dropdown
                _DropdownField(
                  label: 'Location',
                  value: selectedLocation,
                  items: widget.locations,
                  onChanged: (val) => setState(() => selectedLocation = val),
                  borderColor: Colors.transparent,
                  fontSize: 15,
                  height: 48,
                ),
                const SizedBox(height: 16),

                // Application Status Dropdown
                _DropdownField(
                  label: 'Application Status',
                  value: selectedStatus,
                  items: widget.applicationStatuses,
                  onChanged: (val) => setState(() => selectedStatus = val),
                  borderColor: Colors.transparent,
                  fontSize: 15,
                  height: 48,
                ),
                const SizedBox(height: 18),

                // Companies (radio list)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Companies',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  height: 120,
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Scrollbar(
                    thickness: 3,
                    radius: Radius.circular(8),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children:
                          widget.companies.map((company) {
                            return RadioListTile<String>(
                              value: company,
                              groupValue: selectedCompany,
                              onChanged:
                                  (val) =>
                                      setState(() => selectedCompany = val),
                              title: Text(
                                company,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              dense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              activeColor: Color(0xFF6C63FF),
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

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
                          jobRole: selectedJobRole,
                          location: selectedLocation,
                          applicationStatus: selectedStatus,
                          companies:
                              selectedCompany != null ? {selectedCompany!} : {},
                          jobTypes: selectedJobTypes,
                        ),
                      );
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
                        selectedJobRole = widget.jobRoles.first;
                        selectedLocation = widget.locations.first;
                        selectedStatus = widget.applicationStatuses.first;
                        selectedCompany = null;
                        selectedJobTypes.clear();
                      });
                      widget.onClear();
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

// Helper widget for dropdown fields
class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final Color borderColor;
  final double fontSize;
  final double height;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.borderColor = Colors.transparent,
    this.fontSize = 15,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
            color: Colors.black,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: borderColor, width: 1.6),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: borderColor, width: 1.6),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: borderColor, width: 1.6),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          fillColor: Colors.white,
          filled: true,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 26,
          color: Colors.black54,
        ),
        items:
            items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              );
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
