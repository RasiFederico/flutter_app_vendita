import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import 'product_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profile;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadProfile();
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
      setState(() => _profile = p);
    } catch (_) {}
    setState(() => _profileLoading = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SwabbitTheme.surface,
        title: const Text('Logout',
            style: TextStyle(fontFamily: 'Syne', color: SwabbitTheme.text, fontWeight: FontWeight.w700)),
        content: const Text('Vuoi uscire dall\'account?',
            style: TextStyle(color: SwabbitTheme.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla', style: TextStyle(color: SwabbitTheme.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Esci', style: TextStyle(color: SwabbitTheme.accent3)),
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

  String get _displayName {
    if (_profile == null) return 'Utente';
    final nome = _profile!['nome'] ?? '';
    final cognome = _profile!['cognome'] ?? '';
    return '$nome $cognome'.trim();
  }

  String get _username {
    return _profile?['username'] ?? '';
  }

  String get _initials {
    final nome = _profile?['nome'] ?? '';
    final cognome = _profile?['cognome'] ?? '';
    final n = nome.isNotEmpty ? nome[0].toUpperCase() : '';
    final c = cognome.isNotEmpty ? cognome[0].toUpperCase() : '';
    return '$n$c'.isEmpty ? 'U' : '$n$c';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: SafeArea(
        child: _profileLoading
            ? const Center(child: CircularProgressIndicator(color: SwabbitTheme.accent))
            : NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildStats()),
                  SliverToBoxAdapter(child: _buildTabBar()),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          // Top row
          Row(
            children: [
              const Text('Profilo',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: SwabbitTheme.text)),
              const Spacer(),
              _IconBtn(
                  icon: Icons.settings_outlined,
                  onTap: _openEditProfile),
              const SizedBox(width: 8),
              _IconBtn(
                  icon: Icons.logout_rounded,
                  onTap: _logout),
            ],
          ),
          const SizedBox(height: 24),
          // Avatar + info
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: SwabbitTheme.accentGrad,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: SwabbitTheme.accent.withOpacity(0.3),
                          width: 2),
                    ),
                    child: Center(
                      child: Text(_initials,
                          style: const TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.black)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                          color: SwabbitTheme.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: SwabbitTheme.bg, width: 2)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_displayName,
                            style: const TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: SwabbitTheme.text)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: SwabbitTheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                color: SwabbitTheme.accent.withOpacity(0.2)),
                          ),
                          child: const Text('PRO',
                              style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: SwabbitTheme.accent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _username.isNotEmpty
                          ? '@$_username · Membro dal 2024'
                          : 'Membro dal 2024',
                      style: const TextStyle(
                          fontSize: 12, color: SwabbitTheme.text2),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ...List.generate(
                            5,
                            (i) => const Text('★',
                                style: TextStyle(
                                    color: SwabbitTheme.yellow,
                                    fontSize: 13))),
                        const SizedBox(width: 4),
                        const Text('4.9 (47 vendite)',
                            style: TextStyle(
                                fontSize: 11, color: SwabbitTheme.text2)),
                      ],
                    ),
                    if (_profile?['luogo'] != null &&
                        (_profile!['luogo'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: SwabbitTheme.text3),
                          const SizedBox(width: 3),
                          Text(_profile!['luogo'],
                              style: const TextStyle(
                                  fontSize: 12, color: SwabbitTheme.text2)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bio
          if (_profile?['bio'] != null &&
              (_profile!['bio'] as String).isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: SwabbitTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SwabbitTheme.border),
              ),
              child: Text(_profile!['bio'],
                  style: const TextStyle(
                      fontSize: 13, color: SwabbitTheme.text2, height: 1.4)),
            ),
          const SizedBox(height: 14),
          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openEditProfile,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Modifica profilo',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: SwabbitTheme.text,
                side: const BorderSide(color: SwabbitTheme.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatCard(value: '23', label: 'ANNUNCI', color: SwabbitTheme.accent),
          const SizedBox(width: 10),
          _StatCard(value: '47', label: 'VENDITE', color: SwabbitTheme.green),
          const SizedBox(width: 10),
          _StatCard(value: '4.9', label: 'RATING', color: SwabbitTheme.yellow),
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

  Widget _buildListingsTab() {
    final listings = AppData.products.take(3).toList();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: listings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final p = listings[i];
        return GestureDetector(
          onTap: () => Navigator.push(ctx,
              MaterialPageRoute(builder: (_) => ProductScreen(product: p))),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: SwabbitTheme.cardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: p.thumbGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                      child: Text(p.emoji,
                          style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.sellerName,
                          style: const TextStyle(
                              fontFamily: 'Syne',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: SwabbitTheme.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('€${p.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: SwabbitTheme.accent)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SwabbitTheme.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Attivo',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SwabbitTheme.green)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.all(14),
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
                  child: Center(
                      child: Text(
                          String.fromCharCode(65 + i),
                          style: const TextStyle(
                              fontFamily: 'Syne',
                              fontWeight: FontWeight.w700,
                              color: SwabbitTheme.text))),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Acquirente ${i + 1}',
                        style: const TextStyle(
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
                    fontSize: 13, color: SwabbitTheme.text2, height: 1.4)),
          ],
        ),
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
          _infoRow(Icons.phone_outlined, 'Telefono', _profile!['telefono']),
        if (_profile?['luogo'] != null &&
            (_profile!['luogo'] as String).isNotEmpty)
          _infoRow(Icons.location_on_outlined, 'Luogo', _profile!['luogo']),
        _infoRow(Icons.calendar_today_outlined, 'Membro dal', '2024'),
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
          Icon(icon, color: SwabbitTheme.accent, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: SwabbitTheme.text3)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      color: SwabbitTheme.text,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: SwabbitTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SwabbitTheme.border),
        ),
        child: Icon(icon, color: SwabbitTheme.text2, size: 18),
      ),
    );
  }
}

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
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: SwabbitTheme.cardDecoration(),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: SwabbitTheme.text3,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}