import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmergencyContactPage extends StatefulWidget {
  const EmergencyContactPage({super.key});

  @override
  State<EmergencyContactPage> createState() => _EmergencyContactPageState();
}

class _EmergencyContactPageState extends State<EmergencyContactPage> {
  List<MapEntry<String, String>> _allSafetyTips = [];
  List<MapEntry<String, String>> _displayedSafetyTips = [];
  Timer? _safetyTipTimer;

  @override
  void initState() {
    super.initState();
    _listenSafetyTips();
  }

  @override
  void dispose() {
    _safetyTipTimer?.cancel();
    super.dispose();
  }

  void _listenSafetyTips() {
    FirebaseFirestore.instance.collection('safety_tips').snapshots().listen((snapshot) {
      final tips = <MapEntry<String, String>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data.forEach((title, message) {
          tips.add(MapEntry(title, message.toString()));
        });
      }
      setState(() {
        _allSafetyTips = tips;
      });
      _pickRandomSafetyTips();
      _startSafetyTipTimer();
    });
  }

  void _startSafetyTipTimer() {
    _safetyTipTimer?.cancel();
    if (_allSafetyTips.length <= 2) {
      setState(() {
        _displayedSafetyTips = List.from(_allSafetyTips);
      });
      return;
    }
    _safetyTipTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _pickRandomSafetyTips();
    });
  }

  void _pickRandomSafetyTips() {
    if (_allSafetyTips.length <= 2) {
      setState(() {
        _displayedSafetyTips = List.from(_allSafetyTips);
      });
      return;
    }
    final random = Random();
    int first = random.nextInt(_allSafetyTips.length);
    int second;
    do {
      second = random.nextInt(_allSafetyTips.length);
    } while (second == first);
    setState(() {
      _displayedSafetyTips = [_allSafetyTips[first], _allSafetyTips[second]];
    });
  }

  Future<void> _makePhoneCall(BuildContext context, String number) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog(context);
      return;
    }
    final uri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        debugPrint('Could not launch $number');
      }
    } catch (e) {
      debugPrint('Error launching $number: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to make a call.')),
      );
    }
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to use this feature.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/signin');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _addUserContactDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog(context);
      return;
    }
    final nameController = TextEditingController();
    final numberController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Your Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(labelText: 'Contact Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final number = numberController.text.trim();
              if (name.isNotEmpty && number.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('user_emergency')
                    .add({
                      'uid': user.uid,
                      'name': name,
                      'number': number,
                    });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Section: Emergency Contacts
          const Text(
            'Emergency Contacts',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Quick access to essential services in case of emergencies',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('emergency_contacts')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text(
                  'No emergency contacts available.',
                  style: TextStyle(color: Color(0xFF757575)),
                );
              }
              final contacts = <Map<String, dynamic>>[];
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data.containsKey('name') && data.containsKey('number')) {
                  contacts.add({
                    'title': data['name'],
                    'number': data['number'].toString(),
                    'subtitle': '',
                    'callColor': '#4CAF50',
                  });
                } else {
                  data.forEach((key, value) {
                    contacts.add({
                      'title': key[0].toUpperCase() + key.substring(1),
                      'number': value.toString(),
                      'subtitle': '',
                      'callColor': '#4CAF50',
                    });
                  });
                }
              }
              return Column(
                children: contacts.map((contact) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _EmergencyContactCard(
                      icon: Icons.phone,
                      title: contact['title'],
                      number: contact['number'],
                      subtitle: contact['subtitle'],
                      callColor: _colorFromHex(contact['callColor']),
                      onCall: () => _makePhoneCall(context, contact['number']),
                      onMap: () {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          _showLoginDialog(context);
                        } else {
                          // Implement map logic here
                        }
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          // Section: User Emergency Contacts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Emergency Contacts',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                  letterSpacing: 0.5,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _addUserContactDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          user == null
              ? const Text(
                  'Login to view and manage your emergency contacts.',
                  style: TextStyle(color: Color(0xFF757575)),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('user_emergency')
                      .where('uid', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        'No personal emergency contacts added.',
                        style: TextStyle(color: Color(0xFF757575)),
                      );
                    }
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF4CAF50).withOpacity(0.15),
                              child: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
                            ),
                            title: Text(
                              data['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),
                            subtitle: Text(
                              data['number'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Color(0xFF212121),
                              ),
                            ),
                            trailing: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => _makePhoneCall(context, data['number']),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
          const SizedBox(height: 24),
          // Safety Tips Section (prettier, only 2, auto-rotating)
          const Text(
            'Safety Tips & Guidelines',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.green,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _allSafetyTips.isEmpty
              ? const Text('No safety tips found.', style: TextStyle(color: Color(0xFF757575)))
              : Column(
                  children: _displayedSafetyTips.map((entry) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 3,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.yellow[700]?.withOpacity(0.15),
                          child: const Icon(Icons.health_and_safety, color: Colors.orange),
                        ),
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        subtitle: Text(
                          entry.value,
                          style: const TextStyle(
                            color: Color(0xFF757575),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String number;
  final String subtitle;
  final Color callColor;
  final VoidCallback onCall;
  final VoidCallback onMap;

  const _EmergencyContactCard({
    required this.icon,
    required this.title,
    required this.number,
    required this.subtitle,
    required this.callColor,
    required this.onCall,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: callColor.withOpacity(0.15),
              radius: 28,
              child: Icon(icon, color: callColor, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    number,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF212121),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF757575)),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: onCall,
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: callColor,
                    side: BorderSide(color: callColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: onMap,
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('Map', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.yellow[700]?.withOpacity(0.15),
          child: Icon(icon, color: Colors.orange[800]),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            color: Color(0xFF757575),
          ),
        ),
      ),
    );
  }
}
