import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'api.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  List<Map<String, String>> suggestions = [];
  bool isSearching = false;

  String _city = "";
  bool _isGeoMode = false;

  double? latitude;
  double? longitude;

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

  // ================= GEOLOCATION =================

  Future<void> getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isGeoMode = true;
          latitude = null;
          longitude = null;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        _isGeoMode = true;
        latitude = position.latitude;
        longitude = position.longitude;
      });

      print("Location: $latitude, $longitude");
    } catch (e) {
      print("Error: $e");

      setState(() {
        _isGeoMode = true;
        latitude = null;
        longitude = null;
      });
    }
  }

  // ================= SUGGESTIONS =================

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
      suggestions = result ?? [];
      isSearching = false;
    });
  }

  // ================= UI =================

  String buildString(String tab) {
    if (_isGeoMode && latitude != null && longitude != null) {
      return "$tab\n$latitude, $longitude";
    }
    return "$tab\n$_city";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _cityController,
          onChanged: getSuggestions,
          onSubmitted: (value) {
            setState(() {
              _city = value;
              _isGeoMode = false;
              suggestions.clear();
            });
          },
          decoration: const InputDecoration(
            hintText: "Enter city",
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
          if (isSearching)
            const LinearProgressIndicator(),

          if (suggestions.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final city = suggestions[index];

                  return ListTile(
                    title: Text(city["name"] ?? ""),
                    subtitle: Text(
                      "${city["region"] ?? ""}, ${city["country"] ?? ""}",
                    ),
                    onTap: () {
                      setState(() {
                        _city = city["name"] ?? "";
                        _cityController.text = _city;
                        suggestions.clear();
                      });
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
                Center(child: Text(buildString("Currently"), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
                Center(child: Text(buildString("Today") , style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
                Center(child: Text(buildString("Weekly"), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
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