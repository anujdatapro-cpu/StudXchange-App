import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../chat/chat_room_screen.dart';
import '../models/comment_model.dart';
import '../models/item_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_with_loader.dart';
import '../widgets/pressable_glow.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 5;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    FirebaseService.ensureDemoReviewsForItem(widget.item.id);
  }

  Future<void> _postComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await FirebaseService.addComment(
        widget.item.id,
        user.email ?? "user",
        _commentController.text.trim(),
        _selectedRating,
      );

      // Send notification to item owner (if not the commenter)
      final itemOwnerEmail = widget.item.ownerEmail;
      final commenterEmail = user.email ?? "user";
      if (itemOwnerEmail.isNotEmpty && itemOwnerEmail != commenterEmail) {
        await FirebaseService.addNotification(
          userEmail: itemOwnerEmail,
          title: 'New comment on your item 💬',
          message: 'Someone commented on "${widget.item.title}". Check it out!',
        );
      }

      if (!mounted) return;
      _commentController.clear();
      setState(() => _selectedRating = 5);
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _bookItem() async {
    final buyer = FirebaseAuth.instance.currentUser?.email;
    if (buyer == null || buyer.isEmpty) return;
    if (buyer == widget.item.ownerEmail) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = context.appColors;
        return AlertDialog(
          backgroundColor: colors.card,
          title: Text('Confirm Booking', style: TextStyle(color: colors.primaryText)),
          content: Text(
            'Do you want to place booking for "${widget.item.title}"?',
            style: TextStyle(color: colors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    await FirebaseService.createBooking(
      itemId: widget.item.id,
      buyerEmail: buyer,
      sellerEmail: widget.item.ownerEmail,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking request sent')),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Item Detail'),
      ),
      body: StreamBuilder<List<CommentModel>>(
        stream: FirebaseService.getComments(widget.item.id),
        builder: (context, snapshot) {
          final comments = snapshot.data ?? const <CommentModel>[];
          final totalReviews = comments.length;
          final totalRating = comments.fold<double>(
            0,
            (sum, item) => sum + item.rating.toDouble(),
          );
          final averageRating =
              totalReviews == 0 ? 0.0 : (totalRating / totalReviews);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  color: colors.card,
                  child: NetworkImageWithLoader(
                    imageUrl: widget.item.imageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    iconSize: 56,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.item.formattedPrice,
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.item.description,
                        style: TextStyle(color: colors.secondaryText),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatRoomScreen(
                                      otherUserEmail: widget.item.ownerEmail,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Contact Seller'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _bookItem,
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: const Text('Buy Now'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star_rounded, color: colors.accent, size: 26),
                            const SizedBox(width: 8),
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: TextStyle(
                                color: colors.primaryText,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$totalReviews reviews',
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Add your review',
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(5, (index) {
                          final current = index + 1;
                          final filled = current <= _selectedRating;
                          return IconButton(
                            onPressed: _isPosting
                                ? null
                                : () => setState(() => _selectedRating = current),
                            icon: Icon(
                              filled ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: colors.accent,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: TextStyle(color: colors.primaryText),
                              decoration: InputDecoration(
                                hintText: "Write your review...",
                                hintStyle: TextStyle(color: colors.secondaryText),
                                filled: true,
                                fillColor: colors.card,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: colors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: colors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: colors.accent, width: 1.6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          PressableGlow(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _isPosting ? null : _postComment,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.accent.withAlpha(120)),
                              ),
                              child: _isPosting
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: colors.accent,
                                      ),
                                    )
                                  : Icon(Icons.send_rounded, color: colors.accent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Reviews',
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: CircularProgressIndicator(color: colors.accent),
                          ),
                        )
                      else if (snapshot.hasError)
                        Text(
                          'Failed to load comments: ${snapshot.error}',
                          style: TextStyle(color: Colors.red[300]),
                        )
                      else if (comments.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            'Be the first to review',
                            style: TextStyle(color: colors.secondaryText),
                          ),
                        )
                      else
                        ...comments.map((comment) => _ReviewCard(comment: comment)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final CommentModel comment;

  const _ReviewCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FutureBuilder<String>(
      future: FirebaseService.getUserNameByEmail(comment.userEmail),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? comment.userEmail.split('@').first;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      userName,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    comment.timeAgo,
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (index) {
                  final active = index < comment.rating;
                  return Icon(
                    active ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: colors.accent,
                    size: 18,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                comment.comment,
                style: TextStyle(color: colors.secondaryText),
              ),
            ],
          ),
        );
      },
    );
  }
}
