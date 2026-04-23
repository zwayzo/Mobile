import 'package:flutter/material.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
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
  
  bool _isGeoMode = false;
  String buildString(String tab){
    if (_isGeoMode) {
      return "$tab\nGeolocation";
    } else {
      return "$tab\n$_city";
    }
  }
  String _city = "";
  final PageController _pageController = PageController();
  final TextEditingController _cityController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _cityController.dispose(); 
    super.dispose();
  }

  // Called when tapping the bottom bar
  void _onItemTapped(int index) {
    print("selectedindex: $_selectedIndex");
    setState(() {
      _selectedIndex = index;
    });
    // print("Tapped index: $index");
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _goToLocation() {
    setState(() {
      _isGeoMode = true;
    });
    // _pageController.animateToPage(
    //   3,
    //   duration: const Duration(milliseconds: 400),
    //   curve: Curves.easeInOut,
    // ); // Example: Jump to a specific page (e.g., location page)
  }

  // Called when swiping the PageView
  void _handlePageChange(int index) {
    if (index < 3) { // Ensure we only update for the first 3 pages
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _cityController,
          // textInputAction: TextInputAction.done,
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
              _isGeoMode = false; // Switch back to city mode when a search is submitted
            });
            // Handle search submission
            print('Searching for: $value');
          },
        ),
        actions: [
          IconButton(
            onPressed: () => _goToLocation(),
            icon: const Icon(Icons.location_on, color: Colors.white),
            
          ),
        ],
        backgroundColor: Colors.blueGrey,
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: _handlePageChange,
        children: [
          // Center(
          //   child: Text(
          //     '$_city',
          //     style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          //   ),
          // ),
          Center(child: Text(buildString("Currently"), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
          Center(child: Text(buildString("Today"), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
          Center(child: Text(buildString("Weekly"), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.refresh), 
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Currently',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Weekly',
          ),
        ],
      ),
    );
  }
}