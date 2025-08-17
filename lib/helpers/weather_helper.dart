import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherHelper {
  static Future<Map<String, dynamic>> getWeatherForLocation({
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    // Use coordinates if available, else fallback to location name
    String url;
    const apiKey = '294f11c416c40891f6f0422fc3a80488'; // Replace with your API key

    if (latitude != null && longitude != null) {
      url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&units=metric&appid=$apiKey';
    } else if (locationName != null) {
      url =
          'https://api.openweathermap.org/data/2.5/weather?q=$locationName&units=metric&appid=$apiKey';
    } else {
      throw Exception('No location data provided');
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'temp': data['main']['temp'],
        'description': data['weather'][0]['description'],
        'humidity': data['main']['humidity'],
        'rain': data['rain']?['1h'] ?? 0,
      };
    } else {
      throw Exception('Failed to fetch weather');
    }
  }
}