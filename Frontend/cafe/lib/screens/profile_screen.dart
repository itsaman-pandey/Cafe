import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafe/constants/api_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> orders = [];
  Map<int, String> productNames = {};
  bool isLoadingOrders = true;
  Map<String, dynamic>? user;
  bool pulse = false;
  Timer? pulseTimer;
  String? userRole; // To store role (barista or client)

  @override
  void initState() {
    super.initState();
    fetchProfileAndOrders();
    _getUserRole();

    pulseTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      setState(() => pulse = !pulse);
    });
  }

  Future<void> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('user_role') ?? 'client';
    });
  }

  @override
  void dispose() {
    pulseTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchProfileAndOrders() async {
    setState(() => isLoadingOrders = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final email = prefs.getString('user_email');

    if (token == null || email == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("You must login first!")));
      setState(() => isLoadingOrders = false);
      return;
    }

    try {
      // Fetch user details
      final userResponse = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/user?email=$email"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (userResponse.statusCode == 200) {
        final u = jsonDecode(userResponse.body);
        setState(() {
          user = {
            "name": u["name"] ?? "User",
            "email": u["email"] ?? email,
            "address": u["address"] ?? "No address",
            "phone": u["phone"] ?? "N/A",
          };
        });
      }

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

      // Fetch orders
      final ordersResponse = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/orders/orders/"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (ordersResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(ordersResponse.body);
        setState(() {
          orders = data.map((order) {
            return {
              "id": order["id"],
              "status": order["status"].toString().toLowerCase(),
              "total_price": order["total_price"],
              "created_at": order["created_at"],
              "items": order["items"],
            };
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Exception: $e")));
    } finally {
      setState(() => isLoadingOrders = false);
    }
  }

  Future<void> editProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final email = user?["email"];
    if (token == null || email == null) return;

    final nameController = TextEditingController(text: user?["name"]);
    final phoneController = TextEditingController(text: user?["phone"]);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await http.put(
                Uri.parse("${ApiConstants.baseUrl}/user/$email"),
                headers: {
                  "Authorization": "Bearer $token",
                  "Content-Type": "application/json",
                },
                body: jsonEncode({
                  "name": nameController.text.trim(),
                  "phone": phoneController.text.trim(),
                }),
              );
              if (response.statusCode == 200) {
                final updatedUser = jsonDecode(response.body);
                setState(() {
                  user = updatedUser;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile updated")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to update: ${response.body}")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget buildProfileCard() {
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.brown.shade300, Colors.brown.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: Text(
                  (user?["name"]?[0] ?? "U").toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?["name"] ?? "Unknown",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.email,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            user?["email"] ?? "No email",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            user?["address"] ?? "No address",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user?["phone"] ?? "N/A",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            onPressed: editProfile,
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>;
    final status = order['status'];
    final isPending = status == 'pending';
    final isCompleted = status == 'completed';
    Color bgColor = isPending
        ? Colors.yellow[50]!
        : isCompleted
        ? Colors.green[50]!
        : Colors.grey[100]!;
    Color badgeColor = isPending
        ? Colors.orange
        : isCompleted
        ? Colors.green
        : Colors.grey;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending && pulse
              ? Colors.orangeAccent
              : badgeColor.withOpacity(0.6),
          width: isPending ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
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
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Total: ₹${order['total_price']}",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          Text(
            "Placed on: ${order['created_at']}",
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            "Items:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
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
    );
  }

  //   @override
  //   Widget build(BuildContext context) {
  //     final pendingOrdersCount = orders
  //         .where((o) => o['status'] == 'pending')
  //         .length;

  //     return Scaffold(
  //       backgroundColor: Colors.grey[100],
  //       appBar: AppBar(
  //         title: const Text("Profile"),
  //         backgroundColor: const Color.fromARGB(255, 187, 129, 109),
  //       ),
  //       body: SingleChildScrollView(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             buildProfileCard(),
  //             const SizedBox(height: 12),
  //             Text(
  //               userRole == 'barista' ? "Pending Orders" : "Your Orders",
  //               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //             ),
  //             const SizedBox(height: 8),
  //             isLoadingOrders
  //                 ? const Center(child: CircularProgressIndicator())
  //                 : userRole == 'barista'
  //                 ? Text(
  //                     "$pendingOrdersCount pending order(s)",
  //                     style: const TextStyle(
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   )
  //                 : orders.isEmpty
  //                 ? const Text("No orders yet")
  //                 : Column(children: orders.map(buildOrderCard).toList()),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  // }
  @override
  Widget build(BuildContext context) {
    final pendingOrders = orders
        .where((o) => o['status'] == 'pending')
        .toList();
    final pendingOrdersCount = pendingOrders.length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color.fromARGB(255, 187, 129, 109),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildProfileCard(),
            const SizedBox(height: 12),

            // Admin view
            if (userRole == 'admin') ...[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: 1.05,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      child: const Text(
                        "Pending Orders",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: pendingOrdersCount.toDouble(),
                      ),
                      duration: const Duration(seconds: 1),
                      builder: (context, value, child) {
                        return Text(
                          "${value.toInt()} pending order(s)",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(seconds: 1),
                      child: Container(
                        width: 120,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]
            // Barista view
            else if (userRole == 'barista') ...[
              const Text(
                "Pending Orders",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "$pendingOrdersCount pending order(s)",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (pendingOrders.isNotEmpty)
                Column(children: pendingOrders.map(buildOrderCard).toList())
              else
                const Text("No pending orders"),
            ]
            // Client view
            else ...[
              const Text(
                "Your Orders",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (orders.isEmpty)
                const Text("No orders yet")
              else
                Column(children: orders.map(buildOrderCard).toList()),
            ],
          ],
        ),
      ),
    );
  }
}
