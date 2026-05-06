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

String _getDayName(DateTime date) {
  const days = [
    "Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"
  ];
  return days[date.weekday - 1];
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  Map<String, dynamic>? _currentWeather;

  String _locationName = "";
  String _region = "";
  String _country = "";

  List<Map<String, String>> suggestions = [];
  bool isSearching = false;
  bool isLoadingWeather = false;

  final PageController _pageController = PageController();
  final TextEditingController _cityController = TextEditingController();


  double rf(double size) {
    final w = MediaQuery.of(context).size.width;
    if (w < 350) return size * 0.8;
    if (w < 600) return size;
    return size * 1.3;
  }

  EdgeInsets rp() {
    final w = MediaQuery.of(context).size.width;
    if (w < 350) return const EdgeInsets.all(8);
    if (w < 600) return const EdgeInsets.all(16);
    return const EdgeInsets.all(24);
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
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      setState(() => isLoadingWeather = true);

      final position = await Geolocator.getCurrentPosition();

      final weather = await WeatherService().getWeather(
        position.latitude,
        position.longitude,
      );

      setState(() {
        isLoadingWeather = false;
        _currentWeather = weather;
        _locationName = "My Location";
      });

    } catch (e) {
      setState(() => isLoadingWeather = false);
    }
  }


  Future<void> getData(String city) async {
    setState(() => isLoadingWeather = true);

    final coordinates = await WeatherService().getCoordinates(city);
    if (coordinates == null) {
      setState(() => isLoadingWeather = false);
      return;
    }

    final weather = await WeatherService().getWeather(
      coordinates["latitude"]!,
      coordinates["longitude"]!,
    );

    setState(() {
      isLoadingWeather = false;
      _currentWeather = weather;
      _locationName = city;
    });
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
    if (code <= 99) return "⛈️ Storm";
    return "Unknown";
  }


  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
  }

  void _handlePageChange(int index) {
    setState(() => _selectedIndex = index);
  }

  // ---------------- UI HELPERS ----------------

  Widget _placeholder(String text) {
    return Center(
      child: Text(text, style: TextStyle(color: Colors.grey, fontSize: rf(16))),
    );
  }

  Widget _locationHeader() {
    return Padding(
      padding: rp(),
      child: Text(
        "$_locationName",
        style: TextStyle(fontSize: rf(18), fontWeight: FontWeight.bold),
      ),
    );
  }


  Widget buildNowTab() {
    if (isLoadingWeather) return const Center(child: CircularProgressIndicator());

    if (_currentWeather == null || _currentWeather!["current_weather"] == null) {
      return _placeholder("Search for a city");
    }

    final current = _currentWeather!["current_weather"];

    return Center(
      child: Padding(
        padding: rp(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _locationHeader(),
            Text(getWeatherDescription(current["weathercode"]),
                style: TextStyle(fontSize: rf(20))),
            const SizedBox(height: 10),
            Text("${current["temperature"]}°C",
                style: TextStyle(fontSize: rf(60), fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("💨 ${current["windspeed"]} km/h",
                style: TextStyle(fontSize: rf(16))),
          ],
        ),
      ),
    );
  }


  Widget buildTodayTab() {
    if (isLoadingWeather) return const Center(child: CircularProgressIndicator());

    if (_currentWeather == null || _currentWeather!["hourly"] == null) {
      return _placeholder("No data");
    }

    final hourly = _currentWeather!["hourly"];

    final times = hourly["time"];
    final temps = hourly["temperature_2m"];
    final winds = hourly["windspeed_10m"];
    final codes = hourly["weathercode"];

    return Column(
      children: [
        _locationHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: 12,
            itemBuilder: (_, i) {
              final time = times[i].split("T")[1];

              return ListTile(
                title: Text(time),
                subtitle: Text(getWeatherDescription(codes[i])),
                trailing: Text("${temps[i]}°C | ${winds[i]}km/h"),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- WEEK ----------------

  Widget buildWeeklyTab() {
    if (isLoadingWeather) return const Center(child: CircularProgressIndicator());

    if (_currentWeather == null || _currentWeather!["daily"] == null) {
      return _placeholder("No weekly data");
    }

    final daily = _currentWeather!["daily"];

    return Column(
      children: [
        _locationHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: daily["time"].length,
            itemBuilder: (_, i) {
              final day = _getDayName(DateTime.parse(daily["time"][i]));

              return Card(
                child: ListTile(
                  title: Text(day),
                  subtitle: Text(
                    "${daily["temperature_2m_min"][i]}°C - ${daily["temperature_2m_max"][i]}°C",
                  ),
                  trailing: Text(
                    getWeatherDescription(daily["weathercode"][i]),
                  ),
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
          onSubmitted: (v) {
            getData(v);
            setState(() => suggestions.clear());
          },
          decoration: const InputDecoration(
            hintText: "Search city...",
            border: InputBorder.none,
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
                itemBuilder: (_, i) {
                  final c = suggestions[i];
                  return ListTile(
                    title: Text(c["name"] ?? ""),
                    subtitle: Text("${c["region"]}, ${c["country"]}"),
                    onTap: () {
                      final name = c["name"]!;
                      setState(() {
                        _locationName = name;
                        _cityController.text = name;
                        suggestions.clear();
                      });
                      getData(name);
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