import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_cart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class ProductRentalPage extends StatefulWidget {
  final String storeId;
  final String category; // 'camping' or 'hiking'
  final String productId;

  const ProductRentalPage({
    super.key,
    required this.storeId,
    required this.category,
    required this.productId,
  });

  @override
  State<ProductRentalPage> createState() => _ProductRentalPageState();
}

class _ProductRentalPageState extends State<ProductRentalPage> {
  Map<String, dynamic>? product;
  String wageType = 'daily';
  List<Map<String, dynamic>> reviews = [];
  bool isLoadingReviews = true;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProduct();
    _fetchReviews();
  }

  Future<void> _fetchProduct() async {
    final doc = await FirebaseFirestore.instance
        .collection('gearStores')
        .doc(widget.storeId)
        .collection(widget.category)
        .doc(widget.productId)
        .get();
    if (doc.exists) {
      setState(() {
        product = doc.data();
      });
    }
  }

  Future<void> _fetchReviews() async {
    final doc = await FirebaseFirestore.instance
        .collection('gearStores')
        .doc(widget.storeId)
        .collection(widget.category)
        .doc(widget.productId)
        .get();

    final data = doc.data();
    if (data != null && data['reviews'] != null && data['reviews'] is List) {
      setState(() {
        reviews = List<Map<String, dynamic>>.from(data['reviews']);
        isLoadingReviews = false;
      });
    } else {
      setState(() {
        reviews = [];
        isLoadingReviews = false;
      });
    }
  }

  Future<void> _addReview(String reviewText) async {
    if (reviewText.trim().isEmpty) return;
    final newReview = {
      'text': reviewText,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final docRef = FirebaseFirestore.instance
        .collection('gearStores')
        .doc(widget.storeId)
        .collection(widget.category)
        .doc(widget.productId);

    await docRef.set({
      'reviews': FieldValue.arrayUnion([newReview])
    }, SetOptions(merge: true));

    _reviewController.clear();
    _fetchReviews();
  }

  Future<List<Map<String, dynamic>>> _fetchSuggestions() async {
    final snap = await FirebaseFirestore.instance
        .collection('gearStores')
        .doc(widget.storeId)
        .collection(widget.category)
        .get();

    return snap.docs
        .where((doc) => doc.id != widget.productId)
        .map((doc) {
          final data = doc.data();
          data['docId'] = doc.id;
          if (data['images'] != null && data['images'] is Map && data['images']['mainImage'] is String) {
            data['mainImage'] = data['images']['mainImage'];
          }
          return data;
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    String name = product?['productName'] ?? '-';
    String description = product?['description'] ?? '-';
    String dimensions = product?['dimensions']?.toString() ?? '-';
    String weight = product?['weight']?.toString() ?? '-';
    int dailyRate = product?['dailyRate'] ?? 0;
    int weeklyRate = product?['weeklyRate'] ?? 0;
    int monthlyRate = product?['monthlyRate'] ?? 0;
    int stock = product?['quantity'] ?? 0;
    int maxStock = 100;
    String imageUrl = product?['mainImage'] ?? product?['images']?['mainImage'] ?? '';

    double stockProgress = (stock / maxStock).clamp(0.0, 1.0);

    int selectedWagePrice = wageType == 'daily'
        ? dailyRate
        : wageType == 'weekly'
            ? weeklyRate
            : monthlyRate;

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.green),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with shadow and rounded corners
            if (imageUrl.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.13),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.network(
                    imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 18),

            // Description & Features Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.info_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Product Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[800], fontSize: 15.5, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.line_weight, color: Colors.green, size: 20),
                      const SizedBox(width: 4),
                      Text('Weight: $weight', style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 18),
                      Icon(Icons.straighten, color: Colors.green, size: 20),
                      const SizedBox(width: 4),
                      Text('Dimensions: $dimensions', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Availability & Stock Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    stock > 0 ? Icons.check_circle : Icons.cancel,
                    color: stock > 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stock > 0 ? 'Available' : 'Out of Stock',
                    style: TextStyle(
                      color: stock > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: stockProgress,
                        backgroundColor: Colors.green[100],
                        color: Colors.green,
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$stock/$maxStock', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Wage selection Card
            Container(
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.green.withOpacity(0.08)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Select Rental Type',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ],
                  ),
                  RadioListTile(
                    title: Text('Daily: Rs. $dailyRate'),
                    value: 'daily',
                    groupValue: wageType,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setState(() {
                        wageType = 'daily';
                      });
                    },
                  ),
                  RadioListTile(
                    title: Text('Weekly: Rs. $weeklyRate'),
                    value: 'weekly',
                    groupValue: wageType,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setState(() {
                        wageType = 'weekly';
                      });
                    },
                  ),
                  RadioListTile(
                    title: Text('Monthly: Rs. $monthlyRate'),
                    value: 'monthly',
                    groupValue: wageType,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setState(() {
                        wageType = 'monthly';
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Add to Cart Button Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please log in to add items to your cart.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final cartItem = {
                        'productId': widget.productId,
                        'productName': name,
                        'category': widget.category,
                        'wageType': wageType,
                        'price': selectedWagePrice,
                        'imageUrl': imageUrl,
                        'timestamp': DateTime.now().millisecondsSinceEpoch,
                      };

                      final ordersRef = FirebaseFirestore.instance
                          .collection('gearStores')
                          .doc(widget.storeId)
                          .collection('orders')
                          .doc(userId);

                      await ordersRef.set({
                        'cart': FieldValue.arrayUnion([cartItem])
                      }, SetOptions(merge: true));

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserCartPage(
                            storeId: widget.storeId,
                            storeName: name,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 52),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.shopping_cart_checkout_rounded),
                    label: Text(
                      'Add to Cart - Rs. $selectedWagePrice',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Reviews Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reviews_rounded, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (isLoadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (reviews.isEmpty)
                    const Text('No reviews yet.', style: TextStyle(color: Colors.grey)),
                  ...reviews.map((review) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 0,
                        color: Colors.green[50],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(review['text'] ?? ''),
                          subtitle: review['timestamp'] != null
                              ? Text(
                                  DateTime.fromMillisecondsSinceEpoch(review['timestamp'])
                                      .toString()
                                      .split('.')[0],
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                )
                              : null,
                        ),
                      )),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reviewController,
                    decoration: InputDecoration(
                      hintText: 'Write a review...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.green[50],
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, color: Colors.green),
                        onPressed: () {
                          _addReview(_reviewController.text);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // You may also like Card
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchSuggestions(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container();
                }
                final suggestions = snapshot.data!;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.green.withOpacity(0.08)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.thumb_up_alt_rounded, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          const Text('You may also like', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 130,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: suggestions.map((item) {
                            String suggestionImage = item['mainImage'] ?? '';
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => ProductRentalPage(
                                      storeId: widget.storeId,
                                      category: widget.category,
                                      productId: item['docId'],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 110,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.07),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 70,
                                      width: 110,
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                      ),
                                      child: suggestionImage.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                              child: Image.network(
                                                suggestionImage,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : const Icon(Icons.image, size: 40, color: Colors.green),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Column(
                                        children: [
                                          Text(
                                            item['productName'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Rs. ${item['dailyRate'] ?? ''}/day',
                                            style: const TextStyle(color: Colors.green, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}