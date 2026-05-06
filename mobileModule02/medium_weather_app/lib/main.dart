import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_preview/device_preview.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'Weather App',

      builder: DevicePreview.appBuilder,
      locale: DevicePreview.locale(context),

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

  String _city = "";
  bool _isGeoMode = false;

  double? latitude;
  double? longitude;

  final PageController _pageController = PageController();
  final TextEditingController _cityController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  String buildString(String tab) {
    if (_isGeoMode) {
      if (latitude != null && longitude != null) {
        return "$tab\n$latitude, $longitude";
      } else {
        return "$tab\nGeolocation not available";
      }
    } else {
      return "$tab\n$_city";
    }
  }

  Future<void> getLocation() async {
    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _isGeoMode = true;
          latitude = null;
          longitude = null;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      setState(() {
        _isGeoMode = true;
        latitude = position.latitude;
        longitude = position.longitude;
      });
    } catch (e) {
      setState(() {
        _isGeoMode = true;
        latitude = null;
        longitude = null;
      });
    }
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

  Widget buildTab(String title, double width) {
    final fontSize = width * 0.08;
    final padding = width * 0.05;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Text(
          buildString(title),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: size.height * 0.08,
        backgroundColor: Colors.blueGrey,
        title: TextField(
          controller: _cityController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter city name',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white),
          ),
          onSubmitted: (value) {
            setState(() {
              _city = value;
              _isGeoMode = false;
            });
          },
        ),
        actions: [
          IconButton(
            onPressed: getLocation,
            icon: const Icon(Icons.location_on, color: Colors.white),
          ),
        ],
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return PageView(
            controller: _pageController,
            onPageChanged: _handlePageChange,
            children: [
              buildTab("Currently", width),
              buildTab("Today", width),
              buildTab("Weekly", width),
            ],
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.access_time), label: 'Currently'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Today'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Weekly'),
        ],
      ),
    );
  }
}