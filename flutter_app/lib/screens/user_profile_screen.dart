import 'package:flutter/material.dart';
import '../main.dart';
import '../models/listing.dart';
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

  Future<void> _refresh() async {
    await Future.wait([_loadProfile(), _loadListings()]);
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

  // ── HELPERS ───────────────────────────────────────────────────────────────

  String get _displayName {
    if (_profile != null) {
      final nome = _profile!['nome'] ?? '';
      final cognome = _profile!['cognome'] ?? '';
      final full = '$nome $cognome'.trim();
      if (full.isNotEmpty) return full;
    }
    return widget.initialName?.isNotEmpty == true
        ? widget.initialName!
        : 'Utente';
  }

  String get _username {
    final u = _profile?['username'] ?? widget.initialUsername ?? '';
    return u.toString();
  }

  String? get _avatarUrl {
    final url = _profile?['avatar_url'] ?? widget.initialAvatarUrl;
    return url?.toString();
  }

  String get _initials {
    final parts = _displayName.trim().split(' ');
    final first = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return ('$first$second').toUpperCase();
  }

  double get _rating =>
      (_profile?['rating'] as num?)?.toDouble() ?? 5.0;

  int get _salesCount =>
      (_profile?['sales_count'] as num?)?.toInt() ?? 0;

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
    );
  }

  Widget _initialsWidget() {
    return Center(
      child: Text(
        _initials.isEmpty ? '?' : _initials,
        style: const TextStyle(
            fontFamily: 'Syne',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black),
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
        if (_username.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text('@$_username',
              style: const TextStyle(fontSize: 13, color: SwabbitTheme.text3)),
        ],
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
      ],
    );
  }

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
      return ListView(
        children: const [
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
        ],
      );
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ListingScreen(listing: listing)),
      ),
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
                      style: SwabbitTheme.monoStyle.copyWith(
                          fontSize: 14, color: SwabbitTheme.accent)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 11, color: SwabbitTheme.text3),
                      const SizedBox(width: 2),
                      Text(listing.location,
                          style: const TextStyle(
                              fontSize: 11, color: SwabbitTheme.text3)),
                      const Spacer(),
                      Icon(Icons.visibility_outlined,
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

  Widget _buildReviewsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        // Rating summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: SwabbitTheme.cardDecoration(),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    _rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w800,
                        fontSize: 40,
                        color: SwabbitTheme.text),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: i < _rating.round()
                            ? SwabbitTheme.yellow
                            : SwabbitTheme.border,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_salesCount} ${_salesCount == 1 ? 'vendita' : 'vendite'}',
                    style: const TextStyle(
                        fontSize: 11, color: SwabbitTheme.text3),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Text(
                  'Le recensioni saranno disponibili dopo le prime transazioni.',
                  style: TextStyle(
                      fontSize: 13,
                      color: SwabbitTheme.text2,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        if (_profile?['luogo'] != null &&
            (_profile!['luogo'] as String).isNotEmpty)
          _infoRow(
              Icons.location_on_outlined, 'Luogo', _profile!['luogo']),
        if (_profile?['bio'] != null &&
            (_profile!['bio'] as String).isNotEmpty)
          _infoRow(Icons.info_outline_rounded, 'Bio', _profile!['bio']),
        _infoRow(
          Icons.calendar_today_outlined,
          'Membro dal',
          _profile?['created_at'] != null
              ? _formatDate(_profile!['created_at'])
              : '—',
        ),
        _infoRow(
          Icons.sell_outlined,
          'Vendite completate',
          '$_salesCount',
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: SwabbitTheme.cardDecoration(),
        child: Row(
          children: [
            Icon(icon, size: 18, color: SwabbitTheme.text3),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
        'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
      ];
      return '${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return '—';
    }
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
                    fontSize: 18,
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