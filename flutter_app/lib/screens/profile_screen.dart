// lib/screens/profile_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/listing.dart';
import '../models/review.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import 'listing_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;
  const ProfileScreen({super.key, this.refreshNotifier});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profile;
  List<Listing> _listings = [];
  List<Review> _reviews = [];
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
    widget.refreshNotifier?.addListener(_onExternalRefresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onExternalRefresh);
    _reviewsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onExternalRefresh() => _refresh();

  Future<void> _refresh() async {
    await Future.wait([_loadProfile(), _loadListings(), _loadReviews()]);
  }

  Future<void> _loadProfile() async {
    setState(() => _profileLoading = true);
    try {
      final p = await SupabaseService.getProfile();
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
    if (mounted) setState(() => _profileLoading = false);
  }

  Future<void> _loadListings() async {
    setState(() => _listingsLoading = true);
    try {
      final lst = await SupabaseService.getMyListings();
      if (mounted) setState(() => _listings = lst);
    } catch (_) {}
    if (mounted) setState(() => _listingsLoading = false);
  }

  Future<void> _loadReviews() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _reviewsLoading = false);
      return;
    }
    if (mounted) setState(() => _reviewsLoading = true);
    try {
      final reviews = await SupabaseService.getReviews(userId);
      if (mounted) setState(() => _reviews = reviews);
      // Sottoscrivi lo stream una sola volta
      _reviewsSub ??= SupabaseService.reviewsStream(userId).listen(
        (_) => _loadReviews(),
        onError: (_) {},
      );
    } catch (_) {}
    if (mounted) setState(() => _reviewsLoading = false);
  }

  // ── LOGOUT ────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SwabbitTheme.surface,
        title: const Text('Logout',
            style: TextStyle(
                fontFamily: 'Syne',
                color: SwabbitTheme.text,
                fontWeight: FontWeight.w700)),
        content: const Text('Vuoi uscire dall\'account?',
            style: TextStyle(color: SwabbitTheme.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla',
                style: TextStyle(color: SwabbitTheme.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Esci',
                style: TextStyle(color: SwabbitTheme.accent3)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _reviewsSub?.cancel();
      await SupabaseService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _openEditProfile() async {
    if (_profile == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile!)),
    );
    await _refresh();
  }

  Future<void> _openListing(Listing listing) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ListingScreen(listing: listing)),
    );
    if (deleted == true) await _loadListings();
  }

  // ── GETTERS ───────────────────────────────────────────────────────────────

  String get _displayName {
    if (_profile == null) return 'Utente';
    final nome = _profile!['nome'] ?? '';
    final cognome = _profile!['cognome'] ?? '';
    return '$nome $cognome'.trim();
  }

  String get _username => _profile?['username'] ?? '';

  String get _initials {
    final nome = _profile?['nome'] ?? '';
    final cognome = _profile?['cognome'] ?? '';
    final n = nome.isNotEmpty ? nome[0].toUpperCase() : '';
    final c = cognome.isNotEmpty ? cognome[0].toUpperCase() : '';
    return '$n$c';
  }

  String? get _avatarUrl => _profile?['avatar_url']?.toString();

  int get _activeListings =>
      _listings.where((l) => l.status == ListingStatus.active).length;
  int get _soldListings =>
      _listings.where((l) => l.status == ListingStatus.sold).length;
  double get _rating => (_profile?['rating'] as num?)?.toDouble() ?? 5.0;

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: SafeArea(
        child: _profileLoading
            ? const Center(
                child: CircularProgressIndicator(color: SwabbitTheme.accent))
            : RefreshIndicator(
                color: SwabbitTheme.accent,
                backgroundColor: SwabbitTheme.surface,
                onRefresh: _refresh,
                child: NestedScrollView(
                  headerSliverBuilder: (context, _) => [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildHeader(),
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
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Text('Il tuo profilo',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: SwabbitTheme.text)),
          const Spacer(),
          GestureDetector(
            onTap: _openEditProfile,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: SwabbitTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SwabbitTheme.border)),
              child: const Icon(Icons.edit_outlined,
                  size: 18, color: SwabbitTheme.text2),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: SwabbitTheme.accent3.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: SwabbitTheme.accent3.withOpacity(0.3))),
              child: const Icon(Icons.logout_rounded,
                  size: 18, color: SwabbitTheme.accent3),
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
      child: GestureDetector(
        onTap: _openEditProfile,
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
              style: const TextStyle(fontSize: 13, color: SwabbitTheme.text3)),
        ],
        if (_profile?['bio'] != null &&
            (_profile!['bio'] as String).isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _profile!['bio'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: SwabbitTheme.text2, height: 1.4),
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
      child: Row(children: [
        _StatBox(
            value: _activeListings.toString(),
            label: 'ATTIVI',
            color: SwabbitTheme.accent),
        const SizedBox(width: 10),
        _StatBox(
            value: _soldListings.toString(),
            label: 'VENDUTI',
            color: SwabbitTheme.green),
        const SizedBox(width: 10),
        _StatBox(
            value: _rating.toStringAsFixed(1),
            label: 'RATING',
            color: SwabbitTheme.yellow),
      ]),
    );
  }

  // ── TAB BAR ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    final tabs = ['Annunci', 'Recensioni', 'Su di me'];
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
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
                child: Row(children: [
                  Text(tabs[i],
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: active
                            ? SwabbitTheme.accent
                            : SwabbitTheme.text2,
                      )),
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
                ]),
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
        SizedBox(height: 60),
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('📦', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Nessun annuncio',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: SwabbitTheme.text)),
          ]),
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
      onTap: () => _openListing(listing),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: SwabbitTheme.cardDecoration(),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: SwabbitTheme.surface2,
              borderRadius: BorderRadius.circular(10),
              image: listing.images.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(listing.images.first),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: listing.images.isEmpty
                ? Center(
                    child: Text(listing.categoryEmoji,
                        style: const TextStyle(fontSize: 24)))
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
                const SizedBox(height: 3),
                Text('€ ${listing.price.toStringAsFixed(0)}',
                    style: SwabbitTheme.monoStyle
                        .copyWith(fontSize: 13, color: SwabbitTheme.accent)),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: listing.status.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(listing.status.label,
                        style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: listing.status.color)),
                  ),
                  const Spacer(),
                  const Icon(Icons.visibility_outlined,
                      size: 11, color: SwabbitTheme.text3),
                  const SizedBox(width: 3),
                  Text('${listing.views} views',
                      style: const TextStyle(
                          fontSize: 11, color: SwabbitTheme.text3)),
                ]),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: SwabbitTheme.text3, size: 18),
        ]),
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
        if (_reviews.isNotEmpty) ...[
          _buildRatingSummary(),
          const SizedBox(height: 16),
        ],
        if (_reviews.isEmpty)
          _buildNoReviews()
        else
          ..._reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }

  Widget _buildRatingSummary() {
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
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = counts[i];
                final pct =
                    _reviews.isNotEmpty ? count / _reviews.length : 0.0;
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

  Widget _buildNoReviews() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text('⭐', style: TextStyle(fontSize: 44)),
          SizedBox(height: 12),
          Text('Nessuna recensione',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: SwabbitTheme.text)),
          SizedBox(height: 6),
          Text('Le recensioni appariranno dopo le prime transazioni.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: SwabbitTheme.text2)),
        ],
      ),
    );
  }

  // ── TAB: SU DI ME ─────────────────────────────────────────────────────────

  Widget _buildAboutTab() {
    final user = SupabaseService.currentUser;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _infoRow(Icons.email_outlined, 'Email', user?.email ?? '—'),
        if (_profile?['telefono'] != null &&
            (_profile!['telefono'] as String).isNotEmpty)
          _infoRow(Icons.phone_outlined, 'Telefono',
              _profile!['telefono'] as String),
        if (_profile?['luogo'] != null &&
            (_profile!['luogo'] as String).isNotEmpty)
          _infoRow(Icons.location_on_outlined, 'Luogo',
              _profile!['luogo'] as String),
        if (_profile?['bio'] != null &&
            (_profile!['bio'] as String).isNotEmpty)
          _infoRow(Icons.info_outline_rounded, 'Bio',
              _profile!['bio'] as String),
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
        child: Column(children: [
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
        ]),
      ),
    );
  }
}

// ── REVIEW CARD (sola lettura, per profilo proprio) ───────────────────────────

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final name = review.reviewerName ?? 'Utente';
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: SwabbitTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
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
                          errorBuilder: (_, __, ___) => _ini(initials)))
                  : _ini(initials),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: SwabbitTheme.text)),
                  const SizedBox(height: 2),
                  Row(children: [
                    ...List.generate(
                      5,
                      (i) => Icon(Icons.star_rounded,
                          size: 13,
                          color: i < review.rating
                              ? SwabbitTheme.yellow
                              : SwabbitTheme.border),
                    ),
                    const SizedBox(width: 6),
                    Text(
                        '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                        style: const TextStyle(
                            fontSize: 10, color: SwabbitTheme.text3)),
                  ]),
                ],
              ),
            ),
          ]),
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

  static Widget _ini(String i) => Center(
        child: Text(i.isEmpty ? '?' : i,
            style: const TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Colors.black)),
      );
}