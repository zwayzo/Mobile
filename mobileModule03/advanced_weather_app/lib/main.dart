import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'api.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
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
  String _country = "";

  String? _errorMessage;

  List<Map<String, String>> suggestions = [];
  bool isSearching = false;
  bool isLoadingWeather = false;

  final PageController _pageController = PageController();
  final TextEditingController _cityController = TextEditingController();

  double scale(BuildContext context, double size) {
    return size * MediaQuery.of(context).size.width / 375;
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => getLocation());
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

      setState(() {
        isLoadingWeather = true;
        _errorMessage = null;
      });

      final position = await Geolocator.getCurrentPosition();

      final cityData = await WeatherService().getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

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
      setState(() => isLoadingWeather = false);
    }
  }

  Future<void> getData(String city) async {
    setState(() {
      isLoadingWeather = true;
      _errorMessage = null;
    });

    try {
      final coordinates = await WeatherService().getCoordinates(city);

      if (coordinates == null) {
        setState(() {
          isLoadingWeather = false;
          _errorMessage = "City \"$city\" not found.";
          _currentWeather = null;
        });
        return;
      }

      final weather = await WeatherService().getWeather(
        coordinates["latitude"]!,
        coordinates["longitude"]!,
      );

      setState(() {
        isLoadingWeather = false;
        if (weather != null) {
          _currentWeather = weather;
          _locationName = city;
        }
      });
    } catch (e) {
      setState(() {
        isLoadingWeather = false;
        _errorMessage = "Error loading data";
        _currentWeather = null;
      });
    }
  }

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

  String getWeatherDescription(num code) {
    if (code == 0) return "☀️ Sunny";
    if (code <= 3) return "⛅ Cloudy";
    if (code <= 48) return "🌫️ Foggy";
    if (code <= 67) return "🌧️ Rainy";
    if (code <= 77) return "❄️ Snowy";
    if (code <= 82) return "🌦️ Showers";
    if (code <= 99) return "⛈️ Thunderstorm";
    return "Unknown";
  }

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

  Widget _buildPlaceholder(String message, {bool isError = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isError ? Icons.location_off : Icons.cloud_outlined,
            size: scale(context, 64),
            color: isError ? Colors.red : Colors.grey,
          ),
          SizedBox(height: scale(context, 12)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isError ? Colors.red : Colors.grey,
              fontSize: scale(context, 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: scale(context, 12)),
      child: Text(
        "$_locationName, $_region, $_country",
        style: TextStyle(
          fontSize: scale(context, 18),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildNowTab() {
    if (isLoadingWeather) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return _buildPlaceholder(_errorMessage!, isError: true);
    if (_currentWeather == null || _currentWeather!["current_weather"] == null) {
      return _buildPlaceholder("Search for a city to see the weather");
    }

    final current = _currentWeather!["current_weather"];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLocationHeader(),
          Text(getWeatherDescription(current["weathercode"]),
              style: TextStyle(fontSize: scale(context, 22))),
          SizedBox(height: scale(context, 8)),
          Text("${current["temperature"]} °C",
              style: TextStyle(fontSize: scale(context, 64), fontWeight: FontWeight.bold)),
          SizedBox(height: scale(context, 8)),
          Text("💨 Wind: ${current["windspeed"]} km/h",
              style: TextStyle(fontSize: scale(context, 16))),
        ],
      ),
    );
  }

  Widget buildTodayTab() {
    if (isLoadingWeather) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return _buildPlaceholder(_errorMessage!, isError: true);
    if (_currentWeather == null || _currentWeather!["hourly"] == null) {
      return _buildPlaceholder("Search for a city to see today's forecast");
    }

    final hourly = _currentWeather!["hourly"];
    final List times = hourly["time"];
    final List temps = hourly["temperature_2m"];
    final List winds = hourly["windspeed_10m"];
    final List codes = hourly["weathercode"];

    final int count = times.length < 24 ? times.length : 24;

    return Column(
      children: [
        _buildLocationHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: count,
            itemBuilder: (context, index) {
              final time = times[index].toString().split("T")[1];
              return ListTile(
                leading: SizedBox(
                  width: scale(context, 55),
                  child: Text(time),
                ),
                title: Text("${temps[index]} °C"),
                subtitle: Text(getWeatherDescription(codes[index])),
                trailing: Text("💨 ${winds[index]} km/h"),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildWeeklyTab() {
    if (isLoadingWeather) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return _buildPlaceholder(_errorMessage!, isError: true);
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
              final date = _getDayName(DateTime.parse(dates[index]));
              return Card(
                margin: EdgeInsets.symmetric(
                    horizontal: scale(context, 12), vertical: scale(context, 4)),
                child: ListTile(
                  leading: Text(date),
                  title: Text(getWeatherDescription(codes[index])),
                  subtitle: Text("Min: ${minTemps[index]}°C | Max: ${maxTemps[index]}°C"),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

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
          ),
        ],
      ),
      body: Column(
        children: [
          if (isSearching) const LinearProgressIndicator(),
          if (suggestions.isNotEmpty)
            SizedBox(
              height: scale(context, 200),
              child: ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final city = suggestions[index];
                  return ListTile(
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