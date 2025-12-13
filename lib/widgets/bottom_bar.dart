import 'package:flutter/material.dart';
import 'package:flutter_application_difmo/pages/activity.dart';
import 'package:flutter_application_difmo/pages/employee_page.dart';
import 'package:flutter_application_difmo/pages/homepage.dart';
import 'package:flutter_application_difmo/pages/profile.dart';
import 'package:flutter_application_difmo/pages/schedule_page.dart';

class BottomBarWidget extends StatefulWidget {
  const BottomBarWidget({super.key});

  @override
  State<BottomBarWidget> createState() => _BottomBarWidgetState();
}

class _BottomBarWidgetState extends State<BottomBarWidget> {
  int selectedIndex = 0;

  void onNavTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  var screens = [
    DashboardPage(),
    WeeklyScheduleApp(),
    EmployeePage(),
    ActivityPage(),
    ProfilePage(),
  ];

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: onNavTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Iconsax.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.calendar),
            label: "Schedule",
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.profile_2user),
            label: "Employee",
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.activity),
            label: "Activity",
          ),
          BottomNavigationBarItem(icon: Icon(Iconsax.user), label: "Profile"),
        ],
      ),
      body: screens[selectedIndex],
    );
  }
}

class Iconsax {
  static IconData? home;

  static IconData? activity;

  static IconData? profile_2user;

  static IconData? get user => null;

  static IconData? get calendar => null;
}
