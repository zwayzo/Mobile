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

// ─── Color palette ───────────────────────────────────────────────────────────
const Color kTextPrimary   = Color(0xFFD6E8F5); // pale sky blue
const Color kTextSecondary = Color(0xFF8AB4D4); // steel blue
const Color kTextMuted     = Color(0xFFAACBE0); // mid tone

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

  // ─── Shared location header ─────────────────────────────────────────────────
  Widget _buildLocationHeader() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: scale(context, isLandscape ? 6 : 12)),
      child: Text(
        "$_locationName, $_region, $_country",
        style: TextStyle(
          // ✅ Smaller font in landscape so it doesn't dominate the screen
          fontSize: scale(context, isLandscape ? 14 : 18),
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  // ─── Now Tab ────────────────────────────────────────────────────────────────
  Widget buildNowTab() {
    if (isLoadingWeather) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return _buildPlaceholder(_errorMessage!, isError: true);
    if (_currentWeather == null || _currentWeather!["current_weather"] == null) {
      return _buildPlaceholder("Search for a city to see the weather");
    }

    final current = _currentWeather!["current_weather"];
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final header = _buildLocationHeader();
    final description = Text(
      getWeatherDescription(current["weathercode"]),
      style: TextStyle(fontSize: scale(context, isLandscape ? 16 : 22), color: kTextSecondary),
    );
    final temp = Text(
      "${current["temperature"]} °C",
      style: TextStyle(
        fontSize: scale(context, isLandscape ? 40 : 64),
        fontWeight: FontWeight.bold,
        color: kTextPrimary,
      ),
    );
    final wind = Text(
      "💨 Wind: ${current["windspeed"]} km/h",
      style: TextStyle(fontSize: scale(context, isLandscape ? 13 : 16), color: kTextMuted),
    );

    if (isLandscape) {
      return Row(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [header, description],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(fit: BoxFit.scaleDown, child: temp),
                    SizedBox(height: scale(context, 4)),
                    wind,
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            header,
            description,
            SizedBox(height: scale(context, 8)),
            temp,
            SizedBox(height: scale(context, 8)),
            wind,
          ],
        ),
      ),
    );
  }

  // ─── Today Tab ──────────────────────────────────────────────────────────────
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

    // ✅ Filter only today's hours so the list never has ghost empty rows
    final String today = DateTime.now().toIso8601String().split("T")[0];
    final List<int> indices = [];
    for (int i = 0; i < times.length; i++) {
      if (times[i].toString().startsWith(today)) indices.add(i);
    }
    // Fallback if API date format differs
    final List<int> safeIndices = indices.isNotEmpty
        ? indices
        : List.generate(times.length.clamp(0, 24), (i) => i);

    return Column(
      children: [
        _buildLocationHeader(),
        Expanded(
          child: ListView.builder(
            // ✅ Tight bottom padding — just clears the nav bar, nothing extra
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + scale(context, 56),
            ),
            itemCount: safeIndices.length,
            itemBuilder: (context, i) {
              final idx = safeIndices[i];
              final time = times[idx].toString().split("T")[1];
              // ✅ Custom Row instead of ListTile — no fixed-width leading
              //    that overflows in landscape
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: scale(context, 16),
                  vertical: scale(context, 5),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: scale(context, 50),
                      child: Text(
                        time,
                        style: TextStyle(color: kTextMuted, fontSize: scale(context, 13)),
                      ),
                    ),
                    SizedBox(width: scale(context, 8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${temps[idx]} °C",
                            style: TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: scale(context, 14),
                            ),
                          ),
                          Text(
                            getWeatherDescription(codes[idx]),
                            style: TextStyle(color: kTextSecondary, fontSize: scale(context, 12)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "💨 ${winds[idx]} km/h",
                      style: TextStyle(color: kTextMuted, fontSize: scale(context, 13)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Weekly Tab ─────────────────────────────────────────────────────────────
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
        // ✅ Header sits naturally below AppBar — no hardcoded top padding
        _buildLocationHeader(),
        Expanded(
          child: ListView.builder(
            // ✅ Bottom padding so last card clears the bottom nav bar
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + scale(context, 70),
            ),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = _getDayName(DateTime.parse(dates[index]));
              return Card(
                color: Colors.white.withOpacity(0.08),
                margin: EdgeInsets.symmetric(
                  horizontal: scale(context, 12),
                  vertical: scale(context, 4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(scale(context, 10)),
                ),
                child: ListTile(
                  leading: Text(
                    date,
                    style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600),
                  ),
                  title: Text(
                    getWeatherDescription(codes[index]),
                    style: TextStyle(color: kTextSecondary),
                  ),
                  subtitle: Text(
                    "Min: ${minTemps[index]}°C | Max: ${maxTemps[index]}°C",
                    style: TextStyle(color: kTextMuted),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // AppBar height + status bar — used to push page content below the AppBar
    final double topOffset =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextField(
          controller: _cityController,
          onChanged: getSuggestions,
          onSubmitted: (value) {
            getData(value);
            setState(() => suggestions.clear());
          },
          // ✅ Input text and cursor are white
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: "Search city...",
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, color: Colors.white),
            onPressed: getLocation,
          ),
        ],
      ),

      body: Stack(
        children: [
          // ── Background image ──────────────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              "assets/images/background2.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // ── Dark overlay ──────────────────────────────────────────────────
          Container(color: Colors.black.withOpacity(0.3)),

          // ── Content ───────────────────────────────────────────────────────
          // ✅ SafeArea + top padding ensures content starts below the AppBar
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: kToolbarHeight),
              child: Column(
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
                            leading: const Icon(Icons.location_city, color: Colors.white),
                            title: Text(
                              city["name"] ?? "",
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "${city["region"]}, ${city["country"]}",
                              style: const TextStyle(color: Colors.white70),
                            ),
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
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
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