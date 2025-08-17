import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';

class WeatherAlertPage extends StatefulWidget {
  const WeatherAlertPage({super.key});

  @override
  State<WeatherAlertPage> createState() => _WeatherAlertPageState();
}

class _WeatherAlertPageState extends State<WeatherAlertPage> {
  double? temperature;
  double? windSpeed;
  int? humidity;
  int? visibility;
  String? sunrise;
  String? sunset;
  List<Map<String, dynamic>>? forecast;
  bool locationEnabled = true;
  bool loading = true;
  bool sunTimesAlertOn = false;
  String? locationName; // <-- Add this

  final String apiKey = '294f11c416c40891f6f0422fc3a80488';
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    fetchWeather();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showSunTimesNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sun_times_channel',
      'Sun Times Alerts',
      channelDescription: 'Notification for sunrise and sunset',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('ringtone'), // Add ringtone.mp3 to android/app/src/main/res/raw/
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Sun Times Alert',
      'Sunrise at ${sunrise ?? "--"}, Sunset at ${sunset ?? "--"}',
      platformChannelSpecifics,
    );
  }

  Future<void> fetchWeather() async {
    setState(() {
      loading = true;
    });

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission(); // <-- Request permission here
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          locationEnabled = false;
          temperature = null;
          windSpeed = null;
          humidity = null;
          visibility = null;
          sunrise = null;
          sunset = null;
          forecast = null;
          locationName = null;
          loading = false;
        });
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Get location name using geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      String name = '';
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        name = [
          placemark.locality,
          placemark.administrativeArea,
          placemark.country
        ].where((e) => e != null && (e).isNotEmpty).join(', ');
      }

      final weatherUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$apiKey';
      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$apiKey';

      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (weatherResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        final weatherData = json.decode(weatherResponse.body);
        final forecastData = json.decode(forecastResponse.body);

        setState(() {
          temperature = (weatherData['main']['temp'] as num?)?.toDouble();
          windSpeed = (weatherData['wind']['speed'] as num?)?.toDouble();
          humidity = (weatherData['main']['humidity'] as num?)?.toInt();
          visibility = (weatherData['visibility'] != null)
              ? ((weatherData['visibility'] as num) / 1000).toInt()
              : null;
          sunrise = weatherData['sys']['sunrise'] != null
              ? _formatTime(weatherData['sys']['sunrise'])
              : null;
          sunset = weatherData['sys']['sunset'] != null
              ? _formatTime(weatherData['sys']['sunset'])
              : null;
          locationName = name; // <-- Set location name

          // Get next 3 days from forecast (every 8th item is ~24h apart)
          forecast = (forecastData['list'] as List<dynamic>?)
              ?.where((item) => item['dt_txt'].toString().contains('12:00:00'))
              .take(3)
              .map((item) => {
                    'dt': item['dt'],
                    'main': item['weather'][0]['main'],
                    'desc': item['weather'][0]['description'],
                    'icon': item['weather'][0]['icon'],
                    'temp_max': item['main']['temp_max'],
                    'temp_min': item['main']['temp_min'],
                  })
              .toList();

          loading = false;
          locationEnabled = true;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        locationEnabled = false;
        temperature = null;
        windSpeed = null;
        humidity = null;
        visibility = null;
        sunrise = null;
        sunset = null;
        forecast = null;
        locationName = null; // <-- Reset location name
        loading = false;
      });
    }
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour < 12 ? 'AM' : 'PM'}";
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double tempFontSize = screenWidth < 350 ? 28 : (screenWidth < 400 ? 34 : 44);
    final double iconMaxSize = screenWidth < 350 ? 48 : (screenWidth < 400 ? 64 : 90);

    return Scaffold(
      backgroundColor: Colors.green[50], // Softer background
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Weather & Alerts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchWeather,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Weather Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Responsive sizes based on available width
                        double maxWidth = constraints.maxWidth;
                        double tempFontSize = maxWidth < 320 ? 22 : (maxWidth < 400 ? 28 : 36);
                        double iconSize = maxWidth < 320 ? 36 : (maxWidth < 400 ? 48 : 64);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.thermostat, color: Colors.white, size: 20),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          temperature != null
                                              ? '${temperature!.toStringAsFixed(1)}°C'
                                              : '--',
                                          style: TextStyle(
                                            fontSize: tempFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: const [
                                              Shadow(
                                                color: Colors.black26,
                                                blurRadius: 6,
                                                offset: Offset(1, 2),
                                              ),
                                            ],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Live Temperature',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.white70, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          locationEnabled
                                              ? (locationName ?? 'Getting location...')
                                              : 'Turn on location to get live updates',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 2,
                              child: Center(
                                child: Icon(
                                  Icons.cloud,
                                  size: iconSize,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Weather Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _WeatherStat(
                            icon: Icons.air,
                            label: 'Wind',
                            value: windSpeed != null
                                ? '${windSpeed!.toStringAsFixed(1)} m/s'
                                : '--',
                          ),
                          _WeatherStat(
                            icon: Icons.water_drop,
                            label: 'Humidity',
                            value: humidity != null
                                ? '$humidity%'
                                : '--',
                          ),
                          _WeatherStat(
                            icon: Icons.remove_red_eye,
                            label: 'Visibility',
                            value: visibility != null
                                ? '$visibility km'
                                : '--',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Sun Times Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _SunTimesCard(
                      sunrise: sunrise,
                      sunset: sunset,
                      alertOn: sunTimesAlertOn,
                      onToggle: (val) async {
                        setState(() {
                          sunTimesAlertOn = val;
                        });
                        if (val) {
                          await _showSunTimesNotification();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Forecast Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.calendar_today, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '3-Day Forecast',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (forecast != null)
                              Column(
                                children: forecast!.map((day) => _ForecastRow(
                                      day: DateTime.fromMillisecondsSinceEpoch(day['dt'] * 1000)
                                          .toLocal()
                                          .toString()
                                          .split(' ')[0],
                                      iconWidget: Image.network(
                                        'https://openweathermap.org/img/wn/${day['icon']}@2x.png',
                                        width: 32,
                                        height: 32,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.cloud, color: Colors.blue, size: 22),
                                      ),
                                      desc: day['desc'],
                                      temp:
                                          '${(day['temp_max'] as num).toInt()}° / ${(day['temp_min'] as num).toInt()}°',
                                    )).toList(),
                              ),
                            if (forecast == null)
                              const Center(child: Text('No forecast data available')),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.green[700], size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}

class _SunTimesCard extends StatelessWidget {
  final String? sunrise;
  final String? sunset;
  final bool alertOn;
  final ValueChanged<bool> onToggle;
  const _SunTimesCard({
    this.sunrise,
    this.sunset,
    required this.alertOn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.orange, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Sun Times',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: alertOn,
                  onChanged: onToggle,
                  activeColor: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.wb_sunny, color: Colors.orange, size: 28),
                        const SizedBox(height: 4),
                        const Text('Sunrise', style: TextStyle(fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          sunrise ?? '--',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.nightlight_round, color: Colors.purple, size: 28),
                        const SizedBox(height: 4),
                        const Text('Sunset', style: TextStyle(fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          sunset ?? '--',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.notifications_active, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alert 30 min before sunrise & sunset',
                      style: TextStyle(fontSize: 13, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final String day;
  final Widget iconWidget;
  final String desc;
  final String temp;

  const _ForecastRow({
    required this.day,
    required this.iconWidget,
    required this.desc,
    required this.temp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Day (shortened if needed)
          Flexible(
            flex: 2,
            child: Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 2),
          // Weather icon
          SizedBox(
            width: 22,
            height: 22,
            child: iconWidget,
          ),
          const SizedBox(width: 2),
          // Description
          Expanded(
            flex: 7,
            child: Text(
              desc,
              style: const TextStyle(fontSize: 9.5),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              softWrap: true,
            ),
          ),
          const SizedBox(width: 2),
          // Temperature
          Flexible(
            flex: 3,
            child: Text(
              temp,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}