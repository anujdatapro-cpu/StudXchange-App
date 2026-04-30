import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/item_model.dart';
import '../services/firebase_service.dart';
import '../sell/sell_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_with_loader.dart';
import '../widgets/pressable_glow.dart';
import '../notifications/notifications_screen.dart';
import '../item_detail/item_detail_screen.dart';
import '../wishlist/wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _categories = [
    'All',
    'Electronics',
    'Furniture',
    'Books',
    'Tools',
    'Hostel',
    'Others',
  ];

  String _selectedCategory = 'All';
  bool _isLoadingRecommendations = true;
  List<ItemModel> _recommendedItems = const <ItemModel>[];
  List<String> _recentViewedItemIds = const <String>[];

  @override
  void initState() {
    super.initState();
    _loadRecentViewsAndRecommendations();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToAddItem() async {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellScreen()),
    );
  }

  Stream<int> get _unreadNotificationsStream {
    if (widget.userEmail.isEmpty) {
      return Stream<int>.value(0);
    }
    return FirebaseService.getUnreadNotificationCount(widget.userEmail);
  }

  Stream<List<ItemModel>> get _itemsStream {
    return FirebaseService.getItemsByCategory(_selectedCategory);
  }

  Future<void> _loadRecentViewsAndRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList('recent_viewed_item_ids') ?? <String>[];
    if (!mounted) return;
    setState(() {
      _recentViewedItemIds = recent;
      _isLoadingRecommendations = true;
    });
    final recommended = await FirebaseService.getRecommendations(
      userEmail: widget.userEmail,
      recentItemIds: _recentViewedItemIds,
      limit: 12,
    );
    if (!mounted) return;
    setState(() {
      _recommendedItems = recommended;
      _isLoadingRecommendations = false;
    });
  }

  Future<void> _registerViewedItem(ItemModel item) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList('recent_viewed_item_ids') ?? <String>[];
    current.remove(item.id);
    current.insert(0, item.id);
    final trimmed = current.take(20).toList();
    await prefs.setStringList('recent_viewed_item_ids', trimmed);
    _recentViewedItemIds = trimmed;
  }

  Future<void> _onRefresh() async {
    await _loadRecentViewsAndRecommendations();
  }

  Widget _buildNotificationAction() {
    final colors = context.appColors;

    return StreamBuilder<int>(
      stream: _unreadNotificationsStream,
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: colors.overlay,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF0A84FF),
                ),
              ),
              if (unread > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: unread > 9
                        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                        : const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.background, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withAlpha(128),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        unread > 99 ? '99+' : unread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A84FF), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.storefront,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'StudXchange',
              style: TextStyle(
                color: colors.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          _buildNotificationAction(),
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: colors.overlay,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: 'My wishlist',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WishlistScreen(userEmail: widget.userEmail),
                  ),
                );
              },
              icon: Icon(Icons.favorite_outline, color: colors.accent),
            ),
          ),
          // Theme Toggle Button (Sparkle)
          ValueListenableBuilder<bool>(
            valueListenable: isDarkMode,
            builder: (context, darkModeEnabled, _) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: colors.overlay,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  tooltip: darkModeEnabled
                      ? 'Switch to light mode'
                      : 'Switch to dark mode',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    isDarkMode.value = !isDarkMode.value;
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: Icon(
                      darkModeEnabled ? Icons.dark_mode : Icons.light_mode,
                      key: ValueKey<bool>(darkModeEnabled),
                      color: colors.accent,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddItem,
        backgroundColor: colors.accent,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 8,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        ),
        child: RefreshIndicator(
          color: colors.accent,
          onRefresh: _onRefresh,
          child: StreamBuilder<Set<String>>(
            stream: FirebaseService.getWishlistItemIds(widget.userEmail),
            builder: (context, wishlistSnapshot) {
              final wishlistIds = wishlistSnapshot.data ?? const <String>{};
              return StreamBuilder<List<ItemModel>>(
                stream: _itemsStream,
                builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _HomeShimmer();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading items: ${snapshot.error}',
                    style: TextStyle(color: colors.primaryText),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: items.isEmpty ? 8 : items.length + 7,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${widget.userName}! 👋',
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Find amazing deals from VIT Pune campus',
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _PremiumHeroCarousel(),
                      const SizedBox(height: 16),
                      _buildCategoryFilters(),
                      const SizedBox(height: 18),
                      _buildRecommendationsSection(),
                    ],
                  ),
                );
              }

              if (index == 1) {
                return const SizedBox(height: 18);
              }

              if (index == 2) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.overlay,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.accent.withAlpha(80)),
                        ),
                        child: Icon(
                          Icons.local_mall_outlined,
                          color: colors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Recent Items',
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.overlay,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.accent.withAlpha(80)),
                        ),
                        child: Text(
                          '${items.length} items',
                          style: TextStyle(
                            color: colors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (index == 3) return const SizedBox(height: 10);

              if (items.isEmpty) {
                if (index > 4) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: colors.secondaryText,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items available',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first item!',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final itemIndex = index - 4;
              if (itemIndex < 0 || itemIndex >= items.length) {
                return const SizedBox.shrink();
              }
              final item = items[itemIndex];
              return _buildItemCard(
                item,
                isWishlisted: wishlistIds.contains(item.id),
              );
            },
          );
        },
      );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final colors = context.appColors;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isActive = _selectedCategory == category;
          return GestureDetector(
            onTap: () {
              if (isActive) return;
              setState(() => _selectedCategory = category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? colors.accent : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isActive ? Colors.white : colors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: colors.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Recommended for you 🔥',
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingRecommendations)
          const SizedBox(height: 150, child: _RecommendationShimmerRow())
        else if (_recommendedItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              'No recommendations yet',
              style: TextStyle(color: colors.secondaryText),
            ),
          )
        else
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendedItems.length.clamp(0, 10),
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _buildRecommendedCard(_recommendedItems[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendedCard(ItemModel item) {
    final colors = context.appColors;
    return SizedBox(
      width: 170,
      child: PressableGlow(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await _registerViewedItem(item);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
          ).then((_) => _loadRecentViewsAndRecommendations());
        },
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.accent.withAlpha(22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetworkImageWithLoader(
                imageUrl: item.imageUrl,
                width: 170,
                height: 96,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                iconSize: 28,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  item.formattedPrice,
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(ItemModel item, {required bool isWishlisted}) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(20);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: radius,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withAlpha(20),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          PressableGlow(
            borderRadius: radius,
            onTap: () async {
              await _registerViewedItem(item);
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailScreen(item: item),
                ),
              ).then((_) => _loadRecentViewsAndRecommendations());
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NetworkImageWithLoader(
                    imageUrl: item.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(16),
                    iconSize: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 14,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.overlay,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.formattedPrice,
                                style: TextStyle(
                                  color: colors.accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.access_time,
                              color: colors.secondaryText,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.timeAgo,
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () async {
                await FirebaseService.toggleWishlist(
                  userEmail: widget.userEmail,
                  itemId: item.id,
                );
                _loadRecentViewsAndRecommendations();
              },
              icon: Icon(
                isWishlisted ? Icons.favorite : Icons.favorite_border,
                color: isWishlisted ? Colors.redAccent : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumHeroCarousel extends StatefulWidget {
  const _PremiumHeroCarousel();

  @override
  State<_PremiumHeroCarousel> createState() => _PremiumHeroCarouselState();
}

class _PremiumHeroCarouselState extends State<_PremiumHeroCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentPage = 0;
  Timer? _timer;

  static const List<String> _images = [
    'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=1400&q=80',
    'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1400&q=80',
    'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1400&q=80',
    'https://images.unsplash.com/photo-1553406830-ef2513450d76?auto=format&fit=crop&w=1400&q=80',
    'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=1400&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % 5;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const radius = BorderRadius.all(Radius.circular(20));

    return SizedBox(
      height: 198,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _images.length,
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double page = _currentPage.toDouble();
                  if (_pageController.hasClients &&
                      _pageController.position.haveDimensions) {
                    page = _pageController.page ?? _currentPage.toDouble();
                  }
                  final diff = (page - index).abs();
                  final scale = (1 - (diff * 0.08)).clamp(0.92, 1.0);
                  return Transform.scale(scale: scale, child: child);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withAlpha(40),
                          blurRadius: 18,
                          spreadRadius: 1.5,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          NetworkImageWithLoader(
                            imageUrl: _images[index],
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.zero,
                            iconSize: 40,
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xD9000000), Color(0x12000000)],
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 16,
                            right: 16,
                            bottom: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Best Deals 🔥',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Top picks for VIT students',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 10,
            child: Row(
              children: List.generate(_images.length, (index) {
                final isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: isActive ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF0A84FF) : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Container(height: 24, width: 180, color: colors.card),
        const SizedBox(height: 10),
        Container(height: 16, width: 220, color: colors.card),
        const SizedBox(height: 18),
        Container(
          height: 198,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 16),
        const _RecommendationShimmerRow(),
        const SizedBox(height: 18),
        ...List.generate(
          4,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 112,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationShimmerRow extends StatelessWidget {
  const _RecommendationShimmerRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) => Container(
          width: 170,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
