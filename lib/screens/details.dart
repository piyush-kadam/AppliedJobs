import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isEditing = false;

  // Work experience and education data
  List<Map<String, dynamic>> workExperiences = [];
  List<Map<String, dynamic>> educationHistory = [];
  List<String> skills = []; // List to store skills

  // Controllers for work experience and education fields
  List<Map<String, TextEditingController>> workExpControllers = [];
  List<Map<String, TextEditingController>> educationControllers = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final doc = await _firestore.collection('Users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        _usernameController.text = data?['username'] ?? '';
        _phoneController.text = data?['phone'] ?? '';
        _locationController.text = data?['location'] ?? '';
        _aboutController.text = data?['about'] ?? '';

        // Fetch work experience and education data
        if (data?['workExperiences'] != null) {
          workExperiences = List<Map<String, dynamic>>.from(
            data?['workExperiences'],
          );
          _initWorkExpControllers();
        }

        if (data?['educationHistory'] != null) {
          educationHistory = List<Map<String, dynamic>>.from(
            data?['educationHistory'],
          );
          _initEducationControllers();
        }

        // Fetch skills data
        if (data?['skills'] != null) {
          skills = List<String>.from(data?['skills']);
        }
      }
    } catch (e) {
      print('Error fetching details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initWorkExpControllers() {
    workExpControllers.clear();
    for (var exp in workExperiences) {
      workExpControllers.add({
        'position': TextEditingController(text: exp['position'] ?? ''),
        'company': TextEditingController(text: exp['company'] ?? ''),
        'startDate': TextEditingController(text: exp['startDate'] ?? ''),
        'endDate': TextEditingController(text: exp['endDate'] ?? ''),
        'description': TextEditingController(text: exp['description'] ?? ''),
      });
    }
  }

  void _initEducationControllers() {
    educationControllers.clear();
    for (var edu in educationHistory) {
      educationControllers.add({
        'fieldOfStudy': TextEditingController(text: edu['fieldOfStudy'] ?? ''),
        'university': TextEditingController(text: edu['university'] ?? ''),
        'startYear': TextEditingController(text: edu['startYear'] ?? ''),
        'endYear': TextEditingController(text: edu['endYear'] ?? ''),
        'grade': TextEditingController(text: edu['grade'] ?? ''),
      });
    }
  }

  void _updateWorkExperiencesFromControllers() {
    for (int i = 0; i < workExperiences.length; i++) {
      workExperiences[i]['position'] = workExpControllers[i]['position']!.text;
      workExperiences[i]['company'] = workExpControllers[i]['company']!.text;
      workExperiences[i]['startDate'] =
          workExpControllers[i]['startDate']!.text;
      workExperiences[i]['endDate'] = workExpControllers[i]['endDate']!.text;
      workExperiences[i]['description'] =
          workExpControllers[i]['description']!.text;
    }
  }

  void _updateEducationFromControllers() {
    for (int i = 0; i < educationHistory.length; i++) {
      educationHistory[i]['fieldOfStudy'] =
          educationControllers[i]['fieldOfStudy']!.text;
      educationHistory[i]['university'] =
          educationControllers[i]['university']!.text;
      educationHistory[i]['startYear'] =
          educationControllers[i]['startYear']!.text;
      educationHistory[i]['endYear'] = educationControllers[i]['endYear']!.text;
      educationHistory[i]['grade'] = educationControllers[i]['grade']!.text;
    }
  }

  Future<void> _saveDetails() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    // Update data collections from controllers
    _updateWorkExperiencesFromControllers();
    _updateEducationFromControllers();

    try {
      await _firestore.collection('Users').doc(user.uid).update({
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'about': _aboutController.text.trim(),
        'workExperiences': workExperiences,
        'educationHistory': educationHistory,
        'skills': skills, // Save skills to Firestore
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Details saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _isEditing = false);
      Navigator.pop(context);
    } catch (e) {
      print('Error saving details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save details.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    _skillController.dispose();

    // Dispose all work experience controllers
    for (var controllers in workExpControllers) {
      controllers.forEach((_, controller) => controller.dispose());
    }

    // Dispose all education controllers
    for (var controllers in educationControllers) {
      controllers.forEach((_, controller) => controller.dispose());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Your Details',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF3D47D1),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF3D47D1)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailCard(
                      icon: Icons.account_circle,
                      label: 'Username',
                      controller: _usernameController,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 20),
                    _buildDetailCard(
                      icon: Icons.phone,
                      label: 'Phone Number',
                      controller: _phoneController,
                      isEditing: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    _buildDetailCard(
                      icon: Icons.location_on,
                      label: 'Location',
                      controller: _locationController,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 20),
                    _buildDetailCard(
                      icon: Icons.person,
                      label: 'About Me',
                      controller: _aboutController,
                      isEditing: _isEditing,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),

                    // Skills Section
                    _buildSectionHeader('Skills', Icons.psychology),
                    const SizedBox(height: 10),
                    _buildSkillsSection(),
                    const SizedBox(height: 20),

                    // Work Experience Section
                    _buildSectionHeader('Work Experience', Icons.work),
                    const SizedBox(height: 10),
                    ...workExperiences.asMap().entries.map((entry) {
                      final index = entry.key;
                      final exp = entry.value;
                      return _buildWorkExperienceCard(exp, index);
                    }).toList(),

                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: _addWorkExperience,
                            icon: const Icon(
                              Icons.add,
                              color: Color(0xFF3D47D1),
                            ),
                            label: Text(
                              'Add Work Experience',
                              style: GoogleFonts.poppins(
                                color: Color(0xFF3D47D1),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF3D47D1)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Education Section
                    _buildSectionHeader('Education', Icons.school),
                    const SizedBox(height: 10),
                    ...educationHistory.asMap().entries.map((entry) {
                      final index = entry.key;
                      final edu = entry.value;
                      return _buildEducationCard(edu, index);
                    }).toList(),

                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: _addEducation,
                            icon: const Icon(
                              Icons.add,
                              color: Color(0xFF3D47D1),
                            ),
                            label: Text(
                              'Add Education',
                              style: GoogleFonts.poppins(
                                color: Color(0xFF3D47D1),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF3D47D1)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),
                    if (_isEditing)
                      Center(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3D47D1),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 40,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    'Save Changes',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSkillsSection() {
    if (!_isEditing) {
      // View mode - display skills as chips
      return skills.isEmpty
          ? Center(
            child: Text(
              'No skills added yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          )
          : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF3D47D1).withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  skills.map((skill) {
                    return Chip(
                      label: Text(
                        skill,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Color(0xFF3D47D1),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    );
                  }).toList(),
            ),
          );
    } else {
      // Edit mode - allow adding and removing skills
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF3D47D1).withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    textCapitalization:
                        TextCapitalization.words, // 👈 Add this line
                    decoration: InputDecoration(
                      hintText: 'Add a skill',
                      hintStyle: GoogleFonts.poppins(fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                    onSubmitted: _addSkill,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF3D47D1)),
                  onPressed: () {
                    if (_skillController.text.trim().isNotEmpty) {
                      _addSkill(_skillController.text);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (skills.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    skills.map((skill) {
                      return InputChip(
                        label: Text(
                          skill,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Color(0xFF3D47D1),
                        deleteIconColor: Colors.white,
                        onDeleted: () => _removeSkill(skill),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      );
                    }).toList(),
              )
            else
              Center(
                child: Text(
                  'No skills added yet',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  void _addSkill(String skill) {
    final trimmedSkill = skill.trim();
    if (trimmedSkill.isEmpty) return;

    final capitalizedSkill =
        trimmedSkill[0].toUpperCase() + trimmedSkill.substring(1);

    if (!skills.contains(capitalizedSkill)) {
      setState(() {
        skills.add(capitalizedSkill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      skills.remove(skill);
    });
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D47D1), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF3D47D1), size: 28),
          const SizedBox(width: 15),
          Expanded(
            child:
                isEditing
                    ? TextField(
                      controller: controller,
                      maxLines: null, // 👈 Allows multi-line input
                      keyboardType:
                          TextInputType.multiline, // 👈 Enables Enter/new line
                      textCapitalization:
                          TextCapitalization
                              .sentences, // 👈 Capitalize first letter of each sentence
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: label,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(0xFF3D47D1),
                        ),
                        border: InputBorder.none,
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3D47D1),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          controller.text.isEmpty
                              ? 'Not provided'
                              : controller.text,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF3D47D1), size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3D47D1),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkExperienceCard(Map<String, dynamic> exp, int index) {
    if (!_isEditing) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF3D47D1).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exp['position'] ?? 'Position',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  exp['employmentType'] ?? 'Type',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Color(0xFF3D47D1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              exp['company'] ?? 'Company',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${exp['startDate'] ?? 'Start Date'} - ${exp['endDate'] ?? 'Present'}',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
            ),
            if (exp['description'] != null && exp['description'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  exp['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      // Editable card
      // Make sure we have controllers for this card
      if (workExpControllers.length <= index) {
        workExpControllers.add({
          'position': TextEditingController(text: exp['position'] ?? ''),
          'company': TextEditingController(text: exp['company'] ?? ''),
          'startDate': TextEditingController(text: exp['startDate'] ?? ''),
          'endDate': TextEditingController(text: exp['endDate'] ?? ''),
          'description': TextEditingController(text: exp['description'] ?? ''),
        });
      }

      final controllers = workExpControllers[index];

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF3D47D1).withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Work Experience ${index + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D47D1),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeWorkExperience(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildDropdownField(
              label: 'Employment Type',
              value: exp['employmentType'] ?? 'Full-time',
              options: const [
                'Full-time',
                'Part-time',
                'Internship',
                'Freelance',
                'Contract',
              ],
              onChanged: (value) {
                setState(() {
                  exp['employmentType'] = value;
                });
              },
            ),
            _buildTextField(
              label: 'Position',
              controller: controllers['position']!,
            ),
            _buildTextField(
              label: 'Company',
              controller: controllers['company']!,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Start Date',
                    controller: controllers['startDate']!,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDateField(
                    label: 'End Date',
                    controller: controllers['endDate']!,
                    hintText: 'Leave empty if current',
                  ),
                ),
              ],
            ),
            _buildTextField(
              label: 'Description',
              controller: controllers['description']!,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEducationCard(Map<String, dynamic> edu, int index) {
    if (!_isEditing) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF3D47D1).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              edu['degree'] ?? 'Degree',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              edu['university'] ?? 'University',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${edu['startYear'] ?? 'Start'} - ${edu['endYear'] ?? 'End'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                if (edu['grade'] != null && edu['grade'].isNotEmpty)
                  Text(
                    'Grade: ${edu['grade']}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3D47D1),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Editable card
      // Make sure we have controllers for this card
      if (educationControllers.length <= index) {
        educationControllers.add({
          'fieldOfStudy': TextEditingController(
            text: edu['fieldOfStudy'] ?? '',
          ),
          'university': TextEditingController(text: edu['university'] ?? ''),
          'startYear': TextEditingController(text: edu['startYear'] ?? ''),
          'endYear': TextEditingController(text: edu['endYear'] ?? ''),
          'grade': TextEditingController(text: edu['grade'] ?? ''),
        });
      }

      final controllers = educationControllers[index];

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF3D47D1).withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Education ${index + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D47D1),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeEducation(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildDropdownField(
              label: 'Degree',
              value: edu['degree'] ?? 'Bachelor\'s',
              options: const [
                'High School',
                'Associate\'s',
                'Bachelor\'s',
                'Master\'s',
                'Doctorate',
                'Diploma',
                'Certificate',
                'Other',
              ],
              onChanged: (value) {
                setState(() {
                  edu['degree'] = value;
                });
              },
            ),
            _buildTextField(
              label: 'Field of Study',
              controller: controllers['fieldOfStudy']!,
            ),
            _buildTextField(
              label: 'University/Institution',
              controller: controllers['university']!,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildYearField(
                    label: 'Start Year',
                    controller: controllers['startYear']!,
                    value: '',
                    onChanged: (String) {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildYearField(
                    label: 'End Year',
                    controller: controllers['endYear']!,
                    value: '',
                    onChanged: (String) {},
                  ),
                ),
              ],
            ),
            _buildTextField(
              label: 'Grade/GPA',
              controller: controllers['grade']!,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: null, // Allows paragraph input
        textCapitalization:
            TextCapitalization.sentences, // Capitalize first letter
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Color(0xFF3D47D1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3D47D1), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Color(0xFF3D47D1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        value: value,
        items:
            options
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF3D47D1),
                  ),
                ),
                child: child!,
              );
            },
          );

          if (picked != null) {
            final formatted = DateFormat('MMM yyyy').format(picked);
            controller.text = formatted;
          }
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Color(0xFF3D47D1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
      ),
    );
  }

  Widget _buildYearField({
    required String label,
    required String value,
    required Function(String) onChanged,
    required TextEditingController controller,
  }) {
    // Remove this line - it's creating a new controller that shadows your parameter
    // final TextEditingController controller = TextEditingController(text: value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller, // Use the controller passed as parameter
        readOnly: true,
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
            initialDatePickerMode: DatePickerMode.year,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF3D47D1),
                  ),
                ),
                child: child!,
              );
            },
          );

          if (picked != null) {
            final formatted = DateFormat('yyyy').format(picked);
            controller.text = formatted;
            onChanged(formatted);
          }
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Color(0xFF3D47D1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
      ),
    );
  }

  void _addWorkExperience() {
    setState(() {
      workExperiences.add({
        'position': '',
        'company': '',
        'employmentType': 'Full-time',
        'startDate': '',
        'endDate': '',
        'description': '',
      });
    });
  }

  void _removeWorkExperience(int index) {
    setState(() {
      workExperiences.removeAt(index);
    });
  }

  void _addEducation() {
    setState(() {
      educationHistory.add({
        'degree': 'Bachelor\'s',
        'fieldOfStudy': '',
        'university': '',
        'startYear': '',
        'endYear': '',
        'grade': '',
      });
    });
  }

  void _removeEducation(int index) {
    setState(() {
      educationHistory.removeAt(index);
    });
  }
}
