import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'individual_product_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IndividualGearStorePage extends StatefulWidget {
  final String storeId;
  final String storeName;

  const IndividualGearStorePage({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<IndividualGearStorePage> createState() => _IndividualGearStorePageState();
}

class _IndividualGearStorePageState extends State<IndividualGearStorePage> {
  String searchQuery = '';
  String selectedCategory = 'All';

  final List<String> categories = ['All', 'Camping', 'Hiking'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.storeName,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchAllItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No products added yet.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            List<Map<String, dynamic>> items = snapshot.data!;

            // Filter by category (logic unchanged, but UI for filters removed)
            if (selectedCategory != 'All') {
              items = items.where((item) => item['category'] == selectedCategory).toList();
            }

            // Filter by search
            if (searchQuery.isNotEmpty) {
              items = items.where((item) =>
                  (item['productName'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase())
              ).toList();
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store banner
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [Colors.green.shade400, Colors.green.shade100],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.10),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 18),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.store, color: Colors.green[700], size: 38),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.storeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                        color: Colors.white,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${items.length} products available',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search for gear...',
                              hintStyle: TextStyle(color: Colors.green[300], fontWeight: FontWeight.w500),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search, color: Colors.green[400]),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Items grid
                        items.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 40),
                                  child: Text(
                                    'No products added yet.',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: screenWidth < 600 ? 2 : 3,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: screenWidth < 400 ? 0.58 : 0.68,
                                ),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return _GearItemCard(
                                    storeId: widget.storeId,
                                    category: item['category'],
                                    item: item,
                                    productId: item['docId'],
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Fetch all items from both subcollections and include docId
  Future<List<Map<String, dynamic>>> _fetchAllItems() async {
    final campingSnap = await FirebaseFirestore.instance
        .collection('gearStores')
        .doc(widget.storeId)
        .collection('camping')
        .get();
    final hikingSnap = await FirebaseFirestore.instance
        .collection('gearStores')
        .doc(widget.storeId)
        .collection('hiking')
        .get();

    final campingItems = campingSnap.docs.map((doc) {
      final data = doc.data();
      data['category'] = 'Camping';
      data['docId'] = doc.id;
      if (data['images'] != null && data['images'] is Map && data['images']['mainImage'] is String) {
        data['mainImage'] = data['images']['mainImage'];
      }
      return data;
    }).toList();

    final hikingItems = hikingSnap.docs.map((doc) {
      final data = doc.data();
      data['category'] = 'Hiking';
      data['docId'] = doc.id;
      if (data['images'] != null && data['images'] is Map && data['images']['mainImage'] is String) {
        data['mainImage'] = data['images']['mainImage'];
      }
      return data;
    }).toList();

    return [...campingItems, ...hikingItems];
  }
}

class _GearItemCard extends StatelessWidget {
  final String storeId;
  final String category;
  final Map<String, dynamic> item;
  final String productId;

  const _GearItemCard({
    required this.storeId,
    required this.category,
    required this.item,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? imageUrl;
    if (item['mainImage'] is String) {
      imageUrl = item['mainImage'];
    } else if (item['images'] != null && item['images'] is Map && item['images']['mainImage'] is String) {
      imageUrl = item['images']['mainImage'];
    }

    return Card(
      elevation: 3,
      shadowColor: Colors.green.withOpacity(0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use Flexible for the image to avoid overflow
            Flexible(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.green[50],
                  width: double.infinity,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              color: Colors.green[50],
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.red, size: 40),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(Icons.image, color: Colors.green, size: 40),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category,
              style: TextStyle(
                fontSize: 13,
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              item['productName'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if ((item['name'] ?? '') != (item['productName'] ?? ''))
              Text(
                item['name'] ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                ...List.generate(
                  (item['rating'] ?? 0).floor(),
                  (i) => const Icon(Icons.star, color: Colors.amber, size: 16),
                ),
                if ((item['rating'] ?? 0) - (item['rating'] ?? 0).floor() >= 0.5)
                  const Icon(Icons.star_half, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '(${(item['rating'] ?? 0).toStringAsFixed(1)})',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item['price']?.toString() ?? '',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Button at the bottom, but no Spacer to avoid overflow
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please log in to rent gear.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return; // Prevent navigation if not logged in
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductRentalPage(
                        storeId: storeId,
                        category: category.toLowerCase(),
                        productId: productId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                child: const Text(
                  'Rent Now',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreListPage extends StatelessWidget {
  const StoreListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gear Stores'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchStores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No stores found.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final stores = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            itemCount: stores.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final store = stores[index];
              return Card(
                elevation: 3,
                shadowColor: Colors.green.withOpacity(0.10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                color: isDark ? Colors.grey[850] : Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.green[50],
                    child: Icon(Icons.store, color: Colors.green, size: 28),
                  ),
                  title: Text(
                    store['storeName'] ?? 'Unnamed Store',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  subtitle: Text(
                    store['email'] ?? '',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  trailing: SizedBox(
                    width: 110,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IndividualGearStorePage(
                              storeId: store['id'],
                              storeName: store['storeName'] ?? 'Gear Store',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      child: const Text(
                        'View Store',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchStores() async {
    final snapshot = await FirebaseFirestore.instance.collection('gearStores').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}