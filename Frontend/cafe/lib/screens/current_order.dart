import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafe/constants/api_constants.dart';

class CurrentOrdersScreen extends StatefulWidget {
  const CurrentOrdersScreen({super.key});

  @override
  State<CurrentOrdersScreen> createState() => _CurrentOrdersScreenState();
}

class _CurrentOrdersScreenState extends State<CurrentOrdersScreen> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCurrentOrders();
  }

  Future<void> fetchCurrentOrders() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("You must login first!")));
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/barista/orders?status=pending"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          orders = data.map((order) {
            return {
              "id": order["id"],
              "user_name": order["user_name"],
              "status": order["status"],
              "total_price": order["total_price"],
              "created_at": order["created_at"],
              "items": order["items"],
            };
          }).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error fetching orders: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Exception: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> completeOrder(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse(
          "${ApiConstants.baseUrl}/barista/orders/$orderId/status?status=completed",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order marked as completed")),
        );
        fetchCurrentOrders(); // Refresh list
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Order not found")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to complete order: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Exception: $e")));
    }
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>;
    final createdAt = DateTime.parse(
      order['created_at'],
    ); // parse string to DateTime
    final formatted = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(createdAt); // remove milliseconds
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order #${order['id']} - ${order['user_name']}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text("Status: ${order['status']}"),
            Text("Total: ₹${order['total_price']}"),
            Text("Placed on: ${formatted}"),
            const SizedBox(height: 6),
            const Text("Items:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...items.map(
              (item) => Text(
                "${item['quantity']} x Product #${item['product_id']} - ₹${item['price']}",
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => completeOrder(order['id']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Mark as Completed"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Current Orders"),
        backgroundColor: Colors.brown,
      ),
      body: Stack(
        children: [
          // Background image effect
          Positioned.fill(
            child: Image.asset("assets/img1.webp", fit: BoxFit.cover),
          ),
          // Dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          // Glassy content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: orders.isEmpty
                        ? const Center(
                            child: Text(
                              "No current orders",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: buildOrderCard(orders[index]),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
