import 'package:flutter/material.dart';

import '../item_detail/item_detail_screen.dart';
import '../models/item_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_with_loader.dart';
import '../widgets/pressable_glow.dart';

class WishlistScreen extends StatelessWidget {
  final String userEmail;

  const WishlistScreen({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('My Wishlist')),
      body: StreamBuilder<List<ItemModel>>(
        stream: FirebaseService.getWishlistItems(userEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colors.accent),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load wishlist: ${snapshot.error}',
                style: TextStyle(color: Colors.red[300]),
              ),
            );
          }
          final items = snapshot.data ?? const <ItemModel>[];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No wishlist items yet ❤️',
                style: TextStyle(color: colors.secondaryText, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            itemBuilder: (context, index) => _WishlistCard(item: items[index]),
          );
        },
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final ItemModel item;

  const _WishlistCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(18);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: radius,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withAlpha(16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PressableGlow(
        borderRadius: radius,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              NetworkImageWithLoader(
                imageUrl: item.imageUrl,
                width: 74,
                height: 74,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(14),
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
                        fontWeight: FontWeight.w700,
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
            ],
          ),
        ),
      ),
    );
  }
}
