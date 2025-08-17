import 'package:flutter/material.dart';
// Import your weather API helper
import '../helpers/weather_helper.dart'; // Make sure this file exists and contains WeatherHelper

class TripPlannerPage extends StatelessWidget {
  final Map<String, dynamic> location;

  const TripPlannerPage({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    final packingProgress = 12;
    final packingTotal = 20;
    final packingItems = [
      {'name': 'Water bottles', 'checked': true},
      {'name': 'First aid kit', 'checked': false},
      {'name': 'Rain gear', 'checked': true},
    ];
    final itinerary = [
      {'day': 'Day 1', 'activity': 'Morning hike to waterfall', 'active': true},
      {'day': 'Day 2', 'activity': 'Bird watching tour', 'active': false},
      {'day': 'Day 3', 'activity': 'Canopy walk experience', 'active': false},
    ];
    final emergencyContacts = [
      {
        'label': 'Forest Office',
        'phone': '+94 45 567 8901',
        'icon': Icons.phone,
        'color': Colors.red[100],
        'iconColor': Colors.red,
      },
      {
        'label': 'Hospital',
        'phone': '+94 45 234 5678',
        'icon': Icons.local_hospital,
        'color': Colors.blue[100],
        'iconColor': Colors.blue,
      },
      {
        'label': 'Guide',
        'phone': '+94 77 123 4567',
        'icon': Icons.person,
        'color': Colors.green[100],
        'iconColor': Colors.green,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    // Back Button on top
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.green, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location['locationName'] ?? 'Sinharaja Forest',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                              const Text(
                                'Trip Planner',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Green Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.greenAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ready for Adventure?',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Plan your perfect trip to ${location['locationName'] ?? 'Sinharaja Forest Reserve'}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Packing & Weather (responsive)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: isWide ? (constraints.maxWidth / 2) - 18 : constraints.maxWidth - 24,
                          child: _buildPackingCard(packingProgress, packingTotal, packingItems),
                        ),
                        SizedBox(
                          width: isWide ? (constraints.maxWidth / 2) - 18 : constraints.maxWidth - 24,
                          child: WeatherCard(location: location),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Itinerary & Emergency (responsive)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: isWide ? (constraints.maxWidth / 2) - 18 : constraints.maxWidth - 24,
                          child: _buildItineraryCard(itinerary),
                        ),
                        SizedBox(
                          width: isWide ? (constraints.maxWidth / 2) - 18 : constraints.maxWidth - 24,
                          child: _buildEmergencyCard(emergencyContacts),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPackingCard(int progress, int total, List<Map<String, dynamic>> items) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.inventory, color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                'Packing',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Progress',
            style: TextStyle(color: Colors.grey[700], fontSize: 15),
          ),
          Row(
            children: [
              Text(
                '$progress/$total',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: progress / total,
                  color: Colors.green,
                  backgroundColor: Colors.grey[200],
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Row(
                children: [
                  Icon(
                    item['checked'] ? Icons.flag : Icons.check_box_outline_blank,
                    color: item['checked'] ? Colors.blue : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item['name'],
                    style: TextStyle(
                      color: item['checked'] ? Colors.blue : Colors.grey[700],
                      fontSize: 15,
                    ),
                  ),
                ],
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('View All Items'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryCard(List<Map<String, dynamic>> itinerary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.calendar_month, color: Colors.purple, size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                'Itinerary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...itinerary.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: item['active'] ? Colors.green[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.circle,
                    color: item['active'] ? Colors.green : Colors.grey[400],
                    size: 16,
                  ),
                  title: Text(
                    item['day'],
                    style: TextStyle(
                      color: item['active'] ? Colors.green : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    item['activity'],
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Edit Schedule'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(List<Map<String, dynamic>> contacts) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.phone, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                'Emergency',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...contacts.map((contact) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: contact['color'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(contact['icon'], color: contact['iconColor'], size: 22),
                  title: Text(
                    contact['label'],
                    style: TextStyle(
                      color: contact['iconColor'],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    contact['phone'],
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  trailing: Icon(Icons.call, color: contact['iconColor']),
                  onTap: () {
                    // TODO: Implement call functionality
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.map, 'label': 'Map', 'color': Colors.green},
      {'icon': Icons.photo_camera, 'label': 'Photos', 'color': Colors.purple},
      {'icon': Icons.share, 'label': 'Share', 'color': Colors.blue},
      {'icon': Icons.settings, 'label': 'Settings', 'color': Colors.grey[700]},
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions.map((action) {
              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['label'] as String,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// --- Real-time Weather Card Widget ---
class WeatherCard extends StatefulWidget {
  final Map<String, dynamic> location;
  const WeatherCard({super.key, required this.location});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  Map<String, dynamic>? weather;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      // Use location['latitude'] and location['longitude'] if available, else location['locationName']
      weather = await WeatherHelper.getWeatherForLocation(
        latitude: widget.location['latitude'],
        longitude: widget.location['longitude'],
        locationName: widget.location['locationName'],
      );
    } catch (e) {
      error = 'Could not fetch weather';
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.sunny, color: Colors.orange, size: 22),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Weather',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${weather?['temp'] ?? '--'}°C',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      weather?['description'] ?? '',
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Humidity: ${weather?['humidity'] ?? '--'}%',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rain: ${weather?['rain'] ?? '--'}%',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}