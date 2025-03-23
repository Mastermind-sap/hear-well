import 'package:echo_aid/features/features.dart';
import 'package:flutter/material.dart';

class Application extends StatefulWidget {
  const Application({super.key});

  @override
  State<Application> createState() => _ApplicationState();
}

List<Widget> _screens = [
  HomeScreen(),
  SettingScreen(),
  ProfileScreen(),
];

class _ApplicationState extends State<Application> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), 
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), 
            label: 'Settings'
            
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), 
            label: 'Profile'
          )
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
        },
      )
    );
  }
}