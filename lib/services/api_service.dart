import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access host localhost
  // Use your machine's IP address for physical device
  // static const String baseUrl = 'http://10.0.2.2:5000';
  static const String baseUrl = 'https://difmo-crm-backend.onrender.com';

  static void _logRequest(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    print('\n✨ [API REQUEST] ----------------------------------');
    print('METHOD: $method');
    print('URL: $uri');
    if (headers != null) print('HEADERS: $headers');
    if (body != null) print('BODY: $body');
    print('----------------------------------------------------\n');
  }

  static void _logResponse(String method, Uri uri, http.Response response) {
    print('\n📥 [API RESPONSE] ---------------------------------');
    print('METHOD: $method');
    print('URL: $uri');
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');
    print('----------------------------------------------------\n');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final body = jsonEncode({'email': email, 'password': password});

    _logRequest(
      'POST',
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      _logResponse('POST', url, response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final data =
            responseData['data'] ??
            responseData; // Handle both wrapped and unwrapped

        // Save token and user data
        final prefs = await SharedPreferences.getInstance();
        if (data['access_token'] != null) {
          await prefs.setString('token', data['access_token']);
        }
        if (data['user'] != null) {
          await prefs.setString('user', jsonEncode(data['user']));
        }
        return data; // Return the inner data object which contains user info
      } else {
        String errorMessage = 'Login failed';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else {
            errorMessage = response.body;
          }
        } catch (_) {
          errorMessage = response.body;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ [API ERROR] login: $e');
      // Rethrow cleanly if it's already an exception we created
      if (e.toString().startsWith('Exception: ')) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
      throw Exception('Login error: $e');
    }
  }

  static Future<Map<String, dynamic>> checkIn(
    String employeeId,
    double latitude,
    double longitude,
    String location,
    String notes,
  ) async {
    final url = Uri.parse('$baseUrl/attendance/check-in');
    final headers = await _getHeaders();
    final body = jsonEncode({
      'employeeId': employeeId,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'notes': notes,
    });

    _logRequest('POST', url, headers: headers, body: body);

    try {
      final response = await http.post(url, headers: headers, body: body);

      _logResponse('POST', url, response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Check-in failed: ${response.body}');
      }
    } catch (e) {
      print('❌ [API ERROR] checkIn: $e');
      throw Exception('Check-in error: $e');
    }
  }

  static Future<Map<String, dynamic>> checkOut(
    String attendanceId,
    double latitude,
    double longitude,
    String notes,
  ) async {
    final url = Uri.parse('$baseUrl/attendance/check-out');
    final headers = await _getHeaders();
    final body = jsonEncode({
      'attendanceId': attendanceId,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
    });

    _logRequest('POST', url, headers: headers, body: body);

    try {
      final response = await http.post(url, headers: headers, body: body);

      _logResponse('POST', url, response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Check-out failed: ${response.body}');
      }
    } catch (e) {
      print('❌ [API ERROR] checkOut: $e');
      throw Exception('Check-out error: $e');
    }
  }

  static Future<Map<String, dynamic>?> getTodayAttendance(
    String employeeId,
  ) async {
    final url = Uri.parse('$baseUrl/attendance/today/$employeeId');
    final headers = await _getHeaders();

    _logRequest('GET', url, headers: headers);

    try {
      final response = await http.get(url, headers: headers);

      _logResponse('GET', url, response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // Assuming response structure { data: ... }
      } else {
        return null;
      }
    } catch (e) {
      print('❌ [API ERROR] getTodayAttendance: $e');
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

    _logRequest('GET', url, headers: headers);

    try {
      final response = await http.get(url, headers: headers);

      _logResponse('GET', url, response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        // Handle if wrapped in data object
        return data['data'] ?? [];
      } else {
        throw Exception('Failed to fetch employees');
      }
    } catch (e) {
      print('❌ [API ERROR] getEmployees: $e');
      throw Exception('Get employees error: $e');
    }
  }
}
