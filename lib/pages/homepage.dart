import 'package:flutter/material.dart';
import 'package:flutter_application_difmo/pages/home_page_locations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_application_difmo/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  bool isPopUpVisible = false;
  String attendanceStatus = "Clock-In"; // Clock-In or Clock-Out
  String? attendanceId;
  String? employeeId;
  bool isLoading = true;

  // User Data
  String userName = "Loading...";
  String userRole = "Employee";
  String userEmail = "";

  // Time Info
  String clockInTime = "--:--";
  String clockOutTime = "--:--";
  String workingHours = "--h --m";
  String currentDate = "";
  String currentTime = "";

  // Activity History
  List<dynamic> activityHistory = [];

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _fetchAttendanceStatus();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      currentDate = DateFormat('EEEE, dd MMMM').format(now);
      currentTime = DateFormat('HH:mm').format(now);
    });
  }

  DateTime? _parseUtcTime(String? dateStr, String? timeStr) {
    if (dateStr == null || timeStr == null) return null;
    try {
      // Ensure date is YYYY-MM-DD
      final datePart = dateStr.contains('T') ? dateStr.split('T')[0] : dateStr;
      // Construct ISO UTC string
      final isoStr = "${datePart}T${timeStr}Z";
      return DateTime.parse(isoStr).toLocal();
    } catch (e) {
      print("Error parsing time: $e");
      return null;
    }
  }

  Future<void> _fetchAttendanceStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      if (userStr != null) {
        final user = jsonDecode(userStr);
        final userId = user['id'];
        
        setState(() {
          userName = "${user['firstName']} ${user['lastName']}";
          userEmail = user['email'];
        });

        // Get employee record
        final employees = await ApiService.getEmployees(userId: userId);
        if (employees.isNotEmpty) {
          final employee = employees[0];
          setState(() {
            employeeId = employee['id'];
            userRole = employee['role'] ?? "Employee";
          });

          // Get today's attendance
          final attendance = await ApiService.getTodayAttendance(employeeId!);
          
          if (attendance != null) {
             String? date = attendance['date'];
             String? checkInStr = attendance['checkInTime'];
             String? checkOutStr = attendance['checkOutTime'];

             DateTime? checkIn = _parseUtcTime(date, checkInStr);
             DateTime? checkOut = _parseUtcTime(date, checkOutStr);

             setState(() {
               if (checkIn != null) {
                 clockInTime = DateFormat('HH:mm').format(checkIn);
               }
               if (checkOut != null) {
                 clockOutTime = DateFormat('HH:mm').format(checkOut);
                 attendanceStatus = "Completed";
                 
                 // Calculate working hours
                 final duration = checkOut.difference(checkIn!);
                 final hours = duration.inHours;
                 final minutes = duration.inMinutes.remainder(60);
                 workingHours = "${hours}h ${minutes}m";

               } else {
                 attendanceStatus = "Clock-Out";
                 attendanceId = attendance['id'];
               }
             });
          } else {
            setState(() {
              attendanceStatus = "Clock-In";
              clockInTime = "--:--";
              clockOutTime = "--:--";
              workingHours = "--h --m";
            });
          }

          // Get Activity History
          final history = await ApiService.getAttendanceHistory(employeeId!);
          setState(() {
            activityHistory = history;
          });
        }
      }
    } catch (e) {
      // debugPrint("Error fetching attendance: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFF914D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundImage: AssetImage(
                              "assets/images/ranjeet.jpg",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                userRole,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Iconsax.notification,
                              color: Colors.white,
                            ),
                            onPressed: () => showSnack("Notification clicked"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Clock Section
                      Center(
                        child: Column(
                          children: [
                            Text(
                              currentTime,
                              style: const TextStyle(
                                fontSize: 38,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currentDate,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 15),
                            GestureDetector(
                              onTap: () => {
                                setState(() {
                                  isPopUpVisible = !isPopUpVisible;
                                }),
                              },
                              child: Container(
                                padding: const EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Iconsax.finger_scan,
                                  size: 40,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              attendanceStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Time Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TimeInfo(title: "Clock-In", time: clockInTime),
                          TimeInfo(title: "Clock-Out", time: clockOutTime),
                          TimeInfo(title: "Working Hrs", time: workingHours),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ActionIcon(
                        icon: Iconsax.calendar_edit,
                        label: "Leave",
                        onTap: () => showSnack("Leave clicked"),
                      ),
                      ActionIcon(
                        icon: Iconsax.repeat,
                        label: "Swap\nSchedule",
                        onTap: () => showSnack("Swap Schedule clicked"),
                      ),
                      ActionIcon(
                        icon: Iconsax.clock,
                        label: "Overtime",
                        onTap: () => showSnack("Overtime clicked"),
                      ),
                      ActionIcon(
                        icon: Iconsax.lock_1,
                        label: "Permissions",
                        onTap: () => showSnack("Permissions clicked"),
                      ),
                      ActionIcon(
                        icon: Iconsax.receipt_2,
                        label: "My Payslip",
                        onTap: () => showSnack("Payslip clicked"),
                      ),
                      ActionIcon(
                        icon: Iconsax.archive,
                        label: "My Archives",
                        onTap: () => showSnack("Archives clicked"),
                      ),
                      ActionIcon(
                        icon: Iconsax.bank,
                        label: "Koperasi",
                        onTap: () => showSnack("Koperasi clicked"),
                      ),
                      ActionIcon(
                        icon: Iconsax.graph,
                        label: "Report",
                        onTap: () => showSnack("Report clicked"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Activity Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Activity",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (activityHistory.isEmpty)
                        const Text("No activity history found.")
                      else
                        ...activityHistory.take(5).map((activity) {
                          final date = activity['date'];
                          final checkIn = _parseUtcTime(date, activity['checkInTime']);
                          final checkOut = _parseUtcTime(date, activity['checkOutTime']);
                          
                          return Column(
                            children: [
                              if (checkIn != null)
                                activityItem(
                                  "Clock-In", 
                                  DateFormat('dd MMMM yyyy').format(checkIn), 
                                  DateFormat('HH:mm').format(checkIn)
                                ),
                              if (checkOut != null)
                                activityItem(
                                  "Clock-Out", 
                                  DateFormat('dd MMMM yyyy').format(checkOut), 
                                  DateFormat('HH:mm').format(checkOut)
                                ),
                            ],
                          );
                        }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          if (isPopUpVisible)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3), // Optional background dim
                alignment: Alignment.center,
                child: LocationPopup(
                  isCheckIn: attendanceStatus == "Clock-In",
                  employeeId: employeeId,
                  attendanceId: attendanceId,
                  onClose: () {
                    setState(() {
                      isPopUpVisible = false;
                    });
                    // Refresh status after popup closes (assuming check-in/out might have happened)
                    _fetchAttendanceStatus();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Reusable Activity Item
  Widget activityItem(String title, String date, String time) {
    return InkWell(
      onTap: () => showSnack("$title tapped"),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE5D0),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Icon(Iconsax.clock, color: Colors.orange),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(date, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const Spacer(),
            Text(
              time,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Time Info Widget
class TimeInfo extends StatelessWidget {
  final String title, time;
  const TimeInfo({super.key, required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(title, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

// Action Icon Widget
class ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const ActionIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.orange, size: 25),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
