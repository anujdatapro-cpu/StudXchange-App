import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../booking/bookings_screen.dart';
import '../chat/chats_screen.dart';
import '../models/comment_model.dart';
import '../models/item_model.dart';
import '../services/firebase_service.dart';
import '../item_detail/item_detail_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_with_loader.dart';
import '../widgets/pressable_glow.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final seed = (widget.userName.trim().isNotEmpty
            ? widget.userName.trim()
            : widget.userEmail.trim())
        .trim();
    final initial =
        seed.isNotEmpty ? seed.substring(0, 1).toUpperCase() : null;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<List<ItemModel>>(
        stream: FirebaseService.getUserItems(widget.userEmail),
        builder: (context, itemSnapshot) {
          final items = itemSnapshot.data ?? const <ItemModel>[];
          final listed = items.length;
          final sold =
              items.where((i) => (i.status ?? 'available') == 'sold').length;

          return StreamBuilder<List<CommentModel>>(
            stream: FirebaseService.getCommentsByUser(widget.userEmail),
            builder: (context, reviewsSnapshot) {
              final reviews = reviewsSnapshot.data ?? const <CommentModel>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 450),
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 10),
                        child: child,
                      ),
                    ),
                    child: _buildProfileHeader(colors, initial),
                  ),
                  const SizedBox(height: 16),
                  _glassContainer(
                    colors: colors,
                    child: Row(
                      children: [
                        _StatTile(label: 'Items listed', value: '$listed'),
                        _divider(context),
                        _StatTile(label: 'Items sold', value: '$sold'),
                        _divider(context),
                        _StatTile(label: 'Total reviews', value: '${reviews.length}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ChatsScreen()),
                            );
                          },
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('Chats'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BookingsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('My Orders'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'My Items'),
                  const SizedBox(height: 10),
                  if (itemSnapshot.connectionState == ConnectionState.waiting)
                    _loadingPill(colors)
                  else if (itemSnapshot.hasError)
                    Text(
                      'Failed to load your items: ${itemSnapshot.error}',
                      style: TextStyle(color: Colors.red[300]),
                    )
                  else if (items.isEmpty)
                    _emptyCard(colors, 'No items listed yet.')
                  else
                    ...items.map((item) => _MyItemCard(
                          item: item,
                          onOpen: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItemDetailScreen(item: item),
                              ),
                            );
                          },
                          onDelete: () async {
                            HapticFeedback.lightImpact();
                            await FirebaseService.deleteItem(item.id);
                          },
                        )),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'My Reviews'),
                  const SizedBox(height: 10),
                  if (reviewsSnapshot.connectionState == ConnectionState.waiting)
                    _loadingPill(colors)
                  else if (reviewsSnapshot.hasError)
                    Text(
                      'Failed to load your reviews: ${reviewsSnapshot.error}',
                      style: TextStyle(color: Colors.red[300]),
                    )
                  else if (reviews.isEmpty)
                    _emptyCard(colors, 'You have not reviewed any item yet.')
                  else
                    ...reviews.take(8).map((review) => _MyReviewCard(review: review)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(AppThemeColors colors, String? initial) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A84FF), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withAlpha(90),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withAlpha(120)),
                ),
                child: Center(
                  child: Text(
                    initial ?? 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.userEmail,
                      style: TextStyle(
                        color: Colors.white.withAlpha(214),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'VIT Pune Student',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withAlpha(110)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PressableGlow(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(70),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(44)),
                  ),
                  child: const Icon(Icons.logout, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colors = context.appColors;
    return Text(
      title,
      style: TextStyle(
        color: colors.primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _glassContainer({required AppThemeColors colors, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card.withAlpha(220),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.accent.withAlpha(50), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withAlpha(35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _loadingPill(AppThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: CircularProgressIndicator(color: colors.accent),
      ),
    );
  }

  Widget _emptyCard(AppThemeColors colors, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        text,
        style: TextStyle(color: colors.secondaryText),
      ),
    );
  }
}

Widget _divider(BuildContext context) => Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: context.appColors.border,
    );

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.accent,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: colors.secondaryText, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MyItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _MyItemCard({
    required this.item,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(18);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableGlow(
        borderRadius: radius,
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: radius,
            border: Border.all(color: colors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                NetworkImageWithLoader(
                  imageUrl: item.imageUrl,
                  width: 64,
                  height: 64,
                  borderRadius: BorderRadius.circular(16),
                  iconSize: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.formattedPrice,
                        style: TextStyle(
                          color: colors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PressableGlow(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.background.withAlpha(64),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border, width: 1),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyReviewCard extends StatelessWidget {
  final CommentModel review;

  const _MyReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
              Text(
                'Item: ${review.itemId}',
                style: TextStyle(
                  color: colors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                review.timeAgo,
                style: TextStyle(color: colors.secondaryText, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (index) {
              final active = index < review.rating;
              return Icon(
                active ? Icons.star_rounded : Icons.star_outline_rounded,
                color: colors.accent,
                size: 18,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: TextStyle(color: colors.secondaryText),
          ),
        ],
      ),
    );
  }
}
