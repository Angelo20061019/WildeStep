import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../database/database_helper.dart';
import '../helpers/image_helper.dart';
import 'dart:io';

class AddEditLocationPage extends StatefulWidget {
  final Map<String, dynamic>? location;

  const AddEditLocationPage({super.key, this.location});

  @override
  State<AddEditLocationPage> createState() => _AddEditLocationPageState();
}

class _AddEditLocationPageState extends State<AddEditLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Form controllers
  late TextEditingController _locationNameController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _durationController;
  late TextEditingController _descriptionController;
  late TextEditingController _rulesController;

  List<String> _selectedImages = [];
  String _selectedDifficulty = 'Easy';
  String _selectedLocationType = 'Hiking';
  bool _isLoading = false;

  final List<String> _difficultyLevels = ['Easy', 'Moderate', 'Hard'];
  final List<String> _locationTypes = ['Hiking', 'Camping'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _locationNameController = TextEditingController(
      text: widget.location?['locationName'] ?? '',
    );
    _latitudeController = TextEditingController(
      text: widget.location?['latitude']?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.location?['longitude']?.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: widget.location?['duration'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.location?['description'] ?? '',
    );
    _rulesController = TextEditingController(
      text: widget.location?['rulesAndRegulations'] ?? '',
    );

    // Initialize selected images from existing location
    if (widget.location != null && widget.location!['images'] != null) {
      final images = widget.location!['images'];
      if (images is String && images.isNotEmpty) {
        _selectedImages = images.split(',').map((e) => e.trim()).toList();
      } else if (images is List) {
        _selectedImages = List<String>.from(images);
      }
    }

    if (widget.location != null) {
      _selectedDifficulty = widget.location!['difficulty'] ?? 'Easy';
      _selectedLocationType = widget.location!['locationType'] ?? 'Hiking';
    }
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.location != null;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Location' : 'Add New Location',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveLocation,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 600, // Prevents cards from being too wide on tablets
                ),
                child: Center(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                isEditing
                                    ? Icons.edit_location
                                    : Icons.add_location_alt,
                                size: 60,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isEditing
                                    ? 'Update Location Details'
                                    : 'Create New Location',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isEditing
                                    ? 'Modify the location information below'
                                    : 'Fill in the details to add a new camping or hiking location',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Basic Information Section
                        _buildSectionCard(
                          title: 'Basic Information',
                          icon: Icons.info_outline,
                          children: [
                            _buildTextField(
                              controller: _locationNameController,
                              label: 'Location Name',
                              icon: Icons.place,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter location name';
                                }
                                return null;
                              },
                              hintText: 'e.g., Eagle Peak Trail, Pine Forest Campsite',
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _durationController,
                              label: 'Duration',
                              icon: Icons.access_time,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter duration';
                                }
                                return null;
                              },
                              hintText: 'e.g., 2-3 hours, Full day, 2 days',
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              value: _selectedDifficulty,
                              label: 'Difficulty Level',
                              icon: Icons.trending_up,
                              items: _difficultyLevels,
                              onChanged: (value) {
                                setState(() {
                                  _selectedDifficulty = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              value: _selectedLocationType,
                              label: 'Location Type',
                              icon: Icons.nature,
                              items: _locationTypes,
                              onChanged: (value) {
                                setState(() {
                                  _selectedLocationType = value!;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Location Coordinates Section
                        _buildSectionCard(
                          title: 'Location Coordinates',
                          icon: Icons.map,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: screenWidth - 64, // 16*2 padding + 16 between fields
                                ),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: _buildTextField(
                                        controller: _latitudeController,
                                        label: 'Latitude',
                                        icon: Icons.my_location,
                                        keyboardType: TextInputType.number,
                                        hintText: 'e.g., 6.9271',
                                        validator: (value) {
                                          if (value != null && value.isNotEmpty) {
                                            final lat = double.tryParse(value);
                                            if (lat == null || lat < -90 || lat > 90) {
                                              return 'Invalid latitude';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Flexible(
                                      child: _buildTextField(
                                        controller: _longitudeController,
                                        label: 'Longitude',
                                        icon: Icons.location_on,
                                        keyboardType: TextInputType.number,
                                        hintText: 'e.g., 79.8612',
                                        validator: (value) {
                                          if (value != null && value.isNotEmpty) {
                                            final lng = double.tryParse(value);
                                            if (lng == null || lng < -180 || lng > 180) {
                                              return 'Invalid longitude';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info, color: Colors.blue, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Coordinates are optional but help users find the exact location',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Description Section
                        _buildSectionCard(
                          title: 'Description & Details',
                          icon: Icons.description,
                          children: [
                            _buildTextField(
                              controller: _descriptionController,
                              label: 'Description',
                              icon: Icons.article,
                              maxLines: 4,
                              hintText:
                                  'Describe the location, its features, what makes it special, facilities available, etc.',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Rules and Regulations Section
                        _buildSectionCard(
                          title: 'Rules & Regulations',
                          icon: Icons.policy,
                          children: [
                            _buildTextField(
                              controller: _rulesController,
                              label: 'Rules and Regulations',
                              icon: Icons.rule,
                              maxLines: 5,
                              hintText:
                                  'Enter important rules, regulations, and guidelines for this location (e.g., camping restrictions, fire safety, wildlife precautions, permits required, etc.)',
                              validator: null, // Optional field
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Rules help ensure visitor safety and environmental protection',
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Images Section
                        _buildSectionCard(
                          title: 'Images',
                          icon: Icons.photo_library,
                          children: [
                            // Selected Images Display
                            if (_selectedImages.isNotEmpty) ...[
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(right: 12),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: ImageHelper.getImageWidget(
                                              _selectedImages[index],
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Add Images Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _pickImages,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.add_photo_alternate),
                                label: Text(
                                  _selectedImages.isEmpty
                                      ? 'Add Images'
                                      : 'Add More Images (${_selectedImages.length}/5)',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info, color: Colors.blue, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'You can add up to 5 images from your device gallery or camera. Images are optional.',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.pop(context),
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
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveLocation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : FittedBox(
                                        child: Text(
                                          isEditing ? 'Update Location' : 'Add Location',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Image picker methods
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 images allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newImages = await ImageHelper.pickImages(
      context: context,
      maxImages: 5 - _selectedImages.length,
    );

    if (newImages.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(newImages);
      });
    }
  }

  void _removeImage(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Image'),
          content: const Text('Are you sure you want to remove this image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  ImageHelper.deleteImage(_selectedImages[index]);
                  _selectedImages.removeAt(index);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
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
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
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
        fillColor: Colors.grey[50],
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload new images to Firebase Storage and get URLs
      List<String> imageUrls = [];
      for (var imagePath in _selectedImages) {
        if (imagePath.startsWith('http')) {
          // Already uploaded, keep as is
          imageUrls.add(imagePath);
        } else {
          // Local file, upload to Firebase Storage
          final file = File(imagePath);
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
          final ref = FirebaseStorage.instance.ref().child('location_images/$fileName');
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      final locationData = {
        'locationName': _locationNameController.text.trim(),
        'latitude': _latitudeController.text.isNotEmpty
            ? double.tryParse(_latitudeController.text.trim())
            : null,
        'longitude': _longitudeController.text.isNotEmpty
            ? double.tryParse(_longitudeController.text.trim())
            : null,
        'duration': _durationController.text.trim(),
        'images': imageUrls, // Store as List<String> of URLs
        'description': _descriptionController.text.trim(),
        'rulesAndRegulations': _rulesController.text.trim(),
        'difficulty': _selectedDifficulty,
        'locationType': _selectedLocationType,
        'createdAt': DateTime.now(),
      };

      if (widget.location != null) {
        // Update existing location
        await _databaseHelper.updateLocation(
          widget.location!['id'],
          locationData,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Add new location
        await _databaseHelper.insertLocation(locationData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving location: $e'),
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
