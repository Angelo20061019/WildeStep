import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_page.dart';

class UserCartPage extends StatelessWidget {
  final String storeId;
  final String storeName;

  const UserCartPage({super.key, required this.storeId, required this.storeName});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: const [
            Text('Your Rental Cart', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            Text('Review your gear before you confirm', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Please login to view your cart.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('gearStores')
                  .doc(storeId)
                  .collection('orders')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Your cart is empty.'));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final cartItems = (data['cart'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                if (cartItems.isEmpty) {
                  return const Center(child: Text('Your cart is empty.'));
                }

                int totalGearPrice = 0;
                for (var item in cartItems) {
                  totalGearPrice += ((item['price'] ?? 0) as int);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: Colors.green[100],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_cart, color: Colors.green, size: 28),
                              const SizedBox(width: 10),
                              Text(
                                '${cartItems.length} items',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                              ),
                              const Spacer(),
                              Text(
                                'Rs. $totalGearPrice',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...cartItems.map((item) {
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          shadowColor: Colors.green.withOpacity(0.08),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty
                                      ? Image.network(item['imageUrl'], width: 64, height: 64, fit: BoxFit.cover)
                                      : Container(
                                          width: 64,
                                          height: 64,
                                          color: Colors.green[50],
                                          child: const Icon(Icons.image, color: Colors.green),
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.attach_money, color: Colors.green[700], size: 16),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Rs. ${item['price'] ?? 0}',
                                            style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                          const SizedBox(width: 10),
                                          Icon(Icons.calendar_today, color: Colors.blue[700], size: 15),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${item['wageType'] ?? 'daily'}',
                                            style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    Text(
                                      'Rs. ${item['price'] ?? 0}',
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user != null) {
                                          final docRef = FirebaseFirestore.instance
                                              .collection('gearStores')
                                              .doc(storeId)
                                              .collection('orders')
                                              .doc(user.uid);

                                          // Remove the item from the cart array
                                          await docRef.update({
                                            'cart': FieldValue.arrayRemove([item])
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.07),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('Rs. $totalGearPrice', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please log in to proceed to checkout.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CheckoutPage(storeId: storeId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                          label: const Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                );
              },
            ),
    );
  }
}