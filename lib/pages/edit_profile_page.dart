import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/database_helper.dart';
import '../helpers/image_helper.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userType;

  const EditProfilePage({
    super.key,
    required this.userData,
    required this.userType,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Common fields
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  // Camper/Guide fields
  late TextEditingController _fullNameController;
  late TextEditingController _experienceLevelController;

  // Camper specific fields
  late TextEditingController _preferredActivitiesController;

  // Guide specific fields
  late TextEditingController _guidingSpecializationController;
  late TextEditingController _shortBioController;
  late TextEditingController _availableFromController;
  late TextEditingController _availableUntilController;

  // Gear Store fields
  late TextEditingController _storeNameController;
  late TextEditingController _locationController;
  late TextEditingController _gearTypesController;
  late TextEditingController _businessHoursController;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _profileImagePath = widget.userData['profileImage'];

    _emailController = TextEditingController(
      text: widget.userData['email'] ?? '',
    );
    _passwordController = TextEditingController();

    _fullNameController = TextEditingController(
      text: widget.userData['fullName'] ?? '',
    );
    _experienceLevelController = TextEditingController(
      text: widget.userData['experienceLevel'] ?? '',
    );

    // Fix: Convert List to comma-separated string for TextEditingController
    _preferredActivitiesController = TextEditingController(
      text: (widget.userData['preferredActivities'] is List)
          ? (widget.userData['preferredActivities'] as List).join(', ')
          : (widget.userData['preferredActivities'] ?? ''),
    );

    _guidingSpecializationController = TextEditingController(
      text: widget.userData['guidingSpecialization'] ?? '',
    );
    _shortBioController = TextEditingController(
      text: widget.userData['shortBio'] ?? '',
    );
    _availableFromController = TextEditingController(
      text: widget.userData['availableFrom'] ?? '',
    );
    _availableUntilController = TextEditingController(
      text: widget.userData['availableUntil'] ?? '',
    );

    _storeNameController = TextEditingController(
      text: widget.userData['storeName'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.userData['location'] ?? '',
    );
    _gearTypesController = TextEditingController(
      text: (widget.userData['gearTypes'] is List)
          ? (widget.userData['gearTypes'] as List).join(', ')
          : (widget.userData['gearTypes'] ?? ''),
    );
    _businessHoursController = TextEditingController(
      text: widget.userData['businessHours'] ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _experienceLevelController.dispose();
    _preferredActivitiesController.dispose();
    _guidingSpecializationController.dispose();
    _shortBioController.dispose();
    _availableFromController.dispose();
    _availableUntilController.dispose();
    _storeNameController.dispose();
    _locationController.dispose();
    _gearTypesController.dispose();
    _businessHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onLongPress: _profileImagePath != null
                                ? _showRemoveImageDialog
                                : null,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                                image: _profileImagePath != null &&
                                        File(_profileImagePath!).existsSync()
                                    ? DecorationImage(
                                        image: FileImage(
                                          File(_profileImagePath!),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _profileImagePath == null ||
                                      !_profileImagePath!.isNotEmpty ||
                                      !File(_profileImagePath!).existsSync()
                                  ? Icon(
                                      Icons.person,
                                      color: Colors.grey[600],
                                      size: 60,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _pickProfileImage,
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          Text(
                            _profileImagePath != null
                                ? 'Tap camera to change photo'
                                : 'Tap camera to add photo',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          if (_profileImagePath != null)
                            Text(
                              'Long press to remove photo',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Form Fields based on user type
                if (widget.userType == 'camper') ..._buildCamperFields(),
                if (widget.userType == 'guide') ..._buildGuideFields(),
                if (widget.userType == 'gearStore') ..._buildGearStoreFields(),

                // Common fields
                const SizedBox(height: 24),
                _buildSectionTitle('Account Information'),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'New Password (leave empty to keep current)',
                  icon: Icons.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCamperFields() {
    return [
      _buildSectionTitle('Personal Information'),
      _buildTextField(
        controller: _fullNameController,
        label: 'Full Name',
        icon: Icons.person,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your full name';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      _buildDropdownField(
        value: _experienceLevelController.text.isNotEmpty
            ? _experienceLevelController.text
            : null,
        label: 'Experience Level',
        icon: Icons.trending_up,
        items: ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
        onChanged: (value) {
          _experienceLevelController.text = value ?? '';
        },
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _preferredActivitiesController,
        label: 'Preferred Activities',
        icon: Icons.favorite,
        maxLines: 2,
        hintText: 'e.g., Hiking, Camping, Rock Climbing',
      ),
    ];
  }

  List<Widget> _buildGuideFields() {
    return [
      _buildSectionTitle('Professional Information'),
      _buildTextField(
        controller: _fullNameController,
        label: 'Full Name',
        icon: Icons.person,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your full name';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      _buildDropdownField(
        value: _experienceLevelController.text.isNotEmpty
            ? _experienceLevelController.text
            : null,
        label: 'Experience Level',
        icon: Icons.trending_up,
        items: ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
        onChanged: (value) {
          _experienceLevelController.text = value ?? '';
        },
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _guidingSpecializationController,
        label: 'Guiding Specialization',
        icon: Icons.map,
        hintText: 'e.g., Mountain Hiking, Wildlife Tours',
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _shortBioController,
        label: 'Short Bio',
        icon: Icons.description,
        maxLines: 3,
        hintText: 'Tell us about your guiding experience...',
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _availableFromController,
        label: 'Available From',
        icon: Icons.access_time,
        hintText: 'e.g., 6:00 AM',
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _availableUntilController,
        label: 'Available Until',
        icon: Icons.access_time_filled,
        hintText: 'e.g., 8:00 PM',
      ),
    ];
  }

  List<Widget> _buildGearStoreFields() {
    return [
      _buildSectionTitle('Business Information'),
      _buildTextField(
        controller: _storeNameController,
        label: 'Store Name',
        icon: Icons.store,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your store name';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _locationController,
        label: 'Location',
        icon: Icons.location_on,
        hintText: 'e.g., Colombo, Sri Lanka',
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _gearTypesController,
        label: 'Gear Types',
        icon: Icons.backpack,
        maxLines: 2,
        hintText: 'e.g., Tents, Backpacks, Climbing gear',
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _businessHoursController,
        label: 'Business Hours',
        icon: Icons.schedule,
        hintText: 'e.g., Mon-Fri: 9AM-6PM, Sat-Sun: 10AM-4PM',
      ),
    ];
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    bool obscureText = false,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.green),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final String? imagePath = await ImageHelper.pickSingleImage(
        context: context,
      );

      if (imagePath != null) {
        setState(() {
          _profileImagePath = imagePath;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRemoveImageDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Profile Picture'),
          content: const Text(
            'Are you sure you want to remove your profile picture?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _profileImagePath = null;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile picture removed'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uid = widget.userData['id'];
      Map<String, dynamic> updatedData = {};

      // Profile image: upload if changed and not a URL
      File? newProfileImage;
      if (_profileImagePath != null && !_profileImagePath!.startsWith('http')) {
        newProfileImage = File(_profileImagePath!);
      }

      // User type specific fields
      switch (widget.userType) {
        case 'camper':
          updatedData['fullName'] = _fullNameController.text.trim();
          updatedData['experienceLevel'] = _experienceLevelController.text.trim();
          // Store as List<String>
          updatedData['preferredActivities'] = _preferredActivitiesController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          break;
        case 'guide':
          updatedData['fullName'] = _fullNameController.text.trim();
          updatedData['experienceLevel'] = _experienceLevelController.text.trim();
          updatedData['guidingSpecialization'] = _guidingSpecializationController.text.trim();
          updatedData['shortBio'] = _shortBioController.text.trim();
          updatedData['availableFrom'] = _availableFromController.text.trim();
          updatedData['availableUntil'] = _availableUntilController.text.trim();
          break;
        case 'gearStore':
          updatedData['storeName'] = _storeNameController.text.trim();
          updatedData['location'] = _locationController.text.trim();
          // Store as List<String>
          updatedData['gearTypes'] = _gearTypesController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          updatedData['businessHours'] = _businessHoursController.text.trim();
          break;
      }

      // Update profile image in Firestore if changed
      await _databaseHelper.updateUserProfile(
        uid: uid,
        userType: widget.userType,
        updatedData: updatedData,
        newProfileImage: newProfileImage,
      );

      // Update email if changed
      if (_emailController.text.trim() != (widget.userData['email'] ?? '')) {
        await FirebaseAuth.instance.currentUser?.updateEmail(_emailController.text.trim());
      }

      // Update password if provided
      if (_passwordController.text.isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.updatePassword(_passwordController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updatedData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
