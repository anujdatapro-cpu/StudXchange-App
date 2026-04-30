import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../services/firebase_service.dart';
import '../item_detail/item_detail_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_with_loader.dart';
import '../widgets/pressable_glow.dart';

class BuyScreen extends StatefulWidget {
  const BuyScreen({super.key});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  final _searchController = TextEditingController();

  bool _isGridView = true;

  List<ItemModel> _filterItems(List<ItemModel> items) {
    final query = _searchController.text.toLowerCase();

    return items.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildItemCard(ItemModel item) {
    final radius = BorderRadius.circular(16);
    return PressableGlow(
      borderRadius: radius,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ItemDetailScreen(item: item)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.card,
          borderRadius: radius,
          border: Border.all(color: context.appColors.border),
          boxShadow: [
            BoxShadow(
              color: context.appColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NetworkImageWithLoader(
                imageUrl: item.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                iconSize: 40,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                item.title,
                style: TextStyle(color: context.appColors.primaryText, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.formattedPrice,
                style: TextStyle(color: context.appColors.accent),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(ItemModel item) {
    final radius = BorderRadius.circular(12);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: PressableGlow(
        borderRadius: radius,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ItemDetailScreen(item: item)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: context.appColors.card,
            borderRadius: radius,
            border: Border.all(color: context.appColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: NetworkImageWithLoader(
              imageUrl: item.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12),
              iconSize: 26,
            ),
            title: Text(item.title, style: TextStyle(color: context.appColors.primaryText)),
            subtitle: Text(item.description, style: TextStyle(color: context.appColors.secondaryText)),
            trailing: Text(
              item.formattedPrice,
              style: TextStyle(color: context.appColors.accent),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Browse Items'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: colors.accent),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: colors.primaryText),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: colors.secondaryText),
                filled: true,
                fillColor: colors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.accent, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Items
          Expanded(
            child: StreamBuilder<List<ItemModel>>(
              stream: FirebaseService.getItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: colors.primaryText),
                    ),
                  );
                }

                final items = _filterItems(snapshot.data ?? []);

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No items found',
                      style: TextStyle(color: colors.secondaryText),
                    ),
                  );
                }

                return _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _buildItemCard(items[index]);
                        },
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _buildListItem(items[index]);
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}