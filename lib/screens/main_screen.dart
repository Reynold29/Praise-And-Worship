import 'package:flutter/material.dart';
import 'package:worshipcompanion/widgets/english_card.dart';
import 'package:worshipcompanion/data/verse_api.dart';

final ThemeData lightTheme = ThemeData(
  primarySwatch: Colors.blue,
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB(255, 167, 217, 255),
    foregroundColor: Colors.black,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(30.0)),
    ),
  ),
);

final ThemeData darkTheme = ThemeData(
  primarySwatch: Colors.blue,
  brightness: Brightness.dark,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF121212),
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF1E1E1E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(30.0)),
    ),
  ),
);

class MainScreen extends StatefulWidget {
  final String username;

  const MainScreen({super.key, required this.username});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool isDarkTheme = false;
  String? verseOfTheDay;

  @override
  void initState() {
    super.initState();
    final verseApi = VerseApi(); // Create an instance of your API class
    verseApi.fetchVerseOfTheDay().then((verse) {
      setState(() {
        verseOfTheDay = verse;
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkTheme ? darkTheme : lightTheme, // Toggle theme based on state
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header Content
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 167, 217, 255),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(14.0),
                    bottomRight: Radius.circular(14.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hey, ${widget.username} 👋🏼',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 1),
                            const Text(
                              'Hope you\'re doing good',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(isDarkTheme ? Icons.dark_mode : Icons.light_mode),
                          onPressed: () {
                            setState(() {
                              isDarkTheme = !isDarkTheme;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search Songs...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Foreground Content (Card effect)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Column(
                  children: [
                    // English Card
                    LanguageCard(
                      imagePath: 'assets/cards/english_image.png',
                      isSelected: true, // You'll need logic to manage selection
                      onTap: () {
                        // Handle card tap
                      },
                    ),
                    // Add more cards or other widgets here if needed
                  ],
                ),
              ),
            ],
          ),
        ),
        // Bottom Navigation Bar
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(10.0),
          child: PhysicalModel(
            color: Colors.transparent,
            elevation: 6.0,
            borderRadius: BorderRadius.circular(35.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35.0),
              child: BottomNavigationBar(
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                backgroundColor: const Color.fromARGB(187, 255, 255, 255),
                selectedItemColor: Colors.blue,
                unselectedItemColor: Colors.grey,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite),
                    label: 'Favorites',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                selectedIconTheme: const IconThemeData(size: 30.0),
                unselectedIconTheme: const IconThemeData(size: 24.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
