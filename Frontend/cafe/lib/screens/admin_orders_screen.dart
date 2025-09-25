
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafe/constants/api_constants.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool isLoading = true;
  List<dynamic> pendingOrders = [];
  List<dynamic> completedOrders = [];
  double totalSales = 0;
  Map<int, String> productNames = {};

  @override
  void initState() {
    super.initState();
    fetchOrdersAndProducts();
  }

  Future<void> fetchOrdersAndProducts() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token_for_api'); // Barista token
    if (token == null) return;

    try {
      // Fetch products

      final productsResponse = await http.get(
        Uri.parse(ApiConstants.products),
        headers: {"Authorization": "Bearer $token"},
      );
      if (productsResponse.statusCode == 200) {
        final List<dynamic> productsData = jsonDecode(productsResponse.body);
        productNames = {
          for (var p in productsData) p['id'] as int: p['name'] as String,
        };
      }

      final now = DateTime.now();
      List<dynamic> fetchedPending = [];
      List<dynamic> fetchedCompleted = [];

      // Fetch pending orders
      final pendingResponse = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/barista/orders?status=pending"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (pendingResponse.statusCode == 200) {
        fetchedPending = (jsonDecode(pendingResponse.body) as List).where((
          order,
        ) {
          final date =
              DateTime.tryParse(order["created_at"] ?? "") ?? DateTime(2000);
          return date.month == now.month && date.year == now.year;
        }).toList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pending orders failed: ${pendingResponse.body}"),
          ),
        );
      }

      // Fetch completed orders
      final completedResponse = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/barista/orders/completed"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (completedResponse.statusCode == 200) {
        print("\n\n\n\n\n");
        print(completedResponse.body);
        print("\n\n\n\n\n");
        fetchedCompleted = (jsonDecode(completedResponse.body) as List).where((
          order,
        ) {
          final date =
              DateTime.tryParse(order["created_at"] ?? "") ?? DateTime(2000);
          return date.month == now.month && date.year == now.year;
        }).toList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Completed orders failed: ${completedResponse.body}"),
          ),
        );
      }

      setState(() {
        pendingOrders = fetchedPending;
        completedOrders = fetchedCompleted;
        totalSales = [...fetchedPending, ...fetchedCompleted].fold<double>(0, (
          sum,
          order,
        ) {
          final price = order["total_price"];
          double priceValue = 0;
          if (price is num) priceValue = price.toDouble();
          if (price is String) priceValue = double.tryParse(price) ?? 0;
          return sum + priceValue;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildOrderCard(dynamic order, {required bool isPending}) {
    final items = order['items'] as List<dynamic>;
    Color bgColor = isPending ? Colors.yellow[50]! : Colors.green[50]!;
    Color badgeColor = isPending ? Colors.orange : Colors.green;

    return Card(
      color: bgColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order #${order['id']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['status'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Total: ₹${order['total_price']}",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            Text(
              "Placed on: ${order['created_at']}",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "Items:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            ...items.map((item) {
              final pid = item['product_id'] as int;
              final name = productNames[pid] ?? "Product #$pid";
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${item['quantity']} x $name",
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      "₹${item['price']}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _noOrdersCard(String message) {
    return Card(
      color: Colors.grey[200],
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders & Sales"),
        backgroundColor: Colors.brown,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchOrdersAndProducts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Sales
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.brown.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Total Sales (This Month): ₹$totalSales",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pending Orders
                    const Text(
                      "Pending Orders",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    pendingOrders.isEmpty
                        ? _noOrdersCard("No pending orders")
                        : Column(
                            children: pendingOrders
                                .map((o) => _buildOrderCard(o, isPending: true))
                                .toList(),
                          ),
                    const SizedBox(height: 24),

                    // Completed Orders
                    const Text(
                      "Completed Orders",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    completedOrders.isEmpty
                        ? _noOrdersCard("No completed orders")
                        : Column(
                            children: completedOrders
                                .map(
                                  (o) => _buildOrderCard(o, isPending: false),
                                )
                                .toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
