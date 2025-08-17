import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../helpers/image_helper.dart';
import 'location_details_page.dart';

class LocationsSearchPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? userType;
  final String? initialLocationTypeFilter;

  const LocationsSearchPage({
    super.key,
    this.userData,
    this.userType,
    this.initialLocationTypeFilter,
  });

  @override
  State<LocationsSearchPage> createState() => _LocationsSearchPageState();
}

class _LocationsSearchPageState extends State<LocationsSearchPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allLocations = [];
  List<Map<String, dynamic>> _filteredLocations = [];
  bool _isLoading = true;
  String _selectedLocationTypeFilter = 'All';
  String _selectedDifficultyFilter = 'All';

  final List<String> _locationTypeFilters = ['All', 'Hiking', 'Camping'];
  final List<String> _difficultyFilters = ['All', 'Easy', 'Moderate', 'Hard'];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocationTypeFilter != null) {
      _selectedLocationTypeFilter = widget.initialLocationTypeFilter!;
    }
    _loadLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final locations = await _databaseHelper.getAllLocations();

      setState(() {
        _allLocations = locations;
        _filteredLocations = locations;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading locations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    String searchQuery = _searchController.text.toLowerCase();

    setState(() {
      _filteredLocations = _allLocations.where((location) {
        // Search filter
        bool matchesSearch =
            location['locationName'].toString().toLowerCase().contains(
              searchQuery,
            ) ||
            (location['description'] ?? '').toString().toLowerCase().contains(
              searchQuery,
            );

        // Location type filter
        bool matchesLocationType =
            _selectedLocationTypeFilter == 'All' ||
            (location['locationType'] ?? 'Hiking') ==
                _selectedLocationTypeFilter;

        // Difficulty filter
        bool matchesDifficulty =
            _selectedDifficultyFilter == 'All' ||
            (location['difficulty'] ?? 'Easy') == _selectedDifficultyFilter;

        return matchesSearch && matchesLocationType && matchesDifficulty;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text(
          'Explore Locations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
      ),
      body: Column(
        children: [
          // Search and filters section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Search bar
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'Search locations...',
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Filter chips
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        'Type',
                        _selectedLocationTypeFilter,
                        _locationTypeFilters,
                        (value) {
                          setState(() {
                            _selectedLocationTypeFilter = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterDropdown(
                        'Difficulty',
                        _selectedDifficultyFilter,
                        _difficultyFilters,
                        (value) {
                          setState(() {
                            _selectedDifficultyFilter = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results section
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : _filteredLocations.isEmpty
                ? _buildEmptyState()
                : _buildLocationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          hint: Text(label),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No locations found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredLocations.length,
      itemBuilder: (context, index) {
        final location = _filteredLocations[index];
        return _buildLocationCard(location);
      },
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationDetailsPage(
              location: location,
              userData: widget.userData,
              userType: widget.userType,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 4,
        shadowColor: Colors.green.withOpacity(0.10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: _buildLocationImage(location),
              ),
            ),

            // Location details
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          location['locationName'] ?? 'Unknown Location',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${location['averageRating']?.toStringAsFixed(1) ?? '0.0'}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              ' (${location['reviewCount'] ?? 0})',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Tags (Duration, Difficulty, Type)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTag(
                          icon: Icons.access_time,
                          text: location['duration'] ?? 'Unknown',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildTag(
                          icon: Icons.trending_up,
                          text: location['difficulty'] ?? 'Unknown',
                          color: _getDifficultyColor(location['difficulty']),
                        ),
                        const SizedBox(width: 8),
                        _buildTag(
                          icon: _getLocationTypeIcon(location['locationType']),
                          text: location['locationType'] ?? 'Hiking',
                          color: _getLocationTypeColor(location['locationType']),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description
                  if (location['description'] != null &&
                      location['description'].isNotEmpty)
                    Text(
                      location['description'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
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
    // Support Firestore List<String> images
    final List<String> imageList = (location['images'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];

    if (imageList.isNotEmpty && imageList[0].isNotEmpty) {
      return ImageHelper.getImageWidget(imageList[0], fit: BoxFit.cover);
    }

    // Default image when no image available
    return Container(
      decoration: BoxDecoration(color: Colors.green.withOpacity(0.2)),
      child: const Center(
        child: Icon(Icons.landscape, size: 80, color: Colors.green),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
}
