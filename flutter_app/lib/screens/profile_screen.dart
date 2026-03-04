// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import '../main.dart';
import '../models/listing.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import 'listing_screen.dart';

class ProfileScreen extends StatefulWidget {
  // Notifier passato da MainScaffold: si incrementa ogni volta che si tappa
  // sul tab Profilo → la screen ricarica profilo e annunci automaticamente.
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
  bool _profileLoading = true;
  bool _listingsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadProfile();
    _loadListings();

    // Ascolta il notifier del MainScaffold
    widget.refreshNotifier?.addListener(_onExternalRefresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onExternalRefresh);
    _tabController.dispose();
    super.dispose();
  }

  // Chiamato ogni volta che si tappa sul tab Profilo
  void _onExternalRefresh() {
    _refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([_loadProfile(), _loadListings()]);
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: _profile!),
      ),
    );
    // Ricarica SEMPRE al ritorno, indipendentemente dal valore di pop
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
          Row(children: [
            GestureDetector(
              onTap: _openEditProfile,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SwabbitTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SwabbitTheme.border),
                ),
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
                  color: SwabbitTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SwabbitTheme.border),
                ),
                child: const Icon(Icons.logout_rounded,
                    size: 18, color: SwabbitTheme.text2),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: GestureDetector(
        onTap: _openEditProfile,
        child: Stack(children: [
          Container(
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
                  ? Image.network(
                      _avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initialsWidget(),
                    )
                  : _initialsWidget(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: SwabbitTheme.accent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SwabbitTheme.bg, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 12, color: Colors.black),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _initialsWidget() => Center(
        child: Text(
          _initials.isEmpty ? '?' : _initials,
          style: const TextStyle(
              fontFamily: 'Syne',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black),
        ),
      );

  Widget _buildNameSection() {
    return Column(children: [
      Text(_displayName,
          style: const TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: SwabbitTheme.text)),
      if (_username.isNotEmpty)
        Text('@$_username',
            style:
                const TextStyle(fontSize: 13, color: SwabbitTheme.text3)),
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
    ]);
  }

  Widget _buildStats() {
    final rating = (_profile?['rating'] as num?)?.toDouble() ?? 5.0;
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
            value: rating.toStringAsFixed(1),
            label: 'RATING',
            color: SwabbitTheme.yellow),
      ]),
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
                child: Text(tabs[i],
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: active
                          ? SwabbitTheme.accent
                          : SwabbitTheme.text2,
                    )),
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
          child:
              CircularProgressIndicator(color: SwabbitTheme.accent));
    }
    if (_listings.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 80),
        Center(
          child: Column(children: [
            Text('📦', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Nessun annuncio',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: SwabbitTheme.text)),
            SizedBox(height: 6),
            Text('Pubblica il tuo primo annuncio!',
                style: TextStyle(
                    fontSize: 13, color: SwabbitTheme.text2)),
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
                      style: const TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: SwabbitTheme.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('€ ${listing.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: SwabbitTheme.accent)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            listing.status.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: listing.status.color
                                .withOpacity(0.3)),
                      ),
                      child: Text(listing.status.label,
                          style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: listing.status.color)),
                    ),
                    const SizedBox(width: 6),
                    Text('${listing.views} views',
                        style: const TextStyle(
                            fontSize: 11,
                            color: SwabbitTheme.text3)),
                  ]),
                ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: SwabbitTheme.text3, size: 18),
        ]),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('⭐', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Nessuna recensione',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: SwabbitTheme.text)),
          SizedBox(height: 6),
          Text('Le recensioni appariranno dopo le prime transazioni.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: SwabbitTheme.text2)),
        ]),
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
          _infoRow(Icons.phone_outlined, 'Telefono',
              _profile!['telefono']),
        if (_profile?['luogo'] != null &&
            (_profile!['luogo'] as String).isNotEmpty)
          _infoRow(Icons.location_on_outlined, 'Luogo',
              _profile!['luogo']),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: SwabbitTheme.cardDecoration(),
        child: Row(children: [
          Icon(icon, size: 18, color: SwabbitTheme.text3),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: SwabbitTheme.text3,
                    letterSpacing: 0.5,
                    fontFamily: 'SpaceMono')),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    color: SwabbitTheme.text,
                    fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}

// ── HELPER WIDGETS ────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBox(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
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