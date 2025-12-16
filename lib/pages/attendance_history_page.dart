import 'package:flutter/material.dart';
import 'package:flutter_application_difmo/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

class AttendanceHistoryPage extends StatefulWidget {
  final String employeeId;
  final String userName;

  const AttendanceHistoryPage({
    super.key,
    required this.employeeId,
    required this.userName,
  });

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  bool isLoading = true;
  List<dynamic> attendanceList = [];

  // Filters
  DateTime selectedMonth = DateTime.now();
  String selectedStatus = 'all';

  final List<Map<String, String>> statusOptions = [
    {'value': 'all', 'label': 'All Status'},
    {'value': 'present', 'label': 'Present'},
    {'value': 'absent', 'label': 'Absent'},
    {'value': 'late', 'label': 'Late'},
    {'value': 'half_day', 'label': 'Half Day'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Calculate start and end date for the selected month
      final startDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
      final endDate = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);

      final data = await ApiService.getAttendanceHistory(
        widget.employeeId,
        startDate: startStr,
        endDate: endStr,
        status: selectedStatus,
      );

      setState(() {
        attendanceList = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching history: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode
          .year, // Start with year selection if possible, but standard is fine
      helpText: 'Select Month',
    );

    // Note: Standard date picker picks a day. We'll just use the month/year from it.
    if (picked != null &&
        (picked.month != selectedMonth.month ||
            picked.year != selectedMonth.year)) {
      setState(() {
        selectedMonth = picked;
      });
      _fetchAttendance();
    }
  }

  DateTime? _parseUtcTime(String? dateStr, String? timeStr) {
    if (dateStr == null || timeStr == null) return null;
    try {
      final datePart = dateStr.contains('T') ? dateStr.split('T')[0] : dateStr;
      final isoStr = "${datePart}T$timeStr";
      return DateTime.parse(isoStr);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Attendance History"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                Row(
                  children: [
                    // Month Selector
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectMonth(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMMM yyyy').format(selectedMonth),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Icon(
                                Iconsax.calendar_1,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status Selector
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStatus,
                            isExpanded: true,
                            icon: const Icon(
                              Iconsax.arrow_down_1,
                              size: 18,
                              color: Colors.grey,
                            ),
                            items: statusOptions.map((status) {
                              return DropdownMenuItem(
                                value: status['value'],
                                child: Text(
                                  status['label']!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedStatus = val;
                                });
                                _fetchAttendance();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List Section
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : attendanceList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.calendar_remove,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No attendance records found",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: attendanceList.length,
                    itemBuilder: (context, index) {
                      final item = attendanceList[index];
                      final date = item['date'];
                      final checkIn = _parseUtcTime(date, item['checkInTime']);
                      final checkOut = _parseUtcTime(
                        date,
                        item['checkOutTime'],
                      );
                      final status =
                          item['status'] ?? 'Present'; // Default or from API

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat(
                                    'EEEE, dd MMM',
                                  ).format(DateTime.parse(date)),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status.toString().toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTimeColumn(
                                    "Check In",
                                    checkIn != null
                                        ? DateFormat('hh:mm a').format(checkIn)
                                        : "--:--",
                                    Iconsax.login,
                                    Colors.green,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey.shade200,
                                ),
                                Expanded(
                                  child: _buildTimeColumn(
                                    "Check Out",
                                    checkOut != null
                                        ? DateFormat('hh:mm a').format(checkOut)
                                        : "--:--",
                                    Iconsax.logout,
                                    Colors.orange,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey.shade200,
                                ),
                                Expanded(
                                  child: _buildTimeColumn(
                                    "Hrs",
                                    _calculateHours(checkIn, checkOut),
                                    Iconsax.clock,
                                    Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(
    String label,
    String time,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  String _calculateHours(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || checkOut == null) return "--";
    final duration = checkOut.difference(checkIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return "${hours}h ${minutes}m";
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'half_day':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}
