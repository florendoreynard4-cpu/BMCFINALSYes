import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.deepPurple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus, String userId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({'status': newStatus});
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Order Status Updated',
        'body': 'Your order ($orderId) is now "$newStatus".',
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }
  void _showStatusDialog(String orderId, String currentStatus, String userId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        const statuses = ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];
        return AlertDialog(
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map((status) {
              return ListTile(
                title: Text(status),
                trailing: currentStatus.toLowerCase() == status.toLowerCase()
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  _updateOrderStatus(orderId, status, userId);
                  Navigator.of(dialogContext).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Manage All Orders'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('orders').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No orders found.'));
              }
              final orders = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final orderDoc = orders[index];
                  final orderData = orderDoc.data() as Map<String, dynamic>;
                  final status = orderData['status'] ?? 'pending';
                  final total = orderData['totalPrice'] ?? 0.0; // <- FIXED
                  final userEmail = orderData['userEmail'] ?? 'Unknown';
                  final userId = orderData['userId'] ?? '';
                  final createdAt = (orderData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('Order #${orderDoc.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User: $userEmail'),
                          Text('Total: ₱${total.toStringAsFixed(2)}'), // <- FIXED
                          Text('Date: ${createdAt.day}/${createdAt.month}/${createdAt.year}'),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      onTap: () => _showStatusDialog(orderDoc.id, status, userId),
                    ),
                  );
                },
              );
            },
        ),
    );
  }
}