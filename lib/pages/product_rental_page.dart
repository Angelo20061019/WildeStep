import 'package:flutter/material.dart';

class ProductRentalPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductRentalPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.green),
            onPressed: () {},
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rental Period & Price
            Text('Rental Period', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('₹${product['dailyRate'] ?? 0}/day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.calendar_today, color: Colors.green),
              label: Text('Select Rental Dates'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[50],
                foregroundColor: Colors.green,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 16),
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(product['mainImage'] ?? '', height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
            SizedBox(height: 16),
            // Description
            Text('Perfect for Family Adventures', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 4),
            Text(product['description'] ?? ''),
            SizedBox(height: 8),
            // Features
            Row(
              children: [
                Icon(Icons.people, color: Colors.green),
                SizedBox(width: 4),
                Text('Sleeps 4 people comfortably'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.water_drop, color: Colors.green),
                SizedBox(width: 4),
                Text('Waterproof & UV-resistant'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.line_weight, color: Colors.green),
                SizedBox(width: 4),
                Text('Lightweight: ${product['weight'] ?? 'N/A'} packed'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.air, color: Colors.green),
                SizedBox(width: 4),
                Text('Excellent ventilation system'),
              ],
            ),
            SizedBox(height: 16),
            // Price & Availability
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${product['dailyRate'] ?? 0}/day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 4),
                    Text('Available'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 4),
            Text('July 10-15', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Add to Cart - ₹${product['dailyRate'] ?? 0}/day'),
            ),
            SizedBox(height: 4),
            Text('Security deposit: ₹2,000 (refundable)', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            // Rental Terms
            Text('Rental Terms', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Minimum rental: 2 days'),
            Text('Late return fee: ₹500/day'),
            Text('Security deposit: ₹2,000'),
            SizedBox(height: 16),
            // Optional Add-ons
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: Text('Add Insurance'),
                      subtitle: Text('₹150/day - Covers damage & loss'),
                      value: false,
                      onChanged: (val) {},
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // Reviews (dummy)
            Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text('4.5', style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.star, color: Colors.amber, size: 18),
                Text('(50)'),
              ],
            ),
            ListTile(
              leading: CircleAvatar(),
              title: Text('Sarah M.'),
              subtitle: Text('Perfect for our family camping trip! Easy setup and very spacious.'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => Icon(Icons.star, color: i < 5 ? Colors.amber : Colors.grey, size: 16)),
              ),
            ),
            ListTile(
              leading: CircleAvatar(),
              title: Text('Mike R.'),
              subtitle: Text('Great quality tent, stayed dry during heavy rain.'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (i) => Icon(Icons.star, color: i < 4 ? Colors.amber : Colors.grey, size: 16)),
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[50],
                foregroundColor: Colors.green,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Write a Review'),
            ),
            SizedBox(height: 16),
            // You may also like (dummy)
            Text('You may also like', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _SuggestionCard(title: '2-Person Tent', price: '₹1,200/day'),
                  _SuggestionCard(title: 'Sleeping Bag', price: '₹400/day'),
                  _SuggestionCard(title: 'Camping Stove', price: '₹300/day'),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Optional Add-ons
            Text('Optional Add-ons', style: TextStyle(fontWeight: FontWeight.bold)),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Tent Stakes Set'),
                    subtitle: Text('Heavy-duty stakes'),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('₹100 Add'),
                    ),
                  ),
                  ListTile(
                    title: Text('Sleeping Pad'),
                    subtitle: Text('Inflatable comfort pad'),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('₹200 Add'),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Delivery & Pick-up
            Text('Delivery & Pick-up', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Free delivery within 10km'),
            Text('₹50 beyond 10km radius'),
            Text('Delivery: 9 AM - 6 PM'),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green),
                SizedBox(width: 4),
                Text('Sleeping Road, Koramangala, Bangalore'),
                TextButton(
                  onPressed: () {},
                  child: Text('Change', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
            SizedBox(height: 24),
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: Colors.orange,
                child: Icon(Icons.chat),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String title;
  final String price;

  const _SuggestionCard({required this.title, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 100,
            color: Colors.green[50],
            child: Icon(Icons.image, size: 40, color: Colors.green),
          ),
          SizedBox(height: 4),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(price, style: TextStyle(color: Colors.green, fontSize: 12)),
        ],
      ),
    );
  }
}