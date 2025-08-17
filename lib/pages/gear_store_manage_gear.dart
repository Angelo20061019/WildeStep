import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GearStoreManageGearPage extends StatefulWidget {
  final String userEmail;
  const GearStoreManageGearPage({super.key, required this.userEmail});

  @override
  State<GearStoreManageGearPage> createState() => _GearStoreManageGearPageState();
}

class _GearStoreManageGearPageState extends State<GearStoreManageGearPage> {
  String _searchText = '';
  String _selectedFilter = 'All Items';

  final List<String> _filters = [
    'All Items',
    'Available',
    'Low Stock',
    'Hiking',
    'Camping',
  ];

  // Helper to get all items from both categories
  Stream<List<Map<String, dynamic>>> _getAllItemsStream() async* {
    final campingStream = FirebaseFirestore.instance
        .collection('gearStores')
        .doc(widget.userEmail)
        .collection('camping')
        .snapshots();
    final hikingStream = FirebaseFirestore.instance
        .collection('gearStores')
        .doc(widget.userEmail)
        .collection('hiking')
        .snapshots();

    await for (final campingSnapshot in campingStream) {
      final hikingSnapshot = await hikingStream.first;
      final campingItems = campingSnapshot.docs.map((doc) {
        final data = doc.data();
        data['category'] = 'Camping';
        return data;
      }).toList();
      final hikingItems = hikingSnapshot.docs.map((doc) {
        final data = doc.data();
        data['category'] = 'Hiking';
        return data;
      }).toList();
      yield [...campingItems, ...hikingItems];
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> items) {
    List<Map<String, dynamic>> filtered = items;
    if (_selectedFilter == 'Available') {
      filtered = filtered.where((item) => (item['quantity'] ?? 0) > 0).toList();
    } else if (_selectedFilter == 'Low Stock') {
      filtered = filtered.where((item) => (item['quantity'] ?? 0) > 0 && (item['quantity'] ?? 0) <= 5).toList();
    } else if (_selectedFilter == 'Hiking') {
      filtered = filtered.where((item) => item['category'] == 'Hiking').toList();
    } else if (_selectedFilter == 'Camping') {
      filtered = filtered.where((item) => item['category'] == 'Camping').toList();
    }
    if (_searchText.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = (item['productName'] ?? '').toString().toLowerCase();
        final cat = (item['category'] ?? '').toString().toLowerCase();
        return name.contains(_searchText.toLowerCase()) || cat.contains(_searchText.toLowerCase());
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Gear', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getAllItemsStream(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final filteredItems = _applyFilters(items);

          final totalItems = items.length;
          final availableItems = items.where((item) => (item['quantity'] ?? 0) > 0).length;
          final lowStockItems = items.where((item) => (item['quantity'] ?? 0) > 0 && (item['quantity'] ?? 0) <= 5).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search gear by name or category...',
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
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statCard('$totalItems', 'Total Items', Colors.black87),
                        _statCard('$availableItems', 'Available', Colors.green),
                        _statCard('$lowStockItems', 'Low Stock', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredItems.isEmpty
                    ? const Center(child: Text('No items found.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _gearItemCard(item);
                        },
                      ),
              ),
              // Load More Items (pagination placeholder)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Load More Items',
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Column(
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
    );
  }

  Widget _gearItemCard(Map<String, dynamic> item) {
    final quantity = item['quantity'] ?? 0;
    String stockText;
    Color stockColor;
    if (quantity == 0) {
      stockText = 'Out of stock';
      stockColor = Colors.red;
    } else if (quantity <= 5) {
      stockText = '$quantity in stock';
      stockColor = Colors.orange;
    } else {
      stockText = '$quantity in stock';
      stockColor = Colors.green;
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item['mainImage'] != null
                  ? Image.network(
                      item['mainImage'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 32, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['productName'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['category'] ?? '',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Rs. ${item['dailyRate'] ?? item['monthlyRate'] ?? item['weeklyRate'] ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: stockColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stockText,
                      style: TextStyle(color: stockColor, fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                // Edit item logic
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Delete item logic
              },
            ),
          ],
        ),
      ),
    );
  }
}