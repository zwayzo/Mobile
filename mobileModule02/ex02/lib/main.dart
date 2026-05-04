import 'package:flutter/material.dart';
import 'api.dart';
import 'package:geolocator/geolocator.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
String _getDayName(DateTime date) {
  const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  return days[date.weekday - 1];
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  Map<String, dynamic>? _currentWeather;

  String _locationName = "";
  String _region = "";
  String _city = "";
  bool _isGeoMode = false;
  String _country = "";
  double? latitude;
  double? longitude;

  List<Map<String, String>> suggestions = [];
  bool isSearching = false;
  bool isLoadingWeather = false;

  final PageController _pageController = PageController();
  final TextEditingController _cityController = TextEditingController();
  @override
  void initState() {
    super.initState();

    // 👇 THIS is what you were missing
    Future.delayed(Duration.zero, () {
      getLocation(); // ask permission when app starts
    });
  }
  @override
  void dispose() {
    _pageController.dispose();
    _cityController.dispose();
    super.dispose();
  }


    Future<void> getLocation() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    setState(() => isLoadingWeather = true);

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );

    // Get city name from coordinates
    final cityData = await WeatherService().getCityFromCoordinates(
      position.latitude,
      position.longitude,
    );

    // Fetch weather
    final weather = await WeatherService().getWeather(
      position.latitude,
      position.longitude,
    );

    setState(() {
      isLoadingWeather = false;
      if (weather != null) {
        _currentWeather = weather;
        _locationName = cityData?["name"] ?? "";
        _region = cityData?["region"] ?? "";
        _country = cityData?["country"] ?? "";
        _cityController.text = _locationName;
      }
    });

  } catch (e) {
    print("Error: $e");
    setState(() => isLoadingWeather = false);
  }
}

  // ---------------- WEATHER API ----------------

  Future<void> getData(String city) async {
    setState(() => isLoadingWeather = true);

    final coordinates = await WeatherService().getCoordinates(city);
    if (coordinates == null) {
      setState(() => isLoadingWeather = false);
      return;
    }

    final lat = coordinates["latitude"]!;
    final lon = coordinates["longitude"]!;

    final weather = await WeatherService().getWeather(lat, lon);

    setState(() {
      isLoadingWeather = false;
      if (weather != null) {
        _currentWeather = weather;
        _locationName = city;
      }
    });
  }

  // ---------------- SUGGESTIONS ----------------

  Future<void> getSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        suggestions.clear();
        isSearching = false;
      });
      return;
    }

    setState(() => isSearching = true);

    final result = await fetchSuggestions(query);

    setState(() {
      suggestions = result;
      isSearching = false;
    });
  }

  // ---------------- WEATHER DESCRIPTION ----------------

  // Fix: use num instead of int — Open-Meteo returns weathercode as num
  String getWeatherDescription(num code) {
    if (code == 0) return "☀️ Sunny";
    if (code <= 3) return "⛅ Cloudy";
    if (code <= 48) return "🌫️ Foggy";
    if (code <= 67) return "🌧️ Rainy";
    if (code <= 77) return "❄️ Snowy";
    if (code <= 82) return "🌦️ Showers";
    if (code <= 99) return "⛈️ Thunderstorm";
    return "🌡️ Unknown";
  }

  // ---------------- NAVIGATION ----------------

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handlePageChange(int index) {
    setState(() => _selectedIndex = index);
  }

  // ---------------- LOADING / EMPTY STATE ----------------

  Widget _buildPlaceholder(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // ---------------- LOCATION HEADER ----------------

  Widget _buildLocationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        "$_locationName, $_region, $_country",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------- NOW TAB ----------------

  Widget buildNowTab() {
    if (isLoadingWeather) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentWeather == null || _currentWeather!["current_weather"] == null) {
      return _buildPlaceholder("Search for a city to see the weather");
    }

    final current = _currentWeather!["current_weather"];
    final temp = current["temperature"];
    final wind = current["windspeed"];
    final code = current["weathercode"];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLocationHeader(),
          Text(
            getWeatherDescription(code),
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            "$temp °C",
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text("💨 Wind: $wind km/h", style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // ---------------- TODAY TAB ----------------

  Widget buildTodayTab() {
    if (isLoadingWeather) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentWeather == null || _currentWeather!["hourly"] == null) {
      return _buildPlaceholder("Search for a city to see today's forecast");
    }

    final hourly = _currentWeather!["hourly"];
    final List times = hourly["time"];
    final List temps = hourly["temperature_2m"];
    final List winds = hourly["windspeed_10m"];
    final List codes = hourly["weathercode"];

    // Show only the next 24 hours
    final int count = times.length < 24 ? times.length : 24;

    return Column(
      children: [
        _buildLocationHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: count,
            itemBuilder: (context, index) {
              final time = times[index].toString().split("T")[1];
              final temp = temps[index];
              final wind = winds[index];
              final code = codes[index];

              return ListTile(
                leading: SizedBox(
                  width: 55,
                  child: Text(time, style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                title: Text("$temp °C"),
                subtitle: Text(getWeatherDescription(code)),
                trailing: Text("💨 $wind km/h"),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- WEEKLY TAB ----------------

  Widget buildWeeklyTab() {
    if (isLoadingWeather) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentWeather == null ||
        _currentWeather!["daily"] == null ||
        _currentWeather!["daily"]["time"] == null) {
      return _buildPlaceholder("Search for a city to see the weekly forecast");
    }

    final daily = _currentWeather!["daily"];
    final List dates = daily["time"];
    final List maxTemps = daily["temperature_2m_max"];
    final List minTemps = daily["temperature_2m_min"];
    final List codes = daily["weathercode"];

    return Column(
      children: [
        _buildLocationHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = _getDayName(DateTime.parse(dates[index].toString()));

              final min = minTemps[index];
              final max = maxTemps[index];
              final code = codes[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: Text(
                    date,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  title: Text(getWeatherDescription(code)),
                  subtitle: Text("Min: $min°C  |  Max: $max°C"),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _cityController,
          onChanged: getSuggestions,
          onSubmitted: (value) {
            getData(value);
            setState(() => suggestions.clear());
          },
          decoration: const InputDecoration(
            hintText: "Search city...",
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: getLocation,
          )
        ],
      ),

      body: Column(
        children: [
          if (isSearching) const LinearProgressIndicator(),

          if (suggestions.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final city = suggestions[index];

                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(city["name"] ?? ""),
                    subtitle: Text("${city["region"]}, ${city["country"]}"),
                    onTap: () {
                      final selectedCity = city["name"] ?? "";

                      setState(() {
                        _locationName = selectedCity;
                        _region = city["region"] ?? "";
                        _country = city["country"] ?? "";
                        suggestions.clear();
                        _cityController.text = selectedCity;
                      });

                      getData(selectedCity);
                    },
                  );
                },
              ),
            ),

          // Fix: use Expanded + Builder so tabs rebuild when setState is called
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _handlePageChange,
              children: [
                Builder(builder: (_) => buildNowTab()),
                Builder(builder: (_) => buildTodayTab()),
                Builder(builder: (_) => buildWeeklyTab()),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: "Now"),
          BottomNavigationBarItem(icon: Icon(Icons.today), label: "Today"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Week"),
        ],
      ),
    );
  }
}