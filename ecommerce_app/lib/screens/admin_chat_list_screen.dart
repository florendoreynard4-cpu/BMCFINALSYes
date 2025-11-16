import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/chat_screen.dart';
import 'package:flutter/material.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').orderBy('lastMessageAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No chats yet.'));

          final chats = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatData = chats[index].data()! as Map<String, dynamic>;
              final userEmail = chatData['userEmail'] ?? 'Unknown';
              final lastMessage = chatData['lastMessage'] ?? '';
              final unreadCount = chatData['unreadByAdminCount'] ?? 0;

              return ListTile(
                title: Text(userEmail),
                subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: unreadCount > 0
                    ? CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
                )
                    : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ChatScreen(chatRoomId: chats[index].id, userName: userEmail)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
