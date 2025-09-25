import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cafe/constants/api_constants.dart';

class BaristaHelper {
  static const String email = "rahul@gmail.com";
  static const String password = "1234";

  /// Get barista access token
  static Future<String> getBaristaToken() async {
    final url = Uri.parse(ApiConstants.login);
    final body = {
      "grant_type": "password",
      "username": email,
      "password": password,
      "scope": "",
      "client_id": "string",
      "client_secret": "your_secret",
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["access_token"];
    } else {
      throw Exception(
          "Barista login failed: ${response.statusCode} ${response.body}");
    }
  }

  /// Fetch barista orders (current or completed)
  static Future<List<dynamic>> fetchBaristaOrders(String type) async {
    final token = await getBaristaToken();
    final url = "${ApiConstants.baseUrl}/barista/orders/$type";

    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Failed to fetch $type orders: ${response.statusCode} ${response.body}");
    }
  }
}
