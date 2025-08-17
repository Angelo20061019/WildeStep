import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminGearStoreManagePage extends StatefulWidget {
  const AdminGearStoreManagePage({super.key});

  @override
  State<AdminGearStoreManagePage> createState() => _AdminGearStoreManagePageState();
}

class _AdminGearStoreManagePageState extends State<AdminGearStoreManagePage> {
  String _searchText = '';
  String _selectedFilter = 'All Stores';

  final List<String> _filters = [
    'All Stores',
    'High Revenue',
  ];

  Stream<List<Map<String, dynamic>>> _getStoresStream() async* {
    final storesStream = FirebaseFirestore.instance
        .collection('gearStores')
        .snapshots();

    await for (final snapshot in storesStream) {
      yield snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> stores) {
    List<Map<String, dynamic>> filtered = stores;
    if (_selectedFilter == 'Active') {
      filtered = filtered.where((store) => store['status'] == 'active').toList();
    } else if (_selectedFilter == 'Inactive') {
      filtered = filtered.where((store) => store['status'] == 'inactive').toList();
    } else if (_selectedFilter == 'High Revenue') {
      filtered = filtered.where((store) => (store['totalRevenue'] ?? 0) > 40000).toList();
    }
    if (_searchText.isNotEmpty) {
      filtered = filtered.where((store) {
        final name = (store['storeName'] ?? '').toString().toLowerCase();
        final location = (store['location'] ?? '').toString().toLowerCase();
        return name.contains(_searchText.toLowerCase()) || location.contains(_searchText.toLowerCase());
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Stores', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getStoresStream(),
        builder: (context, snapshot) {
          final stores = snapshot.data ?? [];
          final filteredStores = _applyFilters(stores);

          final totalStores = stores.length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search stores...',
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
                    const SizedBox(height: 18),
                    // Centered Total Stores Stat
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statCard('$totalStores', 'Total Stores', Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredStores.isEmpty
                    ? const Center(child: Text('No stores found.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: filteredStores.length,
                        itemBuilder: (context, index) {
                          final store = filteredStores[index];
                          return _storeCard(store);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _storeCard(Map<String, dynamic> store) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    store['storeName'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
                // Removed status badge
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  store['location'] ?? '',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Fetch and show stats from orders collection
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('gearStores')
                  .doc(store['id'])
                  .collection('orders')
                  .get(),
              builder: (context, snapshot) {
                int totalRevenue = 0;
                int itemsRented = 0;
                int totalRentals = 0;

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final confirmedOrders = (data['confirmedOrders'] as List?) ?? [];
                    for (var order in confirmedOrders) {
                      final cart = (order['cart'] as List?) ?? [];
                      for (var item in cart) {
                        totalRevenue += (item['price'] ?? 0) as int;
                      }
                      itemsRented += cart.length;
                      totalRentals += 1;
                    }
                  }
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Use Wrap for responsiveness
                    return Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth / 3 - 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹$totalRevenue',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text('Total Revenue', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: constraints.maxWidth / 3 - 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$itemsRented',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text('Items Rented', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: constraints.maxWidth / 3 - 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$totalRentals',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text('Total Rentals', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              'Last activity: ${store['lastActivity'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      // Manage logic
                    },
                    child: const Text('Manage', style: TextStyle(fontWeight: FontWeight.bold)),
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