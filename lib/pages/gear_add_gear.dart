import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class GearAddGearPage extends StatefulWidget {
  final String userEmail;
  const GearAddGearPage({super.key, required this.userEmail});

  @override
  State<GearAddGearPage> createState() => _GearAddGearPageState();
}

class _GearAddGearPageState extends State<GearAddGearPage> {
  final _formKey = GlobalKey<FormState>();
  String? _mainImage;
  final List<String> _images = [];
  String? _productName;
  String? _selectedCategory;
  String? _description;
  double? _dailyRate;
  double? _weeklyRate;
  double? _monthlyRate;
  int? _quantity;
  double? _weight;
  String? _dimensions;

  final List<String> _storeCategories = [
    'Camping',
    'Hiking',
  ];

  bool _showSnackBar = false;
  String _snackBarMessage = '';

  final ImagePicker _picker = ImagePicker();

  // Helper to upload image and get URL
  Future<String?> _uploadImage(XFile imageFile, {bool main = false}) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('gear_images')
          .child('${widget.userEmail}_${DateTime.now().millisecondsSinceEpoch}_${main ? "main" : "extra"}.jpg');
      await ref.putData(await imageFile.readAsBytes());
      return await ref.getDownloadURL();
    } catch (e) {
      setState(() {
        _showSnackBar = true;
        _snackBarMessage = 'Image upload failed: $e';
      });
      return null;
    }
  }

  Future<void> _pickImage({bool main = false}) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final url = await _uploadImage(pickedFile, main: main);
      if (url != null) {
        setState(() {
          if (main) {
            _mainImage = url;
          } else {
            if (_images.length < 5) {
              _images.add(url);
            }
          }
        });
      }
    }
  }

  Future<void> _saveGear() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      final userEmail = widget.userEmail;
      final categoryCollection = _selectedCategory?.toLowerCase();
      try {
        await FirebaseFirestore.instance
            .collection('gearStores')
            .doc(userEmail)
            .collection(categoryCollection!)
            .add({
          'mainImage': _mainImage,
          'images': _images,
          'productName': _productName,
          'category': _selectedCategory,
          'description': _description,
          'dailyRate': _dailyRate,
          'weeklyRate': _weeklyRate,
          'monthlyRate': _monthlyRate,
          'quantity': _quantity,
          'weight': _weight,
          'dimensions': _dimensions,
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _showSnackBar = true;
          _snackBarMessage = 'Gear added to inventory!';
        });
        Navigator.of(context).pop();
      } catch (e) {
        setState(() {
          _showSnackBar = true;
          _snackBarMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show SnackBar after build (safe way)
    if (_showSnackBar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_snackBarMessage)),
        );
      });
      // Do NOT call setState here, just reset the flag
      _showSnackBar = false;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add New Gear',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Product Images
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Product Images', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(main: true),
                            child: Container(
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt, size: 32, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(
                                      _mainImage == null ? 'Add Main Image' : 'Main Image Added',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(),
                            child: Container(
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add, size: 32, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add More',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Maximum 5 images, up to 5MB each',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Basic Information
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Basic Information', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Enter product name' : null,
                      onSaved: (val) => _productName = val,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: _storeCategories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      value: _selectedCategory,
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      },
                      validator: (val) => val == null ? 'Select category' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        hintText: 'Describe the gear features, specifications, and benefits...',
                      ),
                      maxLines: 3,
                      onSaved: (val) => _description = val,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Pricing
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pricing', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Daily Rate',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (val) => _dailyRate = double.tryParse(val ?? ''),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Weekly Rate',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (val) => _weeklyRate = double.tryParse(val ?? ''),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Monthly Rate',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (val) => _monthlyRate = double.tryParse(val ?? ''),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Inventory & Specifications
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Inventory & Specifications', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity',
                        border: OutlineInputBorder(),
                        hintText: 'Available quantity',
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (val) => _quantity = int.tryParse(val ?? ''),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Weight (Kg)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (val) => _weight = double.tryParse(val ?? ''),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Dimensions',
                              border: OutlineInputBorder(),
                              hintText: 'L x W x H',
                            ),
                            onSaved: (val) => _dimensions = val,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Add Gear Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add Gear to Inventory',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _saveGear,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class SomeOtherPage extends StatelessWidget {
  final String userEmail;
  const SomeOtherPage({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Some Other Page')),
      body: Center(
        child: ElevatedButton(
          child: Text('Add New Gear'),
          onPressed: () {
            // Navigate to GearAddGearPage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GearAddGearPage(userEmail: userEmail),
              ),
            );
          },
        ),
      ),
    );
  }
}