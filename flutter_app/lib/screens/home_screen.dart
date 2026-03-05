// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';
import '../models/listing.dart';
import '../services/supabase_service.dart';
import 'listing_screen.dart';

class HomeScreen extends StatefulWidget {
  // Notifier passato da MainScaffold: si incrementa ogni volta che si tappa
  // sul tab Home → la screen ricarica i dati automaticamente.
  final ValueNotifier<int>? refreshNotifier;

  const HomeScreen({super.key, this.refreshNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = -1;

  // Preferiti da Supabase
  List<Listing> _favoriteListings = [];
  bool _favLoading = true;

  // Annunci reali da Supabase
  List<Listing> _homeListings = [];
  bool _listingsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
    widget.refreshNotifier?.addListener(_onExternalRefresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onExternalRefresh);
    super.dispose();
  }

  void _onExternalRefresh() => _loadAll();

  Future<void> _loadAll() async {
    await Future.wait([_loadFavorites(), _loadListings()]);
  }

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

  Future<void> _loadListings() async {
    if (mounted) setState(() => _listingsLoading = true);
    try {
      // Recupera un pool di annunci recenti ampio per poi ordinarli lato client
      final listings = await SupabaseService.getRecentListings(limit: 60);
      final sorted = _applyScoringSort(listings);
      if (mounted) setState(() => _homeListings = sorted);
    } catch (_) {}
    if (mounted) setState(() => _listingsLoading = false);
  }

  /// Mini-algoritmo di ordinamento:
  ///   score = (views + BASE) / (ageInDays + DECAY)
  ///
  /// • BASE  = 10  → boost per i nuovi annunci con 0 visualizzazioni
  /// • DECAY = 14  → "età di dimezzamento" in giorni
  ///
  /// Effetto pratico:
  ///   - Annunci con molte views scalano in cima
  ///   - Annunci recenti con poche views possono battere annunci vecchi
  ///     anche popolari ("se troppo vecchio")
  ///   - Un annuncio con 0 views da oggi batte un annuncio da 30+ giorni
  ///     con poche views
  List<Listing> _applyScoringSort(List<Listing> listings) {
    const double base = 10.0;
    const double decay = 14.0;

    double _score(Listing l) {
      final ageInDays =
          DateTime.now().difference(l.createdAt).inHours / 24.0;
      return (l.views + base) / (ageInDays + decay);
    }

    final sorted = List<Listing>.from(listings);
    sorted.sort((a, b) => _score(b).compareTo(_score(a)));
    return sorted;
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
    ).then((_) => _loadAll()); // ricarica al ritorno dall'annuncio
  }

  // ── FILTERED LISTINGS (by category) ───────────────────────────────────────

  List<Listing> get _filteredListings {
    if (_selectedCategoryIndex < 0) return _homeListings;
    final catId = AppData.categories[_selectedCategoryIndex].id;
    return _homeListings
        .where((l) => l.category?.toLowerCase() == catId.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          color: SwabbitTheme.accent,
          backgroundColor: SwabbitTheme.surface,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSearchBar(context)),
              SliverToBoxAdapter(child: _buildCategories()),

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

              // ── ANNUNCI ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  title: 'In evidenza',
                  icon: Icons.bolt_rounded,
                  iconColor: SwabbitTheme.accent,
                  count: _filteredListings.isNotEmpty
                      ? _filteredListings.length
                      : null,
                ),
              ),

              if (_listingsLoading)
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: SwabbitTheme.accent, strokeWidth: 2),
                    ),
                  ),
                )
              else if (_filteredListings.isEmpty)
                SliverToBoxAdapter(child: _buildListingsEmpty())
              else
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
                      (context, index) => _buildListingCard(
                          context, _filteredListings[index]),
                      childCount: _filteredListings.length,
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
                    border:
                        Border.all(color: SwabbitTheme.surface2, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: SwabbitTheme.surface,
            borderRadius:
                BorderRadius.circular(SwabbitTheme.radiusSm),
            border: Border.all(color: SwabbitTheme.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded,
                  size: 18, color: SwabbitTheme.text3),
              SizedBox(width: 10),
              Text('Cerca GPU, RAM, CPU...',
                  style:
                      TextStyle(fontSize: 14, color: SwabbitTheme.text3)),
            ],
          ),
        ),
      ),
    );
  }

  // ── CATEGORIES ────────────────────────────────────────────────────────────

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
                    style: TextStyle(fontSize: 12, color: SwabbitTheme.text2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── LISTINGS EMPTY ────────────────────────────────────────────────────────

  Widget _buildListingsEmpty() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SwabbitTheme.surface,
        borderRadius: BorderRadius.circular(SwabbitTheme.radius),
        border: Border.all(color: SwabbitTheme.border),
      ),
      child: Column(
        children: [
          const Text('📦', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            _selectedCategoryIndex >= 0
                ? 'Nessun annuncio in questa categoria'
                : 'Nessun annuncio disponibile',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: SwabbitTheme.text),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sii il primo a pubblicare un annuncio!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: SwabbitTheme.text2),
          ),
        ],
      ),
    );
  }

  // ── LISTING CARD (reale, Supabase) ────────────────────────────────────────

  Widget _buildListingCard(BuildContext context, Listing listing) {
    return GestureDetector(
      onTap: () => _openListing(context, listing),
      child: Container(
        decoration: SwabbitTheme.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Immagine / placeholder ──
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  listing.images.isNotEmpty
                      ? Image.network(
                          listing.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholderThumb(listing),
                        )
                      : _placeholderThumb(listing),
                  // Badge condizione
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: listing.condition.color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        listing.condition.label,
                        style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.black),
                      ),
                    ),
                  ),
                  // Sconto se presente
                  if (listing.originalPrice != null &&
                      listing.originalPrice! > listing.price)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: SwabbitTheme.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '−${((1 - listing.price / listing.originalPrice!) * 100).round()}%',
                          style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.black),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── Info ──
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: SwabbitTheme.text),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '€ ${listing.price.toStringAsFixed(listing.price.truncateToDouble() == listing.price ? 0 : 2)}',
                        style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: SwabbitTheme.accent),
                      ),
                      if (listing.originalPrice != null &&
                          listing.originalPrice! > listing.price) ...[
                        const SizedBox(width: 5),
                        Text(
                          '€ ${listing.originalPrice!.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 10,
                              color: SwabbitTheme.text3,
                              decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined,
                          size: 11, color: SwabbitTheme.text3),
                      const SizedBox(width: 3),
                      Text(
                        '${listing.views}',
                        style: const TextStyle(
                            fontSize: 10, color: SwabbitTheme.text3),
                      ),
                      const Spacer(),
                      if (listing.location.isNotEmpty)
                        Flexible(
                          child: Text(
                            listing.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, color: SwabbitTheme.text3),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderThumb(Listing listing) {
    return Container(
      color: SwabbitTheme.surface2,
      child: Center(
        child: Text(
          listing.categoryEmoji,
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}

// ── ICON BUTTON ───────────────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: SwabbitTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SwabbitTheme.border),
        ),
        child: Icon(icon, size: 20, color: SwabbitTheme.text2),
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
                        color: listing.condition.color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        listing.condition.label,
                        style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.black),
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
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: SwabbitTheme.text),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '€ ${listing.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SwabbitTheme.accent),
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.visibility_outlined,
                        size: 11, color: SwabbitTheme.text3),
                    const SizedBox(width: 3),
                    Text('${listing.views}',
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

  static Widget _placeholder(Listing listing) {
    return Container(
      color: SwabbitTheme.surface2,
      child: Center(
        child:
            Text(listing.categoryEmoji, style: const TextStyle(fontSize: 32)),
      ),
    );
  }
}