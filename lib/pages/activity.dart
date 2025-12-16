import 'package:flutter/material.dart';

class ActivityPage extends StatelessWidget {
  final List<Map<String, dynamic>> activities = [
    {
      "month": "November",
      "records": [
        {
          "type": "Clock-In",
          "time": "07:30",
          "date": "01 November 2023",
          "status": "On-time",
        },
        {
          "type": "Clock-Out",
          "time": "16:30",
          "date": "01 November 2023",
          "status": "On-time",
        },
      ],
    },
    {
      "month": "September",
      "records": [
        {
          "type": "Clock-In",
          "time": "07:30",
          "date": "31 September 2023",
          "status": "On-time",
        },
        {
          "type": "Clock-Out",
          "time": "16:30",
          "date": "31 September 2023",
          "status": "On-time",
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        title: const Text(
          'Your Activity',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilterButton(label: 'Month', onTap: () {}),
                FilterButton(label: 'Sort by', onTap: () {}),
              ],
            ),
            const SizedBox(height: 16),

            // Activity list
            for (var monthData in activities) ...[
              Text(
                monthData["month"],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              for (var record in monthData["records"])
                ActivityCard(
                  type: record["type"],
                  time: record["time"],
                  date: record["date"],
                  status: record["status"],
                ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const FilterButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  final String type;
  final String time;
  final String date;
  final String status;

  const ActivityCard({
    required this.type,
    required this.time,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClockIn = type.toLowerCase().contains("in");
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isClockIn
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.pink[50],
                child: Icon(
                  isClockIn ? Icons.login : Icons.logout,
                  color: isClockIn
                      ? Theme.of(context).primaryColor
                      : Colors.pink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    date,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                status,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
