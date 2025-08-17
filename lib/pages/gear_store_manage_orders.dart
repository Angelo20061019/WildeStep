import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GearStoreManageOrdersPage extends StatefulWidget {
  final String userEmail;
  const GearStoreManageOrdersPage({super.key, required this.userEmail});

  @override
  State<GearStoreManageOrdersPage> createState() => _GearStoreManageOrdersPageState();
}

class _GearStoreManageOrdersPageState extends State<GearStoreManageOrdersPage> {
  String _searchText = '';
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Pending',
    'Shipped',
    'Delivered',
  ];

  Stream<List<Map<String, dynamic>>> _getOrdersStream() async* {
    final ordersStream = FirebaseFirestore.instance
        .collection('gearStores')
        .doc(widget.userEmail)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();

    await for (final snapshot in ordersStream) {
      yield snapshot.docs.map((doc) => doc.data()).toList();
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> orders) {
    List<Map<String, dynamic>> filtered = orders;
    if (_selectedFilter != 'All') {
      filtered = filtered.where((order) =>
        (order['status'] ?? '').toString().toLowerCase() == _selectedFilter.toLowerCase()
      ).toList();
    }
    if (_searchText.isNotEmpty) {
      filtered = filtered.where((order) {
        final orderId = (order['orderId'] ?? '').toString().toLowerCase();
        final customer = (order['customerName'] ?? '').toString().toLowerCase();
        return orderId.contains(_searchText.toLowerCase()) || customer.contains(_searchText.toLowerCase());
      }).toList();
    }
    return filtered;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getOrdersStream(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          final filteredOrders = _applyFilters(orders);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by Order ID or Customer',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchText = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Filters
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final selected = filter == _selectedFilter;
                          return ChoiceChip(
                            label: Text(filter, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            selectedColor: Colors.blue,
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredOrders.isEmpty
                    ? const Center(child: Text('No orders found.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _orderCard(order);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  order['orderId'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(order['status'] ?? '').withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (order['status'] ?? '').toString().capitalize(),
                    style: TextStyle(
                      color: _statusColor(order['status'] ?? ''),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(order['customerName'] ?? '', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Items:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order['items'] ?? '',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Period:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order['date'] ?? '',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Total:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(width: 6),
                Text(
                  'Rs. ${order['price'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  // View details logic
                },
                child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper extension for capitalizing status text
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}