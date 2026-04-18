import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class ChatRoomScreen extends StatefulWidget {
  final String otherUserEmail;

  const ChatRoomScreen({super.key, required this.otherUserEmail});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  String get _myEmail => FirebaseAuth.instance.currentUser?.email ?? '';
  String get _chatId => FirebaseService.chatIdFor(_myEmail, widget.otherUserEmail);

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final message = _controller.text.trim();
    if (message.isEmpty || _myEmail.isEmpty) return;
    setState(() => _sending = true);
    try {
      await FirebaseService.sendChatMessage(
        chatId: _chatId,
        senderEmail: _myEmail,
        receiverEmail: widget.otherUserEmail,
        message: message,
      );
      _controller.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 72,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(widget.otherUserEmail.split('@').first)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseService.getChatMessages(_chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colors.accent),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load chat: ${snapshot.error}',
                      style: TextStyle(color: Colors.red[300]),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Start the conversation',
                      style: TextStyle(color: colors.secondaryText),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final sender = (data['senderEmail'] ?? '').toString();
                    final text = (data['message'] ?? '').toString();
                    final ts = data['timestamp'] as Timestamp?;
                    final mine = sender == _myEmail;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: mine ? colors.accent : colors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: mine ? colors.accent : colors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: TextStyle(
                                color:
                                    mine ? Colors.white : colors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _timeAgo(ts),
                              style: TextStyle(
                                fontSize: 11,
                                color: mine
                                    ? Colors.white.withAlpha(190)
                                    : colors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: colors.primaryText),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: colors.secondaryText),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.accent,
                            ),
                          )
                        : Icon(Icons.send_rounded, color: colors.accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return 'now';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}
