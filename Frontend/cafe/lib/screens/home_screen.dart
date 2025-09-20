import 'package:cafe/screens/admin_orders_screen.dart';
import 'package:cafe/screens/admin_user_management_screen.dart';
import 'package:cafe/screens/completed_order.dart';
import 'package:cafe/screens/current_order.dart';
import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'admin_screen.dart';
import 'barista_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  final String? userRole; // "client", "admin", "barista"

  const HomeScreen({super.key, this.isLoggedIn = false, this.userRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _initScreens();
  }

  void _initScreens() {
    final role = widget.userRole ?? "guest";

    if (widget.isLoggedIn) {
      switch (role) {
        case "client":
          _screens = const [ProfileScreen(), ProductsScreen(), CartScreen()];
          _navItems = const [
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_cafe),
              label: "Products",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: "Cart",
            ),
          ];
          break;

        case "barista":
          _screens = const [
            ProfileScreen(),
            CurrentOrdersScreen(), // will use pending orders API
            CompletedOrdersScreen(),
          ];
          _navItems = const [
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions),
              label: "Current Orders",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.done_all),
              label: "Completed Orders",
            ),
          ];
          break;

        case "admin":
          _screens = const [
            ProfileScreen(),
            AdminUserManagementScreen(), // NEW: Add user screen
            AdminOrdersScreen(), // NEW: Combined orders + sales
          ];
          _navItems = const [
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_add),
              label: "Add User",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: "Orders & Sales",
            ),
          ];
          break;

        default:
          _screens = [_guestScreen()];
          _navItems = [];
      }
    } else {
      _screens = [_guestScreen()];
      _navItems = [];
    }
  }

  Widget _guestScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.shade200, Colors.brown.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_cafe, size: 80, color: Colors.brown.shade400),
                const SizedBox(height: 16),
                const Text(
                  "Welcome to Our Cafe ",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Please login or sign up to continue",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade400,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  label: const Text("Login", style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade200,
                    foregroundColor: Colors.brown.shade800,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  label: const Text("Sign Up", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return Scaffold(body: _guestScreen());
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: _navItems.isNotEmpty
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.brown,
              unselectedItemColor: Colors.grey,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: _navItems,
            )
          : null,
    );
  }
}
