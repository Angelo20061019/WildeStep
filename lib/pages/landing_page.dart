import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Add this import
import 'user_profile_page.dart';
import 'locations_search_page.dart';
import 'weather_alert_page.dart'; // <-- Add this import
import 'gear_page.dart'; // <-- Add this import
import '../database/database_helper.dart';
import 'dart:io';
import 'emergancy_contact.dart';
import 'dart:async';
import 'dart:math'; // <-- Add this import

class LandingPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? userType;

  const LandingPage({super.key, this.userData, this.userType});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _featuredLocations = [];
  List<Map<String, dynamic>> _featuredComments = [];
  bool _isLoadingLocations = true;
  bool _isLoadingComments = true;
  bool _loading = true;
  String? _error;

  // Add for banner image
  String? _bannerImageUrl;
  bool _isBannerLoading = true;

  List<Map<String, dynamic>> _popularGear = [];
  List<Map<String, dynamic>> _displayedGear = []; // <-- Add this
  Timer? _gearSwitchTimer;
  final Random _random = Random(); // <-- Add this

  List<MapEntry<String, String>> _allSafetyTips = [];
  List<MapEntry<String, String>> _displayedSafetyTips = [];
  Timer? _safetyTipTimer;

  @override
  void initState() {
    super.initState();
    _fetchBannerImage();
    _loadFeaturedLocations();
    _loadFeaturedComments();
    _loadData();
    _loadPopularGear();
    _listenSafetyTips();
  }

  @override
  void dispose() {
    _gearSwitchTimer?.cancel();
    _safetyTipTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBannerImage() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('appcontent')
          .doc('homebanner')
          .get();
      setState(() {
        _bannerImageUrl = doc.data()?['image url'];
        _isBannerLoading = false;
      });
    } catch (e) {
      setState(() {
        _bannerImageUrl = null;
        _isBannerLoading = false;
      });
    }
  }

  Future<void> _loadFeaturedLocations() async {
    try {
      final locations = await _databaseHelper.getAllLocations();
      // Ensure each location has an 'images' field that is a List<String>
      for (var loc in locations) {
        if (!loc.containsKey('images') || loc['images'] == null) {
          loc['images'] = <String>[];
        }
      }
      setState(() {
        _featuredLocations = locations.take(2).toList();
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _loadFeaturedComments() async {
    try {
      final allReviews = await _databaseHelper.getAllLocationReviews();
      setState(() {
        // Show only the top-rated comments (rating 4 or 5) and limit to 3
        _featuredComments = allReviews
            .where((review) => review['rating'] >= 4)
            .take(3)
            .toList();
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      // Replace with your actual data loading logic
      // Example:
      // _locations = await _databaseHelper.getAllLocations();
      // _comments = await _databaseHelper.getAllLocationReviews();
      await Future.delayed(const Duration(seconds: 1)); // Simulate loading
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadPopularGear() async {
    try {
      final storesSnap = await FirebaseFirestore.instance.collection('gearStores').get();
      List<Map<String, dynamic>> gearItems = [];

      for (var storeDoc in storesSnap.docs) {
        final campingSnap = await storeDoc.reference.collection('camping').get();
        gearItems.addAll(campingSnap.docs.map((doc) {
          final data = doc.data();
          data['storeId'] = storeDoc.id;
          data['category'] = 'Camping';
          data['productId'] = doc.id;
          return data;
        }));

        final hikingSnap = await storeDoc.reference.collection('hiking').get();
        gearItems.addAll(hikingSnap.docs.map((doc) {
          final data = doc.data();
          data['storeId'] = storeDoc.id;
          data['category'] = 'Hiking';
          data['productId'] = doc.id;
          return data;
        }));
      }

      setState(() {
        _popularGear = gearItems;
      });

      _pickRandomGear(); // Pick initial random gear
      _startGearSwitchTimer(); // Start timer after loading gear
    } catch (e) {
      // Handle error if needed
    }
  }

  void _startGearSwitchTimer() {
    _gearSwitchTimer?.cancel();
    _gearSwitchTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _pickRandomGear();
    });
  }

  void _pickRandomGear() {
    if (_popularGear.length <= 2) {
      setState(() {
        _displayedGear = List.from(_popularGear);
      });
      return;
    }
    // Pick 2 unique random indices
    int first = _random.nextInt(_popularGear.length);
    int second;
    do {
      second = _random.nextInt(_popularGear.length);
    } while (second == first);

    setState(() {
      _displayedGear = [_popularGear[first], _popularGear[second]];
    });
  }

  void _listenSafetyTips() {
    FirebaseFirestore.instance.collection('safety_tips').snapshots().listen((snapshot) {
      final tips = <MapEntry<String, String>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data.forEach((title, message) {
          tips.add(MapEntry(title, message.toString()));
        });
      }
      setState(() {
        _allSafetyTips = tips;
      });
      _pickRandomSafetyTips();
      _startSafetyTipTimer();
    });
  }

  void _startSafetyTipTimer() {
    _safetyTipTimer?.cancel();
    if (_allSafetyTips.length <= 2) {
      setState(() {
        _displayedSafetyTips = List.from(_allSafetyTips);
      });
      return;
    }
    _safetyTipTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _pickRandomSafetyTips();
    });
  }

  void _pickRandomSafetyTips() {
    if (_allSafetyTips.length <= 2) {
      setState(() {
        _displayedSafetyTips = List.from(_allSafetyTips);
      });
      return;
    }
    final random = Random();
    int first = random.nextInt(_allSafetyTips.length);
    int second;
    do {
      second = random.nextInt(_allSafetyTips.length);
    } while (second == first);
    setState(() {
      _displayedSafetyTips = [_allSafetyTips[first], _allSafetyTips[second]];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $_error')),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA), // Soft background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with banner image from Firestore
            SizedBox(
              height: 400,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner image
                  if (_isBannerLoading)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade200, Colors.green.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else if (_bannerImageUrl != null && _bannerImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      child: Image.network(
                        _bannerImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.green.shade100,
                          child: const Center(
                              child: Icon(Icons.image_not_supported,
                                  size: 80, color: Colors.green)),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade200, Colors.green.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                          child: Icon(Icons.image, size: 80, color: Colors.green)),
                    ),
                  // Overlay gradient and content
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        // App bar
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.terrain, color: Colors.white, size: 32),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'WildSteps',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black26,
                                              blurRadius: 8,
                                              offset: Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (widget.userData != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Welcome ${_getUserName()}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfilePage(
                                        userData: widget.userData,
                                        userType: widget.userType,
                                      ),
                                    ),
                                  );
                                },
                                child: _buildProfileAvatar(),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Main content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              const Text(
                                'Find your next adventure...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                LocationsSearchPage(
                                                  userData: widget.userData,
                                                  userType: widget.userType,
                                                  initialLocationTypeFilter:
                                                      'Hiking',
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.directions_walk),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      label: const Text('Browse Trails'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                LocationsSearchPage(
                                                  userData: widget.userData,
                                                  userType: widget.userType,
                                                  initialLocationTypeFilter:
                                                      'Camping',
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.cabin, color: Colors.white),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Colors.white,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      label: const Text('Camping Sites'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom navigation bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.location_on, 'Nearby', true, () {}),
                  _buildNavItem(Icons.store, 'Gear', false, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GearPage()),
                    );
                  }),
                  _buildNavItem(Icons.warning, 'Emergency SOS', false, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmergencyContactPage()),
                    );
                  }),
                  _buildNavItem(Icons.cloud, 'Weather', false, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WeatherAlertPage()),
                    );
                  }),
                ],
              ),
            ),

            // Featured Trails Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.landscape, color: Colors.green, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Featured Locations',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationsSearchPage(
                                userData: widget.userData,
                                userType: widget.userType,
                              ),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Featured location cards
                  _isLoadingLocations
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        )
                      : _featuredLocations.isEmpty
                      ? const Center(
                          child: Text(
                            'No locations available yet.\nAdmin can add locations to display here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _featuredLocations.length,
                          itemBuilder: (context, index) {
                            final location = _featuredLocations[index];
                            return Column(
                              children: [
                                _buildLocationCard(location),
                                if (_featuredLocations.indexOf(location) <
                                    _featuredLocations.length - 1)
                                  const SizedBox(height: 16),
                              ],
                            );
                          },
                        ),
                ],
              ),
            ),

            // Featured Comments Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Featured Comments',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingComments
                      ? const Center(child: CircularProgressIndicator())
                      : _featuredComments.isEmpty
                      ? _buildNoCommentsMessage()
                      : Column(
                          children: _featuredComments
                              .map(
                                (comment) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildFeaturedComment(comment),
                                ),
                              )
                              .toList(),
                        ),
                ],
              ),
            ),

            // Popular Gear Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Popular Gear',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _popularGear.isEmpty
                      ? const Center(child: Text('No gear available yet.', style: TextStyle(color: Colors.grey)))
                      : Row(
                          children: List.generate(_displayedGear.length, (i) {
                            final gear = _displayedGear[i];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => IndividualGearProductPage(
                                        storeId: gear['storeId'],
                                        productId: gear['productId'],
                                        category: gear['category'],
                                        productData: gear,
                                      ),
                                    ),
                                  );
                                },
                                child: _buildGearCard(
                                  gear['name'] ?? gear['productName'] ?? 'Gear',
                                  gear['price'] ?? 'Rs. 0/day',
                                  gear['rating'] != null
                                      ? '⭐ ${gear['rating'].toString()}'
                                      : '⭐ 0.0',
                                  gear['imageUrl'] ?? gear['mainImage'] ?? '',
                                ),
                              ),
                            );
                          }),
                        ),
                ],
              ),
            ),

            // Safety First Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Safety First',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _allSafetyTips.isEmpty
                      ? const Text(
                          'No safety tips available.',
                          style: TextStyle(color: Colors.grey),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _displayedSafetyTips.map((entry) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: ListTile(
                                leading: const Icon(Icons.health_and_safety, color: Colors.green),
                                title: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  entry.value,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.green : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.green : Colors.grey,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationsSearchPage(
              userData: widget.userData,
              userType: widget.userType,
            ),
          ),
        );
      },
      child: Card(
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        shadowColor: Colors.green.withOpacity(0.15),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location image
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: _buildLocationImage(location),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          location['locationName'] ?? 'Unknown Location',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${location['averageRating']?.toStringAsFixed(1) ?? '0.0'} (${location['reviewCount'] ?? 0})',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _getLocationTypeIcon(location['locationType']),
                        size: 18,
                        color: _getLocationTypeColor(location['locationType']),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${location['locationType'] ?? 'Hiking'}  ⏱ ${location['duration'] ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    location['description'] ?? 'No description available.',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationImage(Map<String, dynamic> location) {
    // Firestore: images is a List<String>
    final List<String> imageList = (location['images'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];

    if (imageList.isNotEmpty && imageList[0].isNotEmpty) {
      // Show first image
      return Image.network(
        imageList[0],
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.2)),
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 80, color: Colors.green),
          ),
        ),
      );
    }

    // Default image when no image available
    return Container(
      decoration: BoxDecoration(color: Colors.green.withOpacity(0.2)),
      child: const Center(
        child: Icon(Icons.landscape, size: 80, color: Colors.green),
      ),
    );
  }

  Color _getLocationTypeColor(String? locationType) {
    switch (locationType?.toLowerCase()) {
      case 'camping':
        return Colors.purple;
      case 'hiking':
        return Colors.brown;
      default:
        return Colors.teal;
    }
  }

  IconData _getLocationTypeIcon(String? locationType) {
    switch (locationType?.toLowerCase()) {
      case 'camping':
        return Icons.cabin;
      case 'hiking':
        return Icons.hiking;
      default:
        return Icons.terrain;
    }
  }

  Widget _buildFeaturedComment(Map<String, dynamic> comment) {
    // Try to get the comment text from possible keys
    String? commentText = comment['comment'];
    if (commentText == null || commentText.trim().isEmpty) {
      commentText = comment['review'];
    }
    if (commentText == null || commentText.trim().isEmpty) {
      commentText = comment['text'];
    }
    if (commentText == null || commentText.trim().isEmpty) {
      commentText = null;
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.green.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.7),
                  child: Text(
                    comment['userName'] != null
                        ? comment['userName']
                              .toString()
                              .substring(0, 1)
                              .toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['userName'] ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < (comment['rating'] ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.orange,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '${comment['rating'] ?? 0}.0',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    comment['userType'] ?? 'User',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              (commentText != null && commentText.trim().isNotEmpty)
                  ? commentText
                  : 'No comment provided.',
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Posted ${_formatDate(comment['createdAt'] ?? comment['reviewDate'])}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCommentsMessage() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.comment_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No featured comments yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to leave a review and share your experience!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'recently';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else {
        return 'recently';
      }
    } catch (e) {
      return 'recently';
    }
  }

  Widget _buildGearCard(
    String title,
    String price,
    String rating,
    String imageUrl,
  ) {
    return Card(
      elevation: 5,
      shadowColor: Colors.blue.withOpacity(0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.backpack, size: 40, color: Colors.blue),
                      ),
                    )
                  : const Icon(Icons.backpack, size: 40, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rating,
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }



  String _getUserName() {
    if (widget.userData == null) return '';

    // Try to get name from different user types
    if (widget.userData!.containsKey('firstName') &&
        widget.userData!.containsKey('lastName')) {
      return '${widget.userData!['firstName']} ${widget.userData!['lastName']}';
    } else if (widget.userData!.containsKey('name')) {
      return widget.userData!['name'];
    } else if (widget.userData!.containsKey('storeName')) {
      return widget.userData!['storeName'];
    } else if (widget.userData!.containsKey('email')) {
      return widget.userData!['email'].split(
        '@',
      )[0]; // Use email prefix as fallback
    }
    return 'User';
  }

  Widget _buildProfileAvatar() {
    String? profileImagePath = widget.userData?['profileImageUrl'] ?? widget.userData?['profileImage'];

    bool isNetworkImage = profileImagePath != null &&
        (profileImagePath.startsWith('http://') || profileImagePath.startsWith('https://'));
    bool isLocalFile = profileImagePath != null &&
        profileImagePath.isNotEmpty &&
        !isNetworkImage;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: ClipOval(
        child: isNetworkImage
            ? Image.network(
                profileImagePath,
                fit: BoxFit.cover,
                width: 36,
                height: 36,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              )
            : isLocalFile
                ? Image.file(
                    File(profileImagePath),
                    fit: BoxFit.cover,
                    width: 36,
                    height: 36,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  )
                : Container(
                    color: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
      ),
    );
  }
}

// You need to create IndividualGearProductPage to show product details
// Example stub:
class IndividualGearProductPage extends StatelessWidget {
  final String storeId;
  final String productId;
  final String category;
  final Map<String, dynamic> productData;

  const IndividualGearProductPage({
    super.key,
    required this.storeId,
    required this.productId,
    required this.category,
    required this.productData,
  });

  @override
  Widget build(BuildContext context) {
    // Build your product details UI here using productData
    return Scaffold(
      appBar: AppBar(
        title: Text(productData['name'] ?? 'Product Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Center(
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.blue.withOpacity(0.2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    productData['imageUrl'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 80, color: Colors.blue),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Product name and price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    productData['name'] ?? 'Unknown Product',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  productData['price'] != null
                      ? 'Rs. ${productData['price'].toString()}'
                      : 'Free',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Product rating
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < (productData['rating'] ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.orange,
                    size: 16,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${productData['rating'] ?? 0}.0',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Product description
            Text(
              productData['description'] ?? 'No description available.',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Implement rental action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Rent Now'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Implement wishlist action
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Add to Wishlist'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
