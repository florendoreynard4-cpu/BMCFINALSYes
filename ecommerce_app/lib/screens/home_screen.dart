import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/cart_screen.dart';
import 'package:ecommerce_app/screens/order_history_screen.dart';
import 'package:ecommerce_app/screens/product_detail_screen.dart';
import 'package:ecommerce_app/screens/profile_screen.dart';
import 'package:ecommerce_app/screens/chat_screen.dart';
import 'package:ecommerce_app/screens/admin_panel_screen.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:ecommerce_app/widgets/notification_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    if (widget.user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        setState(() => _userRole = doc.data()!['role']);
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.user;
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/app_logo.png',
          height: 40,
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) => Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
            ),
          ),
          const NotificationIcon(),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'My Orders',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            ),
          ),
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text('No products found.'));

          final products = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDoc = products[index];
              final productData = productDoc.data()! as Map<String, dynamic>;
              return ProductCard(
                productName: productData['name'],
                price: productData['price'],
                imageUrl: productData['imageUrl'],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      productData: productData,
                      productId: productDoc.id,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _userRole == 'user'
          ? StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          int unreadCount = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data =
            snapshot.data!.data() as Map<String, dynamic>?;
            unreadCount = data?['unreadByUserCount'] ?? 0;
          }
          return Badge(
            label: Text('$unreadCount'),
            isLabelVisible: unreadCount > 0,
            child: FloatingActionButton.extended(
              icon: const Icon(Icons.support_agent),
              label: const Text('Contact Admin'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ChatScreen(chatRoomId: currentUser.uid),
                ),
              ),
            ),
          );
        },
      )
          : null,
    );
  }
}
