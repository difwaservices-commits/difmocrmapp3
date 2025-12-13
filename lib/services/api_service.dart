import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access host localhost
  // Use your machine's IP address for physical device
  // static const String baseUrl = 'http://10.0.2.2:5000'; 
  static const String baseUrl = 'https://difmo-crm-backend.onrender.com';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Save token and user data
        final prefs = await SharedPreferences.getInstance();
        if (data['access_token'] != null) {
           await prefs.setString('token', data['access_token']);
        }
        if (data['user'] != null) {
           await prefs.setString('user', jsonEncode(data['user']));
        }
        return data;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  static Future<Map<String, dynamic>> checkIn(String employeeId, double latitude, double longitude, String location, String notes) async {
    final url = Uri.parse('$baseUrl/attendance/check-in');
    final headers = await _getHeaders();
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'employeeId': employeeId,
          'latitude': latitude,
          'longitude': longitude,
          'location': location,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Check-in failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Check-in error: $e');
    }
  }

  static Future<Map<String, dynamic>> checkOut(String attendanceId, double latitude, double longitude, String notes) async {
    final url = Uri.parse('$baseUrl/attendance/check-out');
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'attendanceId': attendanceId,
          'latitude': latitude,
          'longitude': longitude,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Check-out failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Check-out error: $e');
    }
  }

  static Future<Map<String, dynamic>?> getTodayAttendance(String employeeId) async {
    final url = Uri.parse('$baseUrl/attendance/today/$employeeId');
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // Assuming response structure { data: ... }
      } else {
        return null;
      }
    } catch (e) {
      // debugPrint('Error fetching today attendance: $e');
      return null;
    }
  }
  
  static Future<List<dynamic>> getEmployees({String? userId}) async {
    String queryString = '';
    if (userId != null) {
      queryString = '?userId=$userId';
    }
    final url = Uri.parse('$baseUrl/employees$queryString');
    final headers = await _getHeaders();
    
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        // Handle if wrapped in data object
        return data['data'] ?? [];
      } else {
        throw Exception('Failed to fetch employees');
      }
    } catch (e) {
      throw Exception('Get employees error: $e');
    }
  }
}
