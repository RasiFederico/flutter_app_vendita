import 'package:flutter/material.dart';
import '../main.dart';
import '../models/listing.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import 'listing_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profile;
  List<Listing> _listings = [];
  bool _profileLoading = true;
  bool _listingsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadProfile();
    _loadListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: _profile!),
      ),
    );
    if (updated == true) await _loadProfile();
  }

  Future<void> _openListing(Listing listing) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ListingScreen(listing: listing)),
    );
    if (deleted == true) await _loadListings();
  }

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

  int get _activeListings =>
      _listings.where((l) => l.status == ListingStatus.active).length;
  int get _soldListings =>
      _listings.where((l) => l.status == ListingStatus.sold).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: SafeArea(
        child: _profileLoading
            ? const Center(
                child: CircularProgressIndicator(color: SwabbitTheme.accent))
            : Column(
                children: [
                  Expanded(
                    child: NestedScrollView(
                      headerSliverBuilder: (context, innerBoxScrolled) => [
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
                ],
              ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Profilo',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: SwabbitTheme.text)),
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SwabbitTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SwabbitTheme.border),
              ),
              child: const Icon(Icons.logout_rounded,
                  size: 18, color: SwabbitTheme.text2),
            ),
          ),
        ],
      ),
    );
  }

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
        child: Center(
          child: Text(_initials,
              style: const TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black)),
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      children: [
        Text(_displayName,
            style: const TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: SwabbitTheme.text)),
        if (_username.isNotEmpty)
          Text('@$_username',
              style: const TextStyle(
                  fontSize: 13, color: SwabbitTheme.text3)),
        if (_profile?['bio'] != null &&
            (_profile!['bio'] as String).isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: SwabbitTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SwabbitTheme.border),
              ),
              child: Text(_profile!['bio'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      color: SwabbitTheme.text2,
                      height: 1.4)),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openEditProfile,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Modifica profilo',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: SwabbitTheme.text,
                side: const BorderSide(color: SwabbitTheme.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatCard(
              value: '$_activeListings',
              label: 'ANNUNCI',
              color: SwabbitTheme.accent),
          const SizedBox(width: 10),
          _StatCard(
              value: '$_soldListings',
              label: 'VENDITE',
              color: SwabbitTheme.green),
          const SizedBox(width: 10),
          _StatCard(
              value: _profile?['rating']?.toString() ?? '—',
              label: 'RATING',
              color: SwabbitTheme.yellow),
        ],
      ),
    );
  }

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
                child: Text(
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
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── TABS ──────────────────────────────────────────────────────────────────

  Widget _buildListingsTab() {
    if (_listingsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: SwabbitTheme.accent));
    }
    if (_listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📦', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Nessun annuncio',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: SwabbitTheme.text)),
            const SizedBox(height: 6),
            const Text('Pubblica il tuo primo annuncio!',
                style: TextStyle(
                    fontSize: 13, color: SwabbitTheme.text2)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: SwabbitTheme.accent,
      onRefresh: _loadListings,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: _listings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _buildListingCard(_listings[i]),
      ),
    );
  }

  Widget _buildListingCard(Listing listing) {
    return GestureDetector(
      onTap: () => _openListing(listing),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: SwabbitTheme.cardDecoration(),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: SwabbitTheme.surface2,
                borderRadius: BorderRadius.circular(12),
                image: listing.images.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(listing.images.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: listing.images.isEmpty
                  ? Center(
                      child: Text(listing.categoryEmoji,
                          style: const TextStyle(fontSize: 26)))
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
                          fontSize: 14,
                          color: SwabbitTheme.text)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('€ ${listing.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontFamily: 'Syne',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: SwabbitTheme.accent)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              listing.status.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color:
                                  listing.status.color.withOpacity(0.3)),
                        ),
                        child: Text(listing.status.label,
                            style: TextStyle(
                                color: listing.status.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined,
                          size: 12, color: SwabbitTheme.text3),
                      const SizedBox(width: 3),
                      Text('${listing.views}',
                          style: const TextStyle(
                              fontSize: 11, color: SwabbitTheme.text3)),
                      const SizedBox(width: 10),
                      const Icon(Icons.favorite_outline,
                          size: 12, color: SwabbitTheme.text3),
                      const SizedBox(width: 3),
                      Text('${listing.likes}',
                          style: const TextStyle(
                              fontSize: 11, color: SwabbitTheme.text3)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: SwabbitTheme.text3, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _buildReviewCard(),
        const SizedBox(height: 10),
        _buildReviewCard(),
      ],
    );
  }

  Widget _buildReviewCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: SwabbitTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: SwabbitTheme.surface3,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                    child: Text('A',
                        style: TextStyle(
                            fontFamily: 'Syne',
                            fontWeight: FontWeight.w700,
                            color: SwabbitTheme.text))),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Acquirente',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: SwabbitTheme.text,
                          fontSize: 13)),
                  Row(
                    children: List.generate(
                        5,
                        (j) => const Text('★',
                            style: TextStyle(
                                color: SwabbitTheme.yellow,
                                fontSize: 11))),
                  ),
                ],
              ),
              const Spacer(),
              const Text('2 giorni fa',
                  style: TextStyle(
                      fontSize: 11, color: SwabbitTheme.text3)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
              'Venditore affidabile, prodotto perfettamente imballato. Spedizione veloce!',
              style: TextStyle(
                  fontSize: 13,
                  color: SwabbitTheme.text2,
                  height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    final user = SupabaseService.currentUser;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _infoRow(Icons.email_outlined, 'Email', user?.email ?? '—'),
        if (_profile?['telefono'] != null &&
            (_profile!['telefono'] as String).isNotEmpty)
          _infoRow(
              Icons.phone_outlined, 'Telefono', _profile!['telefono']),
        if (_profile?['luogo'] != null &&
            (_profile!['luogo'] as String).isNotEmpty)
          _infoRow(Icons.location_on_outlined, 'Luogo', _profile!['luogo']),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: SwabbitTheme.cardDecoration(),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SwabbitTheme.accent),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: SwabbitTheme.text3)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: SwabbitTheme.text)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
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
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: SwabbitTheme.text3)),
          ],
        ),
      ),
    );
  }
}