import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafe/constants/api_constants.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'cart_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> topPicks = [];
  bool isLoading = true;

  // Animation variables
  late AnimationController _controller;
  late Animation<Offset> _animation;
  GlobalKey cartKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(ApiConstants.products));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> productList = data
            .map((e) => e as Map<String, dynamic>)
            .toList();

        productList.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

        final random = Random();
        topPicks = List.generate(
          min(5, productList.length),
          (_) => productList[random.nextInt(productList.length)],
        );

        setState(() {
          products = productList;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load products");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> addToCart(int productId, GlobalKey imageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("You must login first!")));
      return;
    }

    final url = Uri.parse("${ApiConstants.baseUrl}/cart/add/$productId");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        _runAddToCartAnimation(imageKey);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Added to cart!")));
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Unauthorized!")));
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${data['detail'] ?? 'Unknown error'}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Exception: $e")));
    }
  }

  void _runAddToCartAnimation(GlobalKey imageKey) {
    final renderBox = imageKey.currentContext!.findRenderObject() as RenderBox;
    final imagePosition = renderBox.localToGlobal(Offset.zero);
    final imageSize = renderBox.size;

    final cartRenderBox =
        cartKey.currentContext!.findRenderObject() as RenderBox;
    final cartPosition = cartRenderBox.localToGlobal(Offset.zero);

    final overlay = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final dx =
              imagePosition.dx +
              (cartPosition.dx - imagePosition.dx) * _controller.value;
          final dy =
              imagePosition.dy +
              (cartPosition.dy - imagePosition.dy) * _controller.value;

          final scale = 1.0 - 0.5 * _controller.value;

          return Positioned(
            left: dx,
            top: dy,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: Image(
          image: (imageKey.currentWidget as Image).image,
          width: imageSize.width,
          height: imageSize.height,
        ),
      ),
    );

    overlay?.insert(overlayEntry);
    _controller.forward(from: 0).then((value) {
      overlayEntry.remove();
    });
  }

  void showProductDialog(Map<String, dynamic> product) {
    final imageKey = GlobalKey();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product['image_url'],
                    key: imageKey,
                    height: 250,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      height: 250,
                      child: const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  product['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  product['description'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Price: ₹${product['price']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: product['available']
                        ? const Color.fromARGB(255, 199, 142, 121)
                        : Colors.grey,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  onPressed: product['available']
                      ? () => addToCart(product['id'], imageKey)
                      : null,
                  child: Text(
                    product['available'] ? "Add to Cart" : "Out of Stock",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Products"),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
            key: cartKey,
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/img1.webp', // Your image path
              fit: BoxFit.cover,
            ),
          ),

          // Semi-transparent overlay to reduce opacity
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5), // Adjust opacity as needed
            ),
          ),

          // Main content
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: fetchProducts,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (topPicks.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              "Today's Top Picks",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // White for readability
                              ),
                            ),
                          ),
                          CarouselSlider(
                            options: CarouselOptions(
                              height: 220,
                              autoPlay: true,
                              autoPlayInterval: const Duration(seconds: 3),
                              autoPlayAnimationDuration: const Duration(
                                milliseconds: 800,
                              ),
                              autoPlayCurve: Curves.easeInOut,
                              enlargeCenterPage: true,
                              viewportFraction: 0.8,
                            ),
                            items: topPicks.map((product) {
                              return GestureDetector(
                                onTap: () => showProductDialog(product),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    product['image_url'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                Icons.broken_image,
                                                size: 40,
                                                color: Colors.white70,
                                              ),
                                            ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.75,
                                ),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              final imageKey = GlobalKey();

                              return GestureDetector(
                                onTap: () => showProductDialog(product),
                                child: Card(
                                  color: const Color.fromARGB(
                                    255,
                                    51,
                                    41,
                                    41,
                                  ).withOpacity(0.6), // Slightly dark card
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                          child: Image.network(
                                            product['image_url'],
                                            key: imageKey,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      color: Colors.grey[800],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        size: 40,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors
                                                    .white, // readable on dark
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "₹${product['price']}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(
                                                  0xFFDCAF84,
                                                ), // brownish text
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    product['available']
                                                    ? const Color.fromARGB(
                                                        225,
                                                        100,
                                                        20,
                                                        20,
                                                      )
                                                    : Colors.grey,
                                                minimumSize:
                                                    const Size.fromHeight(30),
                                              ),
                                              onPressed: product['available']
                                                  ? () => addToCart(
                                                      product['id'],
                                                      imageKey,
                                                    )
                                                  : null,
                                              child: Text(
                                                product['available']
                                                    ? "Add to Cart"
                                                    : "Out of Stock",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
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
                  ),
                ),
        ],
      ),
    );

    // return Scaffold(

    //   appBar: AppBar(
    //     title: const Text("Products"),
    //     backgroundColor: Colors.brown,
    //     actions: [
    //       IconButton(
    //         key: cartKey,
    //         icon: const Icon(Icons.shopping_cart),
    //         onPressed: () {
    //           Navigator.push(
    //             context,
    //             MaterialPageRoute(builder: (_) => const CartScreen()),
    //           );
    //         },
    //       ),
    //     ],
    //   ),
    //   body: isLoading
    //       ? const Center(child: CircularProgressIndicator())
    //       : RefreshIndicator(
    //           onRefresh: fetchProducts,
    //           child: SingleChildScrollView(
    //             physics: const AlwaysScrollableScrollPhysics(),
    //             child: Column(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //                 if (topPicks.isNotEmpty) ...[
    //                   const Padding(
    //                     padding: EdgeInsets.all(12),
    //                     child: Text(
    //                       "Today's Top Picks",
    //                       style: TextStyle(
    //                         fontSize: 20,
    //                         fontWeight: FontWeight.bold,
    //                       ),
    //                     ),
    //                   ),
    //                   CarouselSlider(
    //                     options: CarouselOptions(
    //                       height: 220,
    //                       autoPlay: true,
    //                       autoPlayInterval: const Duration(seconds: 3),
    //                       autoPlayAnimationDuration: const Duration(
    //                         milliseconds: 800,
    //                       ),
    //                       autoPlayCurve: Curves.easeInOut,
    //                       enlargeCenterPage: true,
    //                       viewportFraction: 0.8,
    //                     ),
    //                     items: topPicks.map((product) {
    //                       return GestureDetector(
    //                         onTap: () => showProductDialog(product),
    //                         child: ClipRRect(
    //                           borderRadius: BorderRadius.circular(12),
    //                           child: Image.network(
    //                             product['image_url'],
    //                             fit: BoxFit.cover,
    //                             width: double.infinity,
    //                             errorBuilder: (context, error, stackTrace) =>
    //                                 Container(
    //                                   color: Colors.grey[300],
    //                                   child: const Icon(
    //                                     Icons.broken_image,
    //                                     size: 40,
    //                                   ),
    //                                 ),
    //                           ),
    //                         ),
    //                       );
    //                     }).toList(),
    //                   ),
    //                 ],
    //                 const SizedBox(height: 16),
    //                 Padding(
    //                   padding: const EdgeInsets.symmetric(horizontal: 8.0),
    //                   child: GridView.builder(
    //                     physics: const NeverScrollableScrollPhysics(),
    //                     shrinkWrap: true,
    //                     itemCount: products.length,
    //                     gridDelegate:
    //                         const SliverGridDelegateWithFixedCrossAxisCount(
    //                           crossAxisCount: 2,
    //                           crossAxisSpacing: 12,
    //                           mainAxisSpacing: 12,
    //                           childAspectRatio: 0.75,
    //                         ),
    //                     itemBuilder: (context, index) {
    //                       final product = products[index];
    //                       final imageKey = GlobalKey();

    //                       return GestureDetector(
    //                         onTap: () => showProductDialog(product),
    //                         child: Card(
    //                           elevation: 4,
    //                           shape: RoundedRectangleBorder(
    //                             borderRadius: BorderRadius.circular(12),
    //                           ),
    //                           child: Column(
    //                             crossAxisAlignment: CrossAxisAlignment.stretch,
    //                             children: [
    //                               Expanded(
    //                                 child: ClipRRect(
    //                                   borderRadius: const BorderRadius.vertical(
    //                                     top: Radius.circular(12),
    //                                   ),
    //                                   child: Image.network(
    //                                     product['image_url'],
    //                                     key: imageKey,
    //                                     fit: BoxFit.cover,
    //                                     errorBuilder:
    //                                         (context, error, stackTrace) =>
    //                                             Container(
    //                                               color: Colors.grey[300],
    //                                               child: const Icon(
    //                                                 Icons.broken_image,
    //                                                 size: 40,
    //                                               ),
    //                                             ),
    //                                   ),
    //                                 ),
    //                               ),
    //                               Padding(
    //                                 padding: const EdgeInsets.all(8.0),
    //                                 child: Column(
    //                                   crossAxisAlignment:
    //                                       CrossAxisAlignment.start,
    //                                   children: [
    //                                     Text(
    //                                       product['name'],
    //                                       style: const TextStyle(
    //                                         fontWeight: FontWeight.bold,
    //                                         fontSize: 16,
    //                                       ),
    //                                     ),
    //                                     const SizedBox(height: 4),
    //                                     Text(
    //                                       "₹${product['price']}",
    //                                       style: const TextStyle(
    //                                         fontWeight: FontWeight.bold,
    //                                         color: Colors.brown,
    //                                         fontSize: 14,
    //                                       ),
    //                                     ),
    //                                     const SizedBox(height: 6),
    //                                     ElevatedButton(
    //                                       style: ElevatedButton.styleFrom(
    //                                         backgroundColor:
    //                                             product['available']
    //                                             ? const Color.fromARGB(
    //                                                 141,
    //                                                 223,
    //                                                 135,
    //                                                 104,
    //                                               )
    //                                             : Colors.grey,
    //                                         minimumSize: const Size.fromHeight(
    //                                           30,
    //                                         ),
    //                                       ),
    //                                       onPressed: product['available']
    //                                           ? () => addToCart(
    //                                               product['id'],
    //                                               imageKey,
    //                                             )
    //                                           : null,
    //                                       child: Text(
    //                                         product['available']
    //                                             ? "Add to Cart"
    //                                             : "Out of Stock",
    //                                         style: const TextStyle(
    //                                           fontSize: 14,
    //                                         ),
    //                                       ),
    //                                     ),
    //                                   ],
    //                                 ),
    //                               ),
    //                             ],
    //                           ),
    //                         ),
    //                       );
    //                     },
    //                   ),
    //                 ),
    //               ],
    //             ),
    //           ),
    //         ),

    // );
  }
}
