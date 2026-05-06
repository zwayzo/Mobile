import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {

  // 1. Get coordinates from city name
  Future<Map<String, double>?> getCoordinates(String city) async {
  final url =
      'https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1';

  final response = await http.get(Uri.parse(url));
  print("API response status: ${response.statusCode}");
  print("API response body: ${response.body}");

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    final results = data["results"];

    if (results != null && results is List && results.isNotEmpty) {
      return {
        "latitude": results[0]["latitude"],
        "longitude": results[0]["longitude"],
      };
    }
  }

  return null;
}

  // 2. Get weather using lat/lon
  Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
  final url =
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
      '&current_weather=true'
      '&hourly=temperature_2m,windspeed_10m,weathercode'
      '&daily=temperature_2m_max,temperature_2m_min,weathercode'
      '&timezone=auto';

  final response = await http.get(Uri.parse(url));
  print("Weather API response status: ${response.statusCode}");
  

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data; // ✅ return the full object, not just current_weather
  }

  return null;
}
Future<Map<String, String>?> getCityFromCoordinates(double lat, double lon) async {
  final url =
      'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json';

  final response = await http.get(
    Uri.parse(url),
    headers: {"User-Agent": "weather_app"},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final address = data["address"];

    return {
      "name": (address["city"] ?? address["town"] ?? address["village"] ?? "").toString(),
      "region": (address["state"] ?? "").toString(),
      "country": (address["country"] ?? "").toString(),
    };
  }

  return null;
}


}
Future<List<Map<String, String>>> fetchSuggestions(String query) async {
  // print("Fetching suggestions for query: $query");

  final url =
      'https://geocoding-api.open-meteo.com/v1/search?name=$query&count=5';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      print("API error: ${response.statusCode}");
      return [];
    }

    final data = jsonDecode(response.body);

    final List<Map<String, String>> suggestions = [];

    final results = data["results"];

    if (results is List) {
      for (final result in results) {
        suggestions.add({
          "name": (result["name"] ?? "").toString(),
          "region": (result["admin1"] ?? "").toString(),
          "country": (result["country"] ?? "").toString(),
        });
      }
    }
  
    // print("suggestions: $suggestions");

    return suggestions;
  } catch (e) {
    print("Error fetching suggestions: $e");
    return [];
  }





  
}

