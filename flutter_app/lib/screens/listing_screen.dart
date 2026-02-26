// lib/screens/listing_screen.dart

import 'package:flutter/material.dart';
import '../main.dart';
import '../models/listing.dart';
import '../services/supabase_service.dart';
import 'user_profile_screen.dart';
import 'chat_screen.dart'; // ← NUOVO
import '../models/chat.dart'; // ← NUOVO

class ListingScreen extends StatefulWidget {
  final Listing listing;
  const ListingScreen({super.key, required this.listing});

  @override
  State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> {
  bool _isFav = false;
  int _imageIndex = 0;
  bool _descExpanded = false;
  late Listing _listing;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    _trackView();
  }

  Future<void> _trackView() async {
    try {
      await SupabaseService.client
          .from('listings')
          .update({'views': _listing.views + 1}).eq('id', _listing.id);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final updated = await SupabaseService.getListingById(_listing.id);
      if (mounted && updated != null) {
        setState(() => _listing = updated);
      }
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  bool get _isOwner => SupabaseService.currentUser?.id == _listing.userId;

  // ── CONTATTA VENDITORE ────────────────────────────────────────────────────

  Future<void> _contactSeller() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      _snack('Devi essere loggato per scrivere al venditore', error: true);
      return;
    }
    if (user.id == _listing.userId) return; // non scrivere a te stesso

    try {
      final conv = await SupabaseService.getOrCreateConversation(
        sellerId: _listing.userId,
        listingId: _listing.id,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
      );
    } catch (e) {
      if (mounted) _snack('Errore: $e', error: true);
    }
  }

  // ── STATUS MANAGEMENT ─────────────────────────────────────────────────────

  Future<void> _changeStatus(ListingStatus status) async {
    try {
      await SupabaseService.updateListingStatus(_listing.id, status);
      setState(() => _listing = _listing.copyWith(status: status));
      _snack('Stato aggiornato: ${status.label}');
    } catch (e) {
      _snack('Errore: $e', error: true);
    }
  }

  Future<void> _deleteListing() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SwabbitTheme.surface,
        title: const Text('Elimina annuncio',
            style: TextStyle(
                fontFamily: 'Syne',
                color: SwabbitTheme.text,
                fontWeight: FontWeight.w700)),
        content: const Text(
            'Sei sicuro? L\'operazione è irreversibile e le immagini saranno eliminate.',
            style: TextStyle(color: SwabbitTheme.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla',
                style: TextStyle(color: SwabbitTheme.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina',
                style: TextStyle(color: SwabbitTheme.accent3)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await SupabaseService.deleteListing(_listing.id);
        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        _snack('Errore durante l\'eliminazione: $e', error: true);
      }
    }
  }

  void _openSellerProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: _listing.userId,
          initialName: _listing.sellerName,
          initialUsername: _listing.sellerUsername,
          initialAvatarUrl: _listing.sellerAvatarUrl,
        ),
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
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
      body: Stack(
        children: [
          RefreshIndicator(
            color: SwabbitTheme.accent,
            backgroundColor: SwabbitTheme.surface,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildGallery(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBadgesAndTitle(),
                        const SizedBox(height: 20),
                        _buildPriceRow(),
                        const SizedBox(height: 20),
                        _buildTags(),
                        const SizedBox(height: 20),
                        _buildDescription(),
                        const SizedBox(height: 20),
                        _buildSellerCard(),
                        if (_isOwner) ...[
                          const SizedBox(height: 20),
                          _buildOwnerActions(),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(context),
          ),
        ],
      ),
    );
  }

  // ── GALLERY ───────────────────────────────────────────────────────────────

  Widget _buildGallery(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          _listing.images.isEmpty
              ? Container(
                  color: SwabbitTheme.surface2,
                  child: Center(
                    child: Text(_listing.categoryEmoji,
                        style: const TextStyle(fontSize: 72)),
                  ),
                )
              : PageView.builder(
                  itemCount: _listing.images.length,
                  onPageChanged: (i) => setState(() => _imageIndex = i),
                  itemBuilder: (_, i) => Image.network(
                    _listing.images[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: SwabbitTheme.surface2,
                      child: const Icon(Icons.broken_image_outlined,
                          color: SwabbitTheme.text3, size: 48),
                    ),
                  ),
                ),
          // Back button
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Colors.white),
              ),
            ),
          ),
          // Favourite button
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => setState(() => _isFav = !_isFav),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 18,
                  color: _isFav ? SwabbitTheme.accent3 : Colors.white,
                ),
              ),
            ),
          ),
          // Page indicator
          if (_listing.images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _listing.images.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _imageIndex == i ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _imageIndex == i
                          ? SwabbitTheme.accent
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── CONTENT SECTIONS ──────────────────────────────────────────────────────

  Widget _buildBadgesAndTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            _Badge(_listing.condition.label, color: _listing.condition.color),
            if (_listing.hasShipping)
              _Badge('Spedizione', color: SwabbitTheme.accent2),
            if (_listing.isNegotiable)
              _Badge('Trattabile', color: SwabbitTheme.yellow),
            _Badge(_listing.status.label, color: _listing.status.color),
          ],
        ),
        const SizedBox(height: 12),
        Text(_listing.title,
            style: const TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: SwabbitTheme.text,
                height: 1.2)),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('€ ${_listing.price.toStringAsFixed(0)}',
            style: SwabbitTheme.monoStyle
                .copyWith(fontSize: 28, color: SwabbitTheme.accent)),
        if (_listing.originalPrice != null) ...[
          const SizedBox(width: 10),
          Text('€ ${_listing.originalPrice!.toStringAsFixed(0)}',
              style: SwabbitTheme.monoStyle.copyWith(
                  fontSize: 16,
                  color: SwabbitTheme.text3,
                  decoration: TextDecoration.lineThrough)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: SwabbitTheme.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '-${((_listing.originalPrice! - _listing.price) / _listing.originalPrice! * 100).round()}%',
              style: const TextStyle(
                  color: SwabbitTheme.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_listing.location.isNotEmpty)
          _Tag(icon: Icons.location_on_outlined, label: _listing.location),
        if (_listing.category != null)
          _Tag(
              icon: Icons.category_outlined,
              label: _listing.category!.toUpperCase()),
        _Tag(
            icon: Icons.visibility_outlined,
            label: '${_listing.views} visualizzazioni'),
      ],
    );
  }

  Widget _buildDescription() {
    if (_listing.description.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Descrizione',
            style: TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: SwabbitTheme.text)),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: Text(_listing.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: SwabbitTheme.text2, fontSize: 14, height: 1.5)),
          secondChild: Text(_listing.description,
              style: const TextStyle(
                  color: SwabbitTheme.text2, fontSize: 14, height: 1.5)),
          crossFadeState: _descExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        if (_listing.description.length > 120)
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _descExpanded ? 'Mostra meno' : 'Leggi tutto',
                style: const TextStyle(
                    color: SwabbitTheme.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  // ── SELLER CARD ───────────────────────────────────────────────────────────

  Widget _buildSellerCard() {
    final sellerName = _listing.sellerName ?? '';
    final sellerUsername = _listing.sellerUsername ?? '';
    final name = sellerName.isNotEmpty
        ? sellerName
        : sellerUsername.isNotEmpty
            ? sellerUsername
            : 'Utente';

    final showAt = sellerUsername.isNotEmpty && name != sellerUsername;
    final username = showAt ? '@$sellerUsername' : null;

    final words = name.trim().split(' ');
    final initials =
        words.take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    final avatarUrl = _listing.sellerAvatarUrl;
    final isOwnListing = _isOwner;

    return GestureDetector(
      onTap: isOwnListing ? null : _openSellerProfile,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: SwabbitTheme.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: SwabbitTheme.accentGrad,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: SwabbitTheme.accent.withOpacity(0.3), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: avatarUrl != null
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _avatarInitials(initials),
                      )
                    : _avatarInitials(initials),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: SwabbitTheme.text)),
                  if (username != null)
                    Text(username,
                        style: const TextStyle(
                            fontSize: 12, color: SwabbitTheme.text3)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(Icons.star_rounded,
                            size: 12,
                            color: i < _listing.sellerRating.round()
                                ? SwabbitTheme.yellow
                                : SwabbitTheme.border),
                      ),
                      const SizedBox(width: 6),
                      Text(
                          '${_listing.sellerRating.toStringAsFixed(1)} · ${_listing.sellerSales} vendite',
                          style: const TextStyle(
                              fontSize: 11, color: SwabbitTheme.text3)),
                    ],
                  ),
                ],
              ),
            ),
            if (!isOwnListing)
              const Icon(Icons.chevron_right_rounded,
                  color: SwabbitTheme.text3, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _avatarInitials(String initials) {
    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials.toUpperCase(),
        style: const TextStyle(
            fontFamily: 'Syne',
            fontWeight: FontWeight.w800,
            color: Colors.black,
            fontSize: 16),
      ),
    );
  }

  // ── OWNER ACTIONS ─────────────────────────────────────────────────────────

  Widget _buildOwnerActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SwabbitTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gestisci annuncio',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: SwabbitTheme.text)),
          const SizedBox(height: 12),
          Row(
            children: ListingStatus.values.map((s) {
              final active = _listing.status == s;
              return Expanded(
                child: GestureDetector(
                  onTap: active ? null : () => _changeStatus(s),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? s.color.withOpacity(0.15)
                          : SwabbitTheme.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: active
                              ? s.color.withOpacity(0.5)
                              : SwabbitTheme.border),
                    ),
                    child: Text(
                      s.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: active ? s.color : SwabbitTheme.text3),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _deleteListing,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: SwabbitTheme.accent3.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: SwabbitTheme.accent3.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 16, color: SwabbitTheme.accent3),
                  SizedBox(width: 6),
                  Text('Elimina annuncio',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: SwabbitTheme.accent3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM BAR ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    if (_isOwner) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SwabbitTheme.bg.withOpacity(0), SwabbitTheme.bg],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Contatta venditore',
                icon: Icons.chat_bubble_outline_rounded,
                onTap: _contactSeller, // ← COLLEGATO
                color: SwabbitTheme.accent,
                textColor: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            _ActionButton(
              label: 'Offerta',
              icon: Icons.local_offer_outlined,
              onTap: () {},
              color: SwabbitTheme.surface2,
              textColor: SwabbitTheme.text,
              borderColor: SwabbitTheme.border,
            ),
          ],
        ),
      ),
    );
  }
}

// ── HELPER WIDGETS ────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5)),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SwabbitTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SwabbitTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: SwabbitTheme.text3),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: SwabbitTheme.text2,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(SwabbitTheme.radiusSm),
          border:
              borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Syne',
                    color: textColor)),
          ],
        ),
      ),
    );
  }
}