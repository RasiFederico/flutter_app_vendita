// lib/screens/user_profile_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/listing.dart';
import '../models/review.dart';
import '../services/supabase_service.dart';
import 'listing_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? initialName;
  final String? initialUsername;
  final String? initialAvatarUrl;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialName,
    this.initialUsername,
    this.initialAvatarUrl,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profile;
  List<Listing> _listings = [];
  List<Review> _reviews = [];
  Review? _myReview;             // eventuale recensione già lasciata
  bool _profileLoading = true;
  bool _listingsLoading = true;
  bool _reviewsLoading = true;

  StreamSubscription<List<Map<String, dynamic>>>? _reviewsSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadProfile();
    _loadListings();
    _loadReviews();
    _subscribeReviews();
  }

  @override
  void dispose() {
    _reviewsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([_loadProfile(), _loadListings(), _loadReviews()]);
  }

  Future<void> _loadProfile() async {
    setState(() => _profileLoading = true);
    try {
      final p = await SupabaseService.getUserProfileById(widget.userId);
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
    if (mounted) setState(() => _profileLoading = false);
  }

  Future<void> _loadListings() async {
    setState(() => _listingsLoading = true);
    try {
      final lst = await SupabaseService.getUserListings(widget.userId);
      if (mounted) setState(() => _listings = lst);
    } catch (_) {}
    if (mounted) setState(() => _listingsLoading = false);
  }

  Future<void> _loadReviews() async {
    if (mounted) setState(() => _reviewsLoading = true);
    try {
      final reviews = await SupabaseService.getReviews(widget.userId);
      final myR = await SupabaseService.getMyReviewFor(widget.userId);
      if (mounted) setState(() {
        _reviews = reviews;
        _myReview = myR;
      });
    } catch (_) {}
    if (mounted) setState(() => _reviewsLoading = false);
  }

  void _subscribeReviews() {
    _reviewsSub = SupabaseService.reviewsStream(widget.userId).listen(
      (_) => _loadReviews(),
      onError: (_) {},
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  String get _displayName {
    if (_profile != null) {
      final nome = (_profile!['nome'] as String? ?? '').trim();
      final cognome = (_profile!['cognome'] as String? ?? '').trim();
      final full = '$nome $cognome'.trim();
      if (full.isNotEmpty) return full;
      final u = (_profile!['username'] as String? ?? '').trim();
      if (u.isNotEmpty) return u;
    }
    if (widget.initialName?.isNotEmpty == true) return widget.initialName!;
    if (widget.initialUsername?.isNotEmpty == true) return widget.initialUsername!;
    return 'Utente';
  }

  String get _username {
    final u = (_profile?['username'] as String? ?? '').trim();
    return u.isNotEmpty ? u : (widget.initialUsername ?? '').trim();
  }

  String? get _avatarUrl {
    final url = (_profile?['avatar_url'] as String? ?? '').trim();
    if (url.isNotEmpty) return url;
    final init = (widget.initialAvatarUrl ?? '').trim();
    return init.isNotEmpty ? init : null;
  }

  String get _initials {
    final parts = _displayName.trim().split(' ');
    final first = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return ('$first$second').toUpperCase();
  }

  double get _rating => (_profile?['rating'] as num?)?.toDouble() ?? 5.0;
  int get _salesCount => (_profile?['sales_count'] as num?)?.toInt() ?? 0;

  bool get _isOwnProfile =>
      SupabaseService.currentUser?.id == widget.userId;

  // ── REVIEW DIALOG ─────────────────────────────────────────────────────────

  Future<void> _openReviewDialog() async {
    int selectedStars = _myReview?.rating ?? 5;
    final descCtrl = TextEditingController(text: _myReview?.description ?? '');

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: SwabbitTheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SwabbitTheme.radius)),
          title: Text(
            _myReview == null ? 'Lascia una recensione' : 'Modifica recensione',
            style: const TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: SwabbitTheme.text),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stelle
                const Text('Valutazione',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SwabbitTheme.text2)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedStars = star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          star <= selectedStars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 36,
                          color: star <= selectedStars
                              ? SwabbitTheme.yellow
                              : SwabbitTheme.border,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                // Descrizione
                const Text('Descrizione (opzionale)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SwabbitTheme.text2)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: SwabbitTheme.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SwabbitTheme.border),
                  ),
                  child: TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    maxLength: 300,
                    style: const TextStyle(
                        color: SwabbitTheme.text, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Descrivi la tua esperienza...',
                      hintStyle: TextStyle(
                          color: SwabbitTheme.text3, fontSize: 13),
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                      counterStyle: TextStyle(color: SwabbitTheme.text3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Elimina (solo se esiste già una recensione)
            if (_myReview != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Elimina',
                    style: TextStyle(
                        color: SwabbitTheme.accent3,
                        fontWeight: FontWeight.w600)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla',
                  style: TextStyle(color: SwabbitTheme.text2)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Pubblica',
                  style: TextStyle(
                      color: SwabbitTheme.accent,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (submitted == null && _myReview != null) {
      // Elimina
      try {
        await SupabaseService.deleteReview(_myReview!.id);
        if (mounted) _snack('Recensione eliminata');
      } catch (e) {
        if (mounted) _snack('Errore: $e', error: true);
      }
    } else if (submitted == true) {
      try {
        await SupabaseService.submitReview(
          reviewedId: widget.userId,
          rating: selectedStars,
          description: descCtrl.text,
        );
        if (mounted) {
          _snack(_myReview == null
              ? 'Recensione pubblicata!'
              : 'Recensione aggiornata!');
        }
      } catch (e) {
        if (mounted) _snack('Errore: $e', error: true);
      }
    }
    descCtrl.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? SwabbitTheme.accent3 : SwabbitTheme.green,
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: RefreshIndicator(
                color: SwabbitTheme.accent,
                backgroundColor: SwabbitTheme.surface,
                onRefresh: _refresh,
                child: _profileLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: SwabbitTheme.accent))
                    : NestedScrollView(
                        headerSliverBuilder: (ctx, _) => [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                _buildAvatar(),
                                const SizedBox(height: 12),
                                _buildNameSection(),
                                const SizedBox(height: 16),
                                _buildStats(),
                                _buildTabBar(),
                              ],
                            ),
                          ),
                        ],
                        body: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildListingsTab(),
                            _buildReviewsTab(),
                            _buildAboutTab(),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SwabbitTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SwabbitTheme.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: SwabbitTheme.text),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Profilo venditore',
            style: TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: SwabbitTheme.text),
          ),
          const Spacer(),
          // Bottone "Recensisci" (non sul proprio profilo, solo se loggato)
          if (!_isOwnProfile && SupabaseService.currentUser != null)
            GestureDetector(
              onTap: _openReviewDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _myReview != null
                      ? SwabbitTheme.yellow.withOpacity(0.15)
                      : SwabbitTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _myReview != null
                          ? SwabbitTheme.yellow.withOpacity(0.4)
                          : SwabbitTheme.accent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _myReview != null
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 15,
                      color: _myReview != null
                          ? SwabbitTheme.yellow
                          : SwabbitTheme.accent,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _myReview != null ? 'La tua rec.' : 'Recensisci',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: _myReview != null
                              ? SwabbitTheme.yellow
                              : SwabbitTheme.accent),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── AVATAR ────────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: SwabbitTheme.accentGrad,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: SwabbitTheme.accent.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _avatarUrl != null
              ? Image.network(_avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initialsWidget())
              : _initialsWidget(),
        ),
      ),
    );
  }

  Widget _initialsWidget() => Center(
        child: Text(
          _initials.isEmpty ? '?' : _initials,
          style: const TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w800,
              fontSize: 28,
              color: Colors.black),
        ),
      );

  // ── NAME SECTION ──────────────────────────────────────────────────────────

  Widget _buildNameSection() {
    return Column(
      children: [
        Text(_displayName,
            style: const TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: SwabbitTheme.text)),
        if (_username.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('@$_username',
              style: const TextStyle(
                  fontSize: 13, color: SwabbitTheme.text3)),
        ],
        if (_profile?['bio'] != null &&
            (_profile!['bio'] as String).isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: SwabbitTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SwabbitTheme.border),
              ),
              child: Text(
                _profile!['bio'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    color: SwabbitTheme.text2,
                    height: 1.4),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── STATS ─────────────────────────────────────────────────────────────────

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatBox(
              value: _listings.length.toString(),
              label: 'ANNUNCI',
              color: SwabbitTheme.accent),
          const SizedBox(width: 10),
          _StatBox(
              value: _salesCount.toString(),
              label: 'VENDITE',
              color: SwabbitTheme.green),
          const SizedBox(width: 10),
          _StatBox(
              value: _rating.toStringAsFixed(1),
              label: 'RATING',
              color: SwabbitTheme.yellow),
        ],
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    final tabs = ['Annunci', 'Recensioni', 'Info'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: SwabbitTheme.border, width: 1)),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final active = _tabController.index == i;
            return GestureDetector(
              onTap: () => _tabController.animateTo(i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 12),
                margin: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active
                          ? SwabbitTheme.accent
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      tabs[i],
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: active
                            ? SwabbitTheme.accent
                            : SwabbitTheme.text2,
                      ),
                    ),
                    // Badge conteggio recensioni
                    if (i == 1 && _reviews.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: SwabbitTheme.yellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${_reviews.length}',
                            style: const TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: SwabbitTheme.yellow)),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── TAB: ANNUNCI ──────────────────────────────────────────────────────────

  Widget _buildListingsTab() {
    if (_listingsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: SwabbitTheme.accent));
    }
    if (_listings.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Text('📦', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('Nessun annuncio attivo',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: SwabbitTheme.text)),
            ],
          ),
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: _listings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _buildListingCard(_listings[i]),
    );
  }

  Widget _buildListingCard(Listing listing) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ListingScreen(listing: listing))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: SwabbitTheme.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: SwabbitTheme.surface2,
                borderRadius: BorderRadius.circular(12),
                image: listing.images.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(listing.images.first),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: listing.images.isEmpty
                  ? Center(
                      child: Text(listing.categoryEmoji,
                          style: const TextStyle(fontSize: 28)))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: SwabbitTheme.text)),
                  const SizedBox(height: 4),
                  Text('€ ${listing.price.toStringAsFixed(0)}',
                      style: SwabbitTheme.monoStyle
                          .copyWith(fontSize: 14, color: SwabbitTheme.accent)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: SwabbitTheme.text3),
                      const SizedBox(width: 2),
                      Text(listing.location,
                          style: const TextStyle(
                              fontSize: 11, color: SwabbitTheme.text3)),
                      const Spacer(),
                      const Icon(Icons.visibility_outlined,
                          size: 11, color: SwabbitTheme.text3),
                      const SizedBox(width: 2),
                      Text('${listing.views}',
                          style: const TextStyle(
                              fontSize: 11, color: SwabbitTheme.text3)),
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

  // ── TAB: RECENSIONI ───────────────────────────────────────────────────────

  Widget _buildReviewsTab() {
    if (_reviewsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: SwabbitTheme.accent));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        // Rating summary card
        _buildRatingSummary(),
        const SizedBox(height: 16),

        // CTA per lasciare recensione
        if (!_isOwnProfile && SupabaseService.currentUser != null)
          _buildReviewCta(),

        // Lista recensioni
        if (_reviews.isEmpty)
          _buildNoReviews()
        else
          ..._reviews.map((r) => _ReviewCard(
                review: r,
                isOwn: r.reviewerId == SupabaseService.currentUser?.id,
                onEdit: r.reviewerId == SupabaseService.currentUser?.id
                    ? _openReviewDialog
                    : null,
              )),
      ],
    );
  }

  Widget _buildRatingSummary() {
    if (_reviews.isEmpty) return const SizedBox.shrink();
    final avg = _reviews.fold(0, (s, r) => s + r.rating) / _reviews.length;
    final counts = List.generate(5, (i) {
      final star = 5 - i;
      return _reviews.where((r) => r.rating == star).length;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SwabbitTheme.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Numero grande
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w800,
                    fontSize: 40,
                    color: SwabbitTheme.text),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(Icons.star_rounded,
                        size: 14,
                        color: i < avg.round()
                            ? SwabbitTheme.yellow
                            : SwabbitTheme.border)),
              ),
              const SizedBox(height: 4),
              Text('${_reviews.length} recens.',
                  style: const TextStyle(
                      fontSize: 11, color: SwabbitTheme.text3)),
            ],
          ),
          const SizedBox(width: 20),
          // Barre per stelle
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = counts[i];
                final pct = _reviews.isNotEmpty ? count / _reviews.length : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Text('$star',
                        style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 11,
                            color: SwabbitTheme.text3)),
                    const SizedBox(width: 6),
                    const Icon(Icons.star_rounded,
                        size: 11, color: SwabbitTheme.yellow),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: SwabbitTheme.surface2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              SwabbitTheme.yellow),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 18,
                      child: Text('$count',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 11,
                              color: SwabbitTheme.text3)),
                    ),
                  ]),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCta() {
    return GestureDetector(
      onTap: _openReviewDialog,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SwabbitTheme.accent.withOpacity(0.07),
          borderRadius: BorderRadius.circular(SwabbitTheme.radius),
          border: Border.all(color: SwabbitTheme.accent.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.rate_review_outlined,
                color: SwabbitTheme.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _myReview == null
                    ? 'Hai avuto un\'esperienza con questo venditore? Lascia una recensione!'
                    : 'Hai già lasciato una recensione. Tocca per modificarla.',
                style: const TextStyle(
                    fontSize: 13,
                    color: SwabbitTheme.text2,
                    height: 1.4),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: SwabbitTheme.accent, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildNoReviews() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          const Text('Nessuna recensione',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: SwabbitTheme.text)),
          const SizedBox(height: 6),
          const Text('Le recensioni appariranno qui.',
              style: TextStyle(fontSize: 13, color: SwabbitTheme.text2)),
        ],
      ),
    );
  }

  // ── TAB: INFO ─────────────────────────────────────────────────────────────

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        if (_profile?['luogo'] != null &&
            (_profile!['luogo'] as String).isNotEmpty)
          _infoRow(Icons.location_on_outlined, 'Luogo', _profile!['luogo']),
        if (_profile?['bio'] != null &&
            (_profile!['bio'] as String).isNotEmpty)
          _infoRow(
              Icons.info_outline_rounded, 'Bio', _profile!['bio']),
        _infoRow(
          Icons.calendar_today_outlined,
          'Membro dal',
          _profile?['created_at'] != null
              ? _formatDate(_profile!['created_at'] as String)
              : '—',
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: SwabbitTheme.cardDecoration(),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: SwabbitTheme.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: SwabbitTheme.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 9,
                        color: SwabbitTheme.text3,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        color: SwabbitTheme.text,
                        fontWeight: FontWeight.w500)),
              ]),
        ),
      ]),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '—';
    }
  }
}

// ── STAT BOX ──────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBox(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: SwabbitTheme.text3,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── REVIEW CARD ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final Review review;
  final bool isOwn;
  final VoidCallback? onEdit;

  const _ReviewCard(
      {required this.review, required this.isOwn, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final name = review.reviewerName ?? 'Utente';
    final initials =
        name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOwn
            ? SwabbitTheme.yellow.withOpacity(0.05)
            : SwabbitTheme.surface,
        borderRadius: BorderRadius.circular(SwabbitTheme.radius),
        border: Border.all(
            color: isOwn
                ? SwabbitTheme.yellow.withOpacity(0.3)
                : SwabbitTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + nome + stelle + eventuale pulsante modifica
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: SwabbitTheme.accentGrad,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: review.reviewerAvatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(review.reviewerAvatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _initialsWidget(initials)),
                      )
                    : _initialsWidget(initials),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontFamily: 'Syne',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: SwabbitTheme.text)),
                        if (isOwn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: SwabbitTheme.yellow.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Tu',
                                style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: SwabbitTheme.yellow)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(Icons.star_rounded,
                              size: 13,
                              color: i < review.rating
                                  ? SwabbitTheme.yellow
                                  : SwabbitTheme.border),
                        ),
                        const SizedBox(width: 6),
                        Text(_formatDate(review.createdAt),
                            style: const TextStyle(
                                fontSize: 10,
                                color: SwabbitTheme.text3)),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwn && onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: SwabbitTheme.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SwabbitTheme.border),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 14, color: SwabbitTheme.text2),
                  ),
                ),
            ],
          ),
          // Descrizione
          if (review.description != null &&
              review.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.description!,
                style: const TextStyle(
                    fontSize: 13,
                    color: SwabbitTheme.text2,
                    height: 1.5)),
          ],
        ],
      ),
    );
  }

  static Widget _initialsWidget(String initials) => Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: const TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.black),
        ),
      );

  static String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}