import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'landing_page.dart';
import 'gear_add_gear.dart';
import 'gear_store_manage_orders.dart';
import 'gear_store_manage_gear.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class GearHomePage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const GearHomePage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              child: Text(
                userData['storeName']?.substring(0, 1).toUpperCase() ?? 'G',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gearStores')
            .doc(userData['email'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final totalRentals = data['totalRentals'] ?? 0;
          final totalRevenue = data['totalRevenue'] ?? 0;
          final itemsRented = data['itemsRented'] ?? 0;
          final newOrders = data['newOrders'] ?? 0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.green[100],
                        child: Text(
                          userData['storeName']?.substring(0, 1).toUpperCase() ?? 'G',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${userData['storeName'] ?? 'Mountain Gear Co.'}!',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage your outdoor gear rental business',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Overview Cards
                  Row(
                    children: [
                      Expanded(
                        child: _overviewCard(
                          icon: Icons.card_giftcard,
                          value: '$totalRentals',
                          label: 'Total Rentals',
                          color: Colors.blue,
                          percent: '',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _overviewCard(
                          icon: Icons.attach_money,
                          value: '₹$totalRevenue',
                          label: 'Total Revenue',
                          color: Colors.green,
                          percent: '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _overviewCard(
                          icon: Icons.inventory_2,
                          value: '$itemsRented',
                          label: 'Items Rented',
                          color: Colors.orange,
                          percent: '',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _overviewCard(
                          icon: Icons.new_releases,
                          value: '$newOrders',
                          label: 'New Orders',
                          color: Colors.purple,
                          percent: '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Recent Orders Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'View All',
                          style: TextStyle(color: Colors.green, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('gearStores')
                        .doc(userData['email'])
                        .collection('orders')
                        .snapshots(),
                    builder: (context, orderSnapshot) {
                      if (orderSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: Text('No orders yet', style: TextStyle(color: Colors.grey))),
                        );
                      }

                      final orders = orderSnapshot.data!.docs;

                      if (orders.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: Text('No orders yet', style: TextStyle(color: Colors.grey))),
                        );
                      }

                      // Show the most recent order (active or closed) for each user
                      return Column(
                        children: orders.take(3).map((doc) {
                          final order = doc.data() as Map<String, dynamic>;
                          final cart = (order['cart'] as List?) ?? [];
                          final closedOrders = (order['closedOrders'] as List?) ?? [];
                          final userId = doc.id;

                          // Show active order if cart is not empty, otherwise show last closed order
                          Map<String, dynamic>? displayOrder;
                          String status = 'Closed';
                          if (cart.isNotEmpty) {
                            displayOrder = {
                              'cart': cart,
                              'createdAt': order['createdAt'],
                            };
                            status = 'Active';
                          } else if (closedOrders.isNotEmpty) {
                            displayOrder = closedOrders.last as Map<String, dynamic>;
                            status = 'Closed';
                          }

                          if (displayOrder == null) return SizedBox();

                          final items = (displayOrder['cart'] as List)
                              .map((item) => item['productName'])
                              .join(', ');
                          final price = (displayOrder['cart'] as List)
                              .fold<int>(0, (sum, item) => sum + ((item['price'] ?? 0) as int));
                          final date = displayOrder['createdAt'] != null
                              ? (displayOrder['createdAt'] is String
                                  ? displayOrder['createdAt'].split('T').first
                                  : (displayOrder['createdAt'] is Timestamp
                                      ? (displayOrder['createdAt'] as Timestamp).toDate().toString().split(' ').first
                                      : ''))
                              : '';

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('campers').doc(userId).get(),
                            builder: (context, userSnap) {
                              final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
                              final customerName = userData['name'] ?? 'Unknown User';

                              return _orderCard(
                                orderId: doc.id,
                                name: customerName,
                                items: items,
                                price: '₹$price',
                                date: date,
                                status: status,
                                statusColor: _getStatusColor(status),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Upcoming Deliveries Section
                  const Text(
                    'Upcoming Deliveries',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('gearStores')
                        .doc(userData['email'])
                        .collection('deliveries')
                        .snapshots(),
                    builder: (context, deliverySnapshot) {
                      if (deliverySnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!deliverySnapshot.hasData || deliverySnapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: Text('No deliveries yet', style: TextStyle(color: Colors.grey))),
                        );
                      }
                      // Group deliveries by day
                      final deliveriesByDay = <String, List<Map<String, dynamic>>>{};
                      for (var doc in deliverySnapshot.data!.docs) {
                        final delivery = doc.data() as Map<String, dynamic>;
                        final day = delivery['deliveryDate'] ?? 'Unknown Day';
                        deliveriesByDay.putIfAbsent(day, () => []).add(delivery);
                      }
                      return Column(
                        children: deliveriesByDay.entries.map((entry) {
                          return _deliveryCard(
                            day: entry.key,
                            deliveries: entry.value.map((delivery) {
                              return {
                                'type': delivery['type'] ?? '',
                                'id': delivery['deliveryId'] ?? '',
                                'name': delivery['customerName'] ?? '',
                                'time': delivery['time'] ?? '',
                                'icon': delivery['type'] == 'Delivery'
                                    ? Icons.local_shipping
                                    : Icons.card_giftcard,
                                'iconColor': delivery['type'] == 'Delivery'
                                    ? Colors.blue
                                    : Colors.green,
                              };
                            }).toList(),
                            dotColor: Colors.red,
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Quick Actions Section
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _quickActionCard(
                          icon: Icons.add,
                          label: 'Add New Gear',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GearAddGearPage(userEmail: userData['email']),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickActionCard(
                          icon: Icons.inventory_2,
                          label: 'Manage Inventory',
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GearStoreManageGearPage(userEmail: userData['email']),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _quickActionCard(
                          icon: Icons.list_alt,
                          label: 'View Orders',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GearStoreManageOrdersPage(userEmail: userData['email']),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickActionCard(
                          icon: Icons.headset_mic,
                          label: 'Customer Support',
                          color: Colors.orange,
                          onTap: () async {
                            final Uri phoneUri = Uri(scheme: 'tel', path: '+94710452822');
                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _overviewCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required String percent,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderCard({
    required String orderId,
    required String name,
    required String items,
    required String price,
    required String date,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    name.substring(0, 1),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    items,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _deliveryCard({
    required String day,
    required List<Map<String, dynamic>> deliveries,
    required Color dotColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...deliveries.map((delivery) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      delivery['icon'],
                      color: delivery['iconColor'],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${delivery['type']} ${delivery['id']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        delivery['name'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      delivery['time'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LandingPage(),
                  ),
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.blue;
      case 'delivery':
        return Colors.orange;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}