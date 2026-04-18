import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'chat_room_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final myEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseService.getUserChats(myEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colors.accent));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load chats: ${snapshot.error}',
                style: TextStyle(color: Colors.red[300]),
              ),
            );
          }
          final chats = snapshot.data?.docs ?? [];
          if (chats.isEmpty) {
            return Center(
              child: Text(
                'No chats yet',
                style: TextStyle(color: colors.secondaryText),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final data = chats[index].data();
              final participants =
                  (data['participants'] as List<dynamic>? ?? const [])
                      .map((e) => e.toString())
                      .toList();
              final other = participants.firstWhere(
                (e) => e != myEmail,
                orElse: () => 'Unknown',
              );
              final last = (data['lastMessage'] ?? '').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(otherUserEmail: other),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: colors.overlay,
                    child: Icon(Icons.person, color: colors.accent),
                  ),
                  title: Text(
                    other.split('@').first,
                    style: TextStyle(color: colors.primaryText),
                  ),
                  subtitle: Text(
                    last.isEmpty ? 'Say hello' : last,
                    style: TextStyle(color: colors.secondaryText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(Icons.chevron_right, color: colors.secondaryText),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
