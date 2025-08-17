import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'individual_gear_store_page.dart';
import 'user_cart.dart';
import 'landing_page.dart';

class GearPage extends StatelessWidget {
  const GearPage({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => LandingPage()),
            );
          },
        ),
        title: const Text(
          'Find & Rent Gear',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.green),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              final storesSnapshot = await FirebaseFirestore.instance.collection('gearStores').get();
              String? foundStoreId;
              String? foundStoreName;

              for (final doc in storesSnapshot.docs) {
                final orderDoc = await doc.reference.collection('orders').doc(user.uid).get();
                final orderData = orderDoc.data();
                final cart = (orderData?['cart'] as List?) ?? [];
                if (cart.isNotEmpty) {
                  foundStoreId = doc.id;
                  foundStoreName = doc['storeName'] ?? 'Gear Store';
                  break;
                }
              }

              final storeId = foundStoreId ?? (storesSnapshot.docs.isNotEmpty ? storesSnapshot.docs.first.id : '');
              final storeName = foundStoreName ?? (storesSnapshot.docs.isNotEmpty ? storesSnapshot.docs.first['storeName'] ?? 'Gear Store' : 'Gear Store');

              if (storeId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserCartPage(storeId: storeId, storeName: storeName),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for gear or stores...',
                          hintStyle: TextStyle(color: Colors.green[300], fontWeight: FontWeight.w500),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search, color: Colors.green[400]),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Filter row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            icon: Icons.filter_alt,
                            label: 'All Filters',
                            selected: true,
                          ),
                          const SizedBox(width: 10),
                          _FilterChip(
                            icon: Icons.location_on,
                            label: 'Distance',
                          ),
                          const SizedBox(width: 10),
                          _FilterChip(
                            icon: Icons.attach_money,
                            label: 'Price',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Gear store cards from Firestore
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('gearStores').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No gear stores found.',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          );
                        }
                        final stores = snapshot.data!.docs;
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: stores.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 18),
                          itemBuilder: (context, index) {
                            final store = stores[index].data() as Map<String, dynamic>;
                            return _GearStoreCard(
                              icon: Icons.store,
                              iconColor: Colors.green,
                              name: store['storeName'] ?? 'Gear Store',
                              rating: store['rating']?.toString() ?? '4.5',
                              distance: store['distance'] ?? '',
                              status: 'Open',
                              statusColor: Colors.green[50],
                              statusTextColor: Colors.green[700],
                              description: store['gearTypes'] != null
                                  ? (store['gearTypes'] as List).join(', ')
                                  : 'Gear available',
                              onViewGear: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => IndividualGearStorePage(
                                      storeId: stores[index].id,
                                      storeName: store['storeName'] ?? 'Gear Store',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _FilterChip({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: selected ? Colors.green[600] : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: Colors.green.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
        border: Border.all(
          color: selected ? Colors.green : Colors.green[100]!,
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.green, size: 18),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.green[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GearStoreCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String rating;
  final String distance;
  final String status;
  final Color? statusColor;
  final Color? statusTextColor;
  final String description;
  final VoidCallback onViewGear;

  const _GearStoreCard({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.rating,
    required this.distance,
    required this.status,
    required this.statusColor,
    required this.statusTextColor,
    required this.description,
    required this.onViewGear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      elevation: 4,
      shadowColor: Colors.green.withOpacity(0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: iconColor, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black87,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 3),
                      Text(
                        rating,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (distance.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        distance,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onViewGear,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shadowColor: Colors.green.withOpacity(0.12),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                child: const Text('View Gear'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}