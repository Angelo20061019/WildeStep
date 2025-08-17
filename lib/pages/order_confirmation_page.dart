import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gear_page.dart';
import 'landing_page.dart';
import 'gear_home_page.dart';
import 'guide_home_page.dart';
import 'admin_landing_page.dart';

class OrderConfirmationPage extends StatefulWidget {
  final String storeId;
  final String storeEmail;
  final List<Map<String, dynamic>> cartItems;
  final int totalAmount;

  const OrderConfirmationPage({
    super.key,
    required this.storeId,
    required this.storeEmail,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  String? userAddress;

  @override
  void initState() {
    super.initState();
    _finalizeOrder();
  }

  Future<void> _finalizeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final orderRef = FirebaseFirestore.instance
        .collection('gearStores')
        .doc(widget.storeId)
        .collection('orders')
        .doc(user.uid);

    // Get current order doc (if exists)
    final orderSnap = await orderRef.get();
    final orderData = orderSnap.data() as Map<String, dynamic>? ?? {};

    // Ensure 'cart' exists
    if (!orderData.containsKey('cart')) {
      await orderRef.set({'cart': []}, SetOptions(merge: true));
    }

    // Ensure 'createdAt' exists
    if (!orderData.containsKey('createdAt')) {
      await orderRef.set({'createdAt': DateTime.now().toIso8601String()}, SetOptions(merge: true));
    }

    // Ensure 'confirmedOrders' exists and add the new confirmed order
    await orderRef.set({
      'confirmedOrders': FieldValue.arrayUnion([
        {
          'cart': widget.cartItems,
          'total': widget.totalAmount,
          'timestamp': DateTime.now().toIso8601String(),
        }
      ])
    }, SetOptions(merge: true));

    // Get address
    final camperSnap = await FirebaseFirestore.instance.collection('campers').doc(user.uid).get();
    setState(() {
      userAddress = camperSnap.data()?['address'] ?? '';
    });
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rental Terms & Conditions'),
        content: const Text(
          'All rentals are subject to our terms and conditions. Please return the gear in good condition. Late returns may incur additional charges.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => GearPage()),
              (route) => false,
            );
          },
        ),
        title: const Text('Order Confirmation', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [],
      ),
      body: user == null
          ? const Center(child: Text('Please login to continue.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Confirmation Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 4,
                    shadowColor: Colors.green.withOpacity(0.10),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 56),
                          const SizedBox(height: 16),
                          const Text('Rental Confirmed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green)),
                          const SizedBox(height: 10),
                          Text(
                            "You're all set for your adventure!\nHere's your rental confirmation.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700], fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Order Progress
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Rental Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Order placed successfully', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Rental Summary
                  const Text('Rental Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.green)),
                  const SizedBox(height: 10),
                  ...widget.cartItems.map((item) => Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.symmetric(vertical: 7),
                        elevation: 2,
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
                          subtitle: Text('Rs. ${item['price'] ?? 0}/${item['wageType'] ?? 'day'}'),
                          trailing: Text('Rs. ${item['price'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      )),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Rs. ${widget.totalAmount}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Delivery Details
                  const Text('Delivery Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.green)),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  userAddress ?? 'No address found',
                                  style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: const [
                              Icon(Icons.phone, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('+94 77 123 4567', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.email, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(widget.storeEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Track Delivery Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.location_on),
                      label: const Text('Track My Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.remove_red_eye, color: Colors.green),
                          label: const Text('View Rentals', style: TextStyle(color: Colors.green)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.verified_user, color: Colors.green),
                          label: const Text('Add Insurance', style: TextStyle(color: Colors.green)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Rental Terms & Conditions
                  ListTile(
                    tileColor: Colors.green[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    title: const Text('Rental Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.keyboard_arrow_down),
                    onTap: _showTermsDialog,
                  ),
                  const SizedBox(height: 18),

                  // --- Add this button at the bottom ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.home, color: Colors.white),
                      label: const Text(
                        'Back to Home Page',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        // Fetch user type from Firestore
                        final uid = user.uid;
                        String? userType;
                        // Check in each user collection
                        final camperDoc = await FirebaseFirestore.instance.collection('campers').doc(uid).get();
                        final guideDoc = await FirebaseFirestore.instance.collection('guides').doc(uid).get();
                        final gearDoc = await FirebaseFirestore.instance.collection('gearStores').doc(uid).get();
                        final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();

                        if (camperDoc.exists) {
                          userType = 'camper';
                        } else if (guideDoc.exists) {
                          userType = 'guide';
                        } else if (gearDoc.exists) {
                          userType = 'gearStore';
                        } else if (adminDoc.exists) {
                          userType = 'admin';
                        }

                        // Navigate to the correct landing page
                        if (userType == 'camper') {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => LandingPage(userType: 'camper')),
                            (route) => false,
                          );
                        } else if (userType == 'guide') {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => GuideHomePage(userData: {},)),
                            (route) => false,
                          );
                        } else if (userType == 'gearStore') {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => GearHomePage(userData: {},)),
                            (route) => false,
                          );
                        } else if (userType == 'admin') {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => AdminLandingPage(adminData: {},)),
                            (route) => false,
                          );
                        } else {
                          // Default fallback
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => LandingPage(userType: 'camper')),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
    );
  }
}