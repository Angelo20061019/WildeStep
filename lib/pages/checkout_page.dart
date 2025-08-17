import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_confirmation_page.dart';

class CheckoutPage extends StatefulWidget {
  final String storeId;
  const CheckoutPage({super.key, required this.storeId});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String paymentMethod = 'card';
  bool termsChecked = false;

  Future<String?> _getAddress(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('campers').doc(userId).get();
    return doc.data()?['address'] as String?;
  }

  Future<void> _setAddress(BuildContext context, String userId) async {
    String newAddress = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Address'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter your address'),
          onChanged: (value) => newAddress = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newAddress.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('campers')
                    .doc(userId)
                    .set({'address': newAddress.trim()}, SetOptions(merge: true));
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

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
        title: const Text('Checkout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Please login to continue.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('gearStores')
                  .doc(widget.storeId)
                  .collection('orders')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('No items in your rental cart.'));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final cartItems = (data['cart'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                // Calculate total
                int total = 0;
                for (var item in cartItems) {
                  int price = item['price'] ?? 0;
                  int quantity = item['quantity'] ?? 1;
                  total += price * quantity;
                }
                int deliveryFee = 50;
                double tax = total * 0.18;
                int grandTotal = total + deliveryFee + tax.round();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rental Summary
                      const Text('Rental Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                      const SizedBox(height: 10),
                      ...cartItems.map((item) => Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(vertical: 7),
                        elevation: 3,
                        shadowColor: Colors.green.withOpacity(0.08),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty
                                ? Image.network(item['imageUrl'], width: 54, height: 54, fit: BoxFit.cover)
                                : Container(
                                    width: 54,
                                    height: 54,
                                    color: Colors.green[50],
                                    child: const Icon(Icons.image, color: Colors.green),
                                  ),
                          ),
                          title: Text(item['productName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quantity: ${item['quantity'] ?? 1}'),
                              Text('Type: ${item['wageType'] ?? 'daily'}'),
                              Text('Rs. ${item['price'] ?? 0}'),
                            ],
                          ),
                          trailing: Text('Rs. ${item['price'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      )),
                      const SizedBox(height: 18),

                      // Delivery Information
                      const Text('Delivery Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.green)),
                      const SizedBox(height: 8),
                      FutureBuilder<String?>(
                        future: _getAddress(user.uid),
                        builder: (context, addressSnap) {
                          final address = addressSnap.data;
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.green, size: 20),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          address != null && address.isNotEmpty
                                              ? address
                                              : 'No address added',
                                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _setAddress(context, user.uid),
                                        child: const Text('Edit', style: TextStyle(color: Colors.green)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.local_shipping, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('Home Delivery Selected', style: TextStyle(color: Colors.green)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // Payment Method
                      const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.green)),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              RadioListTile(
                                value: 'card',
                                groupValue: paymentMethod,
                                onChanged: (val) {
                                  setState(() {
                                    paymentMethod = val as String;
                                  });
                                },
                                title: const Text('Credit/Debit Card'),
                                activeColor: Colors.green,
                              ),
                              RadioListTile(
                                value: 'cod',
                                groupValue: paymentMethod,
                                onChanged: (val) {
                                  setState(() {
                                    paymentMethod = val as String;
                                  });
                                },
                                title: const Text('Cash on Delivery'),
                                activeColor: Colors.green,
                              ),
                              if (paymentMethod == 'cod') ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Have the money ready upon delivery',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                              if (paymentMethod == 'card') ...[
                                const SizedBox(height: 8),
                                TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Card Number',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.credit_card, color: Colors.green),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: InputDecoration(
                                          labelText: 'Expiry Date',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        decoration: InputDecoration(
                                          labelText: 'CVV',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: const [
                                    Icon(Icons.lock, color: Colors.grey, size: 18),
                                    SizedBox(width: 4),
                                    Text('Your payment is secured with SSL encryption', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Order Review
                      const Text('Order Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.green)),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              _buildOrderRow('Subtotal', 'Rs. $total'),
                              _buildOrderRow('Delivery Fee', 'Rs. $deliveryFee'),
                              _buildOrderRow('Tax (18%)', 'Rs. ${tax.round()}'),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                  Text('Rs. $grandTotal', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 19)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Terms and Place Order
                      Row(
                        children: [
                          Checkbox(
                            value: termsChecked,
                            onChanged: (val) {
                              setState(() {
                                termsChecked = val ?? false;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                children: [
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: const TextStyle(color: Colors.green, decoration: TextDecoration.underline),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(color: Colors.green, decoration: TextDecoration.underline),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: termsChecked
                              ? () async {
                                  // Fetch user address
                                  final address = await _getAddress(user.uid);
                                  if (address == null || address.trim().isEmpty) {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please add your delivery address before checking out.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  // Fetch store email from Firestore
                                  final storeDoc = await FirebaseFirestore.instance
                                      .collection('gearStores')
                                      .doc(widget.storeId)
                                      .get();
                                  final storeEmail = storeDoc.data()?['email'] ?? 'support@gearrental.lk';

                                  // Fetch cart before clearing it
                                  final orderDoc = await FirebaseFirestore.instance
                                      .collection('gearStores')
                                      .doc(widget.storeId)
                                      .collection('orders')
                                      .doc(user.uid)
                                      .get();
                                  final orderData = orderDoc.data() ?? {};
                                  final cartItems = (orderData['cart'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                  final totalAmount = cartItems.fold<int>(0, (sum, item) => sum + ((item['price'] ?? 0) as int));

                                  // Navigate and pass cart and total
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderConfirmationPage(
                                        storeId: widget.storeId,
                                        storeEmail: storeEmail,
                                        cartItems: cartItems,
                                        totalAmount: totalAmount,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                          label: const Text('Complete Rental', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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

  Widget _buildOrderRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        ],
      ),
    );
  }
}