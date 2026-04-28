import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {

  // 1. Get coordinates from city name
  Future<Map<String, double>?> getCoordinates(String city) async {
    final url =
        'https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // print("data in getCordinates: $data");

      if (data["results"]) {
        return {
          "latitude": data["results"][0]["latitude"],
          "longitude": data["results"][0]["longitude"],
        };
      }
    }

    return null;
  }

  // 2. Get weather using lat/lon
  Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final currentWeather = data["current_weather"];
      print("data in getWeather: $currentWeather");
      return currentWeather;
    }

    return null;
  }

  // 3. MAIN FUNCTION (what UI will call)
  // Future<List<String>> fetchWeather(String city) async {
  //   print("Fetching weather for city: $city");
  //   final coords = await getCoordinates(city);

  //   if (coords == null) return null;

  //   final weather = await getWeather(
    
  //     coords["latitude"]!,
  //     coords["longitude"]!,
  //   );

  //   return weather;
  // }
}
Future<List<Map<String, String>>> fetchSuggestions(String query) async {
  print("Fetching suggestions for query: $query");

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

    print("suggestions: $suggestions");
    return suggestions;
  } catch (e) {
    print("Error fetching suggestions: $e");
    return [];
  }
}