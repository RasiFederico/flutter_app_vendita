// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';
import '../models/listing.dart';
import '../services/supabase_service.dart';
import 'product_screen.dart';
import 'listing_screen.dart';

class HomeScreen extends StatefulWidget {
  // Notifier passato da MainScaffold: si incrementa ogni volta che si tappa
  // sul tab Home → la screen ricarica i preferiti automaticamente.
  final ValueNotifier<int>? refreshNotifier;

  const HomeScreen({super.key, this.refreshNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = -1;
  final Set<String> _favorites = {};

  // Preferiti da Supabase (annunci reali)
  List<Listing> _favoriteListings = [];
  bool _favLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    widget.refreshNotifier?.addListener(_onExternalRefresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onExternalRefresh);
    super.dispose();
  }

  // Chiamato ogni volta che si tappa sul tab Home
  void _onExternalRefresh() => _loadFavorites();

  Future<void> _loadFavorites() async {
    if (SupabaseService.currentUser == null) {
      if (mounted) setState(() => _favLoading = false);
      return;
    }
    if (mounted) setState(() => _favLoading = true);
    try {
      final favs = await SupabaseService.getFavoriteListings();
      if (mounted) setState(() => _favoriteListings = favs);
    } catch (_) {}
    if (mounted) setState(() => _favLoading = false);
  }

  // Toggle locale per i prodotti mock (non Supabase)
  void _toggleFavorite(String id) => setState(() {
        _favorites.contains(id)
            ? _favorites.remove(id)
            : _favorites.add(id);
      });

  void _openProduct(BuildContext context, Product product) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ProductScreen(product: product),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
      ),
    );
  }

  void _openListing(BuildContext context, Listing listing) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ListingScreen(listing: listing),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
      ),
    ).then((_) => _loadFavorites()); // ricarica al ritorno dall'annuncio
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFavorites,
          color: SwabbitTheme.accent,
          backgroundColor: SwabbitTheme.surface,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSearchBar(context)),
              SliverToBoxAdapter(child: _buildCategories()),
              SliverToBoxAdapter(child: _buildFeaturedBanner(context)),

              // ── PREFERITI (solo se loggato) ────────────────────────
              if (SupabaseService.currentUser != null) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    title: 'I tuoi preferiti',
                    icon: Icons.favorite_rounded,
                    iconColor: SwabbitTheme.accent3,
                    count: _favoriteListings.length,
                  ),
                ),
                if (_favLoading)
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 140,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: SwabbitTheme.accent, strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_favoriteListings.isEmpty)
                  SliverToBoxAdapter(child: _buildFavEmpty())
                else
                  SliverToBoxAdapter(child: _buildFavoritesRow(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],

              // ── ANNUNCI RECENTI ────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  title: 'Annunci recenti',
                  icon: Icons.bolt_rounded,
                  iconColor: SwabbitTheme.accent,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildProductCard(context, AppData.products[index]),
                    childCount: AppData.products.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Swab',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    color: SwabbitTheme.text,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'bit',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    color: SwabbitTheme.accent,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Stack(
            children: [
              _IconButton(
                  icon: Icons.notifications_none_rounded, onTap: () {}),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: SwabbitTheme.accent3,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: SwabbitTheme.surface2, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          _IconButton(icon: Icons.tune_rounded, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: SwabbitTheme.surface,
            borderRadius: BorderRadius.circular(SwabbitTheme.radiusSm),
            border: Border.all(color: SwabbitTheme.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded,
                  size: 18, color: SwabbitTheme.text3),
              SizedBox(width: 10),
              Text('Cerca GPU, RAM, CPU...',
                  style: TextStyle(
                      fontSize: 14, color: SwabbitTheme.text3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text('Categorie',
              style: SwabbitTheme.displayStyle.copyWith(fontSize: 17)),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: AppData.categories.length,
            itemBuilder: (ctx, i) {
              final cat = AppData.categories[i];
              final isSelected = _selectedCategoryIndex == i;
              return GestureDetector(
                onTap: () => setState(
                    () => _selectedCategoryIndex = isSelected ? -1 : i),
                child: Container(
                  width: 64,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: isSelected ? cat.gradient : null,
                          color: isSelected ? null : SwabbitTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? SwabbitTheme.accent
                                : SwabbitTheme.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: SwabbitTheme.accent
                                        .withOpacity(0.25),
                                    blurRadius: 16,
                                  )
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(cat.emoji,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(cat.label,
                          style: const TextStyle(
                              fontSize: 11,
                              color: SwabbitTheme.text2,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFeaturedBanner(BuildContext context) {
    final featured = AppData.products.firstWhere((p) => p.isFeatured);
    return GestureDetector(
      onTap: () => _openProduct(context, featured),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a0933),
              Color(0xFF0d1a33),
              Color(0xFF001a1a)
            ],
          ),
          borderRadius: BorderRadius.circular(SwabbitTheme.radius),
          border:
              Border.all(color: SwabbitTheme.accent2.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -20,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      SwabbitTheme.accent2.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SwabbitTheme.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: SwabbitTheme.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    featured.originalPrice != null
                        ? '−${((1 - featured.price / featured.originalPrice!) * 100).round()}%'
                        : 'TOP',
                    style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: SwabbitTheme.green),
                  ),
                ),
                const SizedBox(height: 10),
                Text(featured.title,
                    style: SwabbitTheme.displayStyle
                        .copyWith(fontSize: 18, height: 1.2)),
                const SizedBox(height: 6),
                Text('€ ${featured.price.toStringAsFixed(0)}',
                    style: SwabbitTheme.monoStyle.copyWith(
                        fontSize: 22, color: SwabbitTheme.accent)),
                const SizedBox(height: 14),
                Row(children: [
                  Text(featured.emoji,
                      style: const TextStyle(fontSize: 36)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: SwabbitTheme.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Vedi',
                        style: TextStyle(
                            fontFamily: 'Syne',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black)),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── SECTION HEADER ────────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color iconColor,
    int? count,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: SwabbitTheme.displayStyle.copyWith(fontSize: 17)),
          if (count != null && count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: iconColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── FAVORITES ROW ─────────────────────────────────────────────────────────

  Widget _buildFavoritesRow(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _favoriteListings.length,
        itemBuilder: (ctx, i) {
          final listing = _favoriteListings[i];
          return _FavoriteCard(
            listing: listing,
            onTap: () => _openListing(context, listing),
            onRemove: () async {
              await SupabaseService.removeFavorite(listing.id);
              _loadFavorites();
            },
          );
        },
      ),
    );
  }

  Widget _buildFavEmpty() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SwabbitTheme.surface,
        borderRadius: BorderRadius.circular(SwabbitTheme.radius),
        border: Border.all(color: SwabbitTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: SwabbitTheme.accent3.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite_border_rounded,
                color: SwabbitTheme.accent3, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nessun preferito',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: SwabbitTheme.text)),
                SizedBox(height: 3),
                Text('Tocca ❤ su un annuncio per salvarlo qui.',
                    style: TextStyle(
                        fontSize: 12, color: SwabbitTheme.text2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PRODUCT CARD (mock) ───────────────────────────────────────────────────

  Widget _buildProductCard(BuildContext context, Product product) {
    final isFav = _favorites.contains(product.id);
    return GestureDetector(
      onTap: () => _openProduct(context, product),
      child: Container(
        decoration: SwabbitTheme.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration:
                        BoxDecoration(gradient: product.thumbGradient)),
                  Center(
                    child: Text(product.emoji,
                        style: const TextStyle(fontSize: 52)),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(product.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 14,
                            color: isFav
                                ? SwabbitTheme.accent3
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: SwabbitTheme.text)),
                  const SizedBox(height: 4),
                  Text('€ ${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: SwabbitTheme.accent)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            product.conditionColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(product.conditionLabel,
                          style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: product.conditionColor)),
                    ),
                    const Spacer(),
                    const Icon(Icons.location_on_outlined,
                        size: 10, color: SwabbitTheme.text3),
                    const SizedBox(width: 2),
                    Text(product.location,
                        style: const TextStyle(
                            fontSize: 10,
                            color: SwabbitTheme.text3)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAVORITE CARD ─────────────────────────────────────────────────────────────

class _FavoriteCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.listing,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImg = listing.images.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: SwabbitTheme.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasImg
                      ? Image.network(listing.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholder(listing))
                      : _placeholder(listing),
                  // Remove fav button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: SwabbitTheme.accent3.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.favorite_rounded,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                  // Condition badge
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            listing.condition.color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        listing.condition.label.toUpperCase(),
                        style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: SwabbitTheme.text,
                          height: 1.3)),
                  const SizedBox(height: 5),
                  Text('€ ${listing.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: SwabbitTheme.accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(Listing listing) => Container(
        color: SwabbitTheme.surface2,
        child: Center(
          child: Text(listing.categoryEmoji,
              style: const TextStyle(fontSize: 40)),
        ),
      );
}

// ── ICON BUTTON ───────────────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: SwabbitTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SwabbitTheme.border),
          ),
          child: Icon(icon, size: 18, color: SwabbitTheme.text2),
        ),
      );
}