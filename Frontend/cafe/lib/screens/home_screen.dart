import 'dart:ui'; // For BackdropFilter
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
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  final String? userRole; // "client", "admin", "barista"

  const HomeScreen({super.key, this.isLoggedIn = false, this.userRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navItems;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.1), // start slightly lower
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    _initScreens();
    _fadeController.forward(); // Start animation after everything is ready
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
            CurrentOrdersScreen(),
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
            AdminUserManagementScreen(),
            AdminOrdersScreen(),
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
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            "assets/img1.webp", // add this to assets
            fit: BoxFit.cover,
          ),
        ),

        // Dark overlay for better contrast
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.4))),

        // Animated guest dialog (fade + slide)
        Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/gif1.gif", // add your cafe logo
                          height: 80,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Welcome to Our Cafe",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Please login or sign up to continue",
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              214,
                              221,
                              191,
                              182,
                            ),
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
                          label: const Text(
                            "Login",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.person_add),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white70),
                            foregroundColor: Colors.white,
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
                          label: const Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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









































// import 'package:cafe/screens/admin_orders_screen.dart';
// import 'package:cafe/screens/admin_user_management_screen.dart';
// import 'package:cafe/screens/completed_order.dart';
// import 'package:cafe/screens/current_order.dart';
// import 'package:flutter/material.dart';
// import 'signup_screen.dart';
// import 'login_screen.dart';
// import 'profile_screen.dart';
// import 'products_screen.dart';
// import 'cart_screen.dart';
// import 'admin_screen.dart';
// import 'barista_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class HomeScreen extends StatefulWidget {
//   final bool isLoggedIn;
//   final String? userRole; // "client", "admin", "barista"

//   const HomeScreen({super.key, this.isLoggedIn = false, this.userRole});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;
//   late List<Widget> _screens;
//   late List<BottomNavigationBarItem> _navItems;

//   @override
//   void initState() {
//     super.initState();
//     _initScreens();
//   }

//   void _initScreens() {
//     final role = widget.userRole ?? "guest";

//     if (widget.isLoggedIn) {
//       switch (role) {
//         case "client":
//           _screens = const [ProfileScreen(), ProductsScreen(), CartScreen()];
//           _navItems = const [
//             BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.local_cafe),
//               label: "Products",
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.shopping_cart),
//               label: "Cart",
//             ),
//           ];
//           break;

//         case "barista":
//           _screens = const [
//             ProfileScreen(),
//             CurrentOrdersScreen(), // will use pending orders API
//             CompletedOrdersScreen(),
//           ];
//           _navItems = const [
//             BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.pending_actions),
//               label: "Current Orders",
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.done_all),
//               label: "Completed Orders",
//             ),
//           ];
//           break;

//         case "admin":
//           _screens = const [
//             ProfileScreen(),
//             AdminUserManagementScreen(), // NEW: Add user screen
//             AdminOrdersScreen(), // NEW: Combined orders + sales
//           ];
//           _navItems = const [
//             BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.person_add),
//               label: "Add User",
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.list_alt),
//               label: "Orders & Sales",
//             ),
//           ];
//           break;

//         default:
//           _screens = [_guestScreen()];
//           _navItems = [];
//       }
//     } else {
//       _screens = [_guestScreen()];
//       _navItems = [];
//     }
//   }

//   Widget _guestScreen() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.brown.shade200, Colors.brown.shade50],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Center(
//         child: Card(
//           elevation: 8,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           margin: const EdgeInsets.symmetric(horizontal: 24),
//           child: Padding(
//             padding: const EdgeInsets.all(32),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.local_cafe, size: 80, color: Colors.brown.shade400),
//                 const SizedBox(height: 16),
//                 const Text(
//                   "Welcome to Our Cafe ",
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.brown,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 12),
//                 const Text(
//                   "Please login or sign up to continue",
//                   style: TextStyle(fontSize: 16, color: Colors.black87),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 32),
//                 ElevatedButton.icon(
//                   icon: const Icon(Icons.login),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.brown.shade400,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 36,
//                       vertical: 14,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const LoginScreen(),
//                       ),
//                     );
//                   },
//                   label: const Text("Login", style: TextStyle(fontSize: 16)),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton.icon(
//                   icon: const Icon(Icons.person_add),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.brown.shade200,
//                     foregroundColor: Colors.brown.shade800,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 36,
//                       vertical: 14,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const SignupScreen(),
//                       ),
//                     );
//                   },
//                   label: const Text("Sign Up", style: TextStyle(fontSize: 16)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();

//     if (mounted) {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => const LoginScreen()),
//         (route) => false,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!widget.isLoggedIn) {
//       return Scaffold(body: _guestScreen());
//     }

//     return Scaffold(
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: _navItems.isNotEmpty
//           ? BottomNavigationBar(
//               currentIndex: _selectedIndex,
//               selectedItemColor: Colors.brown,
//               unselectedItemColor: Colors.grey,
//               onTap: (index) => setState(() => _selectedIndex = index),
//               items: _navItems,
//             )
//           : null,
//     );
//   }
// }