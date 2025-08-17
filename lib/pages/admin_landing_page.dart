import 'package:flutter/material.dart';
import 'login_selection_page.dart';
import 'users_list_page.dart';
import 'locations_management_page.dart';
import 'reviews_management_page.dart';
import '../database/database_helper.dart';
import 'emergancy_manage.dart';
import 'admin_gear_store_manage.dart';

class AdminLandingPage extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const AdminLandingPage({super.key, required this.adminData});

  @override
  State<AdminLandingPage> createState() => _AdminLandingPageState();
}

class _AdminLandingPageState extends State<AdminLandingPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  int _totalUsers = 0;
  int _campingLocations = 0;
  int _hikingLocations = 0;
  int _gearStores = 0;
  int _totalReviews = 0;
  bool _isLoading = true;
  Map<String, dynamic> _adminData = {};

  @override
  void initState() {
    super.initState();
    _adminData = Map<String, dynamic>.from(widget.adminData);
    _loadAdminData();
    _loadStatistics();
  }

  Future<void> _loadAdminData() async {
    final adminUid = _adminData['id'];
    if (adminUid == null || adminUid.toString().isEmpty) {
      return;
    }
    final admin = await _databaseHelper.getAdminById(adminUid);
    if (admin != null && mounted) {
      setState(() {
        _adminData.addAll(admin);
      });
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final totalUsers = await _databaseHelper.getTotalUsersCount();
      final gearStores = await _databaseHelper.getGearStoresCount();
      final campingLocations = await _databaseHelper.getCampingLocationsCount();
      final hikingLocations = await _databaseHelper.getHikingLocationsCount();
      final totalReviews = await _databaseHelper.getTotalReviewsCount();

      setState(() {
        _totalUsers = totalUsers;
        _gearStores = gearStores;
        _campingLocations = campingLocations;
        _hikingLocations = hikingLocations;
        _totalReviews = totalReviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header (no hamburger menu)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _loadStatistics,
                                child: const Icon(Icons.refresh, size: 24),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  _showLogoutDialog(context);
                                },
                                child: const Icon(Icons.logout, size: 24),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Welcome Card (fix overflow with Flexible and maxLines)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Welcome, ${_adminData['username'] ?? ''} 👋',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Here's what's happening with WildSteps today",
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Admin Credentials Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
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
                            const Text(
                              'Admin Credentials',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildCredentialRow(
                              'Username',
                              _adminData['username'] ?? '',
                            ),
                            _buildCredentialRow(
                              'Email',
                              _adminData['email'] ?? '',
                            ),
                            _buildCredentialRow(
                              'Phone Number',
                              _adminData['phone number']?.toString() ?? '',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Statistics Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UsersListPage(),
                                ),
                              );
                            },
                            child: _buildStatCard(
                              icon: Icons.people,
                              title: _isLoading ? '...' : _totalUsers.toString(),
                              subtitle: 'Total Users',
                              color: Colors.blue,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LocationsManagementPage(),
                                ),
                              ).then((_) {
                                _loadStatistics();
                              });
                            },
                            child: _buildStatCard(
                              icon: Icons.cabin,
                              title: _isLoading
                                  ? '...'
                                  : _campingLocations.toString(),
                              subtitle: 'Camping',
                              color: Colors.green,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LocationsManagementPage(),
                                ),
                              ).then((_) {
                                _loadStatistics();
                              });
                            },
                            child: _buildStatCard(
                              icon: Icons.hiking,
                              title: _isLoading ? '...' : _hikingLocations.toString(),
                              subtitle: 'Hiking Locations',
                              color: Colors.orange,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReviewsManagementPage(),
                                ),
                              );
                            },
                            child: _buildStatCard(
                              icon: Icons.rate_review,
                              title: _isLoading ? '...' : _totalReviews.toString(),
                              subtitle: 'Total Reviews',
                              color: Colors.deepPurple,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminGearStoreManagePage(),
                                ),
                              );
                            },
                            child: _buildStatCard(
                              icon: Icons.store,
                              title: _isLoading ? '...' : _gearStores.toString(),
                              subtitle: 'Gear Stores',
                              color: Colors.purple,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EmergencyManagePage(),
                                ),
                              );
                            },
                            child: _buildStatCard(
                              icon: Icons.phone_in_talk,
                              title: 'Emergency',
                              subtitle: 'Contacts',
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Additional Stats
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.yellow.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isLoading ? '...' : _totalReviews.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Total Reviews',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // No Recent Activities section here
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginSelectionPage()),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
