import 'package:flutter/material.dart';

class EmployeeListApp extends StatelessWidget {
  const EmployeeListApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.indigo),
      home: const EmployeePage(),
    );
  }
}

class Employee {
  final String name;
  final String role;
  String status;
  final String imageUrl;

  Employee({
    required this.name,
    required this.role,
    required this.status,
    required this.imageUrl,
  });
}

class EmployeePage extends StatefulWidget {
  const EmployeePage({Key? key}) : super(key: key);

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  late List<Employee> employees;
  late List<Employee> filteredEmployees;
  final List<String> statuses = ["On Work", "Leaves", "Off Day", "Permit"];
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    employees = List.generate(40, (i) {
      final colors = ["On Work", "Leaves", "Off Day", "Permit"];
      return Employee(
        name: "Employee ${i + 1}",
        role: "Software Developer",
        status: colors[i % colors.length],
        imageUrl: "https://i.pravatar.cc/150?img=${(i % 70) + 1}",
      );
    });
    filteredEmployees = employees;
  }

  void _searchEmployee(String query) {
    final results = employees.where((emp) {
      final nameMatch = emp.name.toLowerCase().contains(query.toLowerCase());
      final statusMatch = emp.status.toLowerCase().contains(
        query.toLowerCase(),
      );
      return nameMatch || statusMatch;
    }).toList();

    setState(() {
      filteredEmployees = results;
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "On Work":
        return Colors.green;
      case "Leaves":
        return Colors.amber;
      case "Off Day":
        return Colors.grey;
      case "Permit":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void toggleStatus(Employee emp) {
    final nextIndex =
        (statuses.indexOf(emp.status) + 1) % statuses.length; // cycle statuses
    setState(() {
      emp.status = statuses[nextIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search employee or status...',
                  border: InputBorder.none,
                ),
                onChanged: _searchEmployee,
              )
            : const Text("Employee"),
        centerTitle: true,
        leading: const Icon(Icons.arrow_back_ios_new_rounded),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  searchController.clear();
                  filteredEmployees = employees;
                }
                isSearching = !isSearching;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(child: _buildFilterButton("All Teams")),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterButton("All Status")),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredEmployees.length,
              itemBuilder: (context, index) {
                final emp = filteredEmployees[index];
                return GestureDetector(
                  onTap: () => toggleStatus(emp),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(emp.imageUrl),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emp.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                emp.role,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(emp.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            emp.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        ],
      ),
    );
  }
}
