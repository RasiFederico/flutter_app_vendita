// lib/screens/listing_screen.dart

import 'package:flutter/material.dart';
import '../main.dart';
import '../models/listing.dart';
import '../services/supabase_service.dart';
import '../services/audio_service.dart';
import 'user_profile_screen.dart';
import 'chat_screen.dart';
import '../models/chat.dart';

class ListingScreen extends StatefulWidget {
  final Listing listing;
  const ListingScreen({super.key, required this.listing});

  @override
  State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> {
  bool _isFav = false;
  bool _favLoading = false;
  int _imageIndex = 0;
  bool _descExpanded = false;
  late Listing _listing;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    _trackView();
    _loadFavStatus();
  }

  Future<void> _loadFavStatus() async {
    if (SupabaseService.currentUser == null) return;
    try {
      final ids = await SupabaseService.getFavoriteIds();
      if (mounted) setState(() => _isFav = ids.contains(_listing.id));
    } catch (_) {}
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
      if (mounted && updated != null) setState(() => _listing = updated);
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  // ── TOGGLE FAV ────────────────────────────────────────────────────────────

  Future<void> _toggleFav() async {
    if (SupabaseService.currentUser == null) {
      _snack('Devi essere loggato per salvare i preferiti', error: true);
      return;
    }
    setState(() => _favLoading = true);
    try {
      final newState = await SupabaseService.toggleFavorite(_listing.id);
      if (mounted) {
        setState(() => _isFav = newState);
        // ── Suono ──
        if (newState) {
          AudioService.playFavoriteAdd();
        } else {
          AudioService.playFavoriteRemove();
        }
      }
    } catch (e) {
      if (mounted) _snack('Errore: $e', error: true);
    }
    if (mounted) setState(() => _favLoading = false);
  }

  bool get _isOwner => SupabaseService.currentUser?.id == _listing.userId;

  // ── CONTATTA VENDITORE ────────────────────────────────────────────────────

  Future<void> _contactSeller() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      _snack('Devi essere loggato per scrivere al venditore', error: true);
      return;
    }
    if (user.id == _listing.userId) return;

    try {
      // Cerca o crea conversazione
      final existing = await SupabaseService.client
          .from('conversations')
          .select()
          .or('and(buyer_id.eq.${user.id},seller_id.eq.${_listing.userId}),and(buyer_id.eq.${_listing.userId},seller_id.eq.${user.id})')
          .eq('listing_id', _listing.id)
          .maybeSingle();

      Map<String, dynamic> convRow;
      if (existing != null) {
        convRow = existing as Map<String, dynamic>;
      } else {
        final created = await SupabaseService.client
            .from('conversations')
            .insert({
              'buyer_id': user.id,
              'seller_id': _listing.userId,
              'listing_id': _listing.id,
            })
            .select()
            .single();
        convRow = created as Map<String, dynamic>;
      }

      // Carica profilo venditore per la conv
      final sellerProfile = await SupabaseService.client
          .from('profiles')
          .select('nome, cognome, username, avatar_url')
          .eq('id', _listing.userId)
          .maybeSingle();

      final nome = (sellerProfile?['nome'] as String? ?? '').trim();
      final cognome = (sellerProfile?['cognome'] as String? ?? '').trim();
      final fullName = '$nome $cognome'.trim();
      final username = sellerProfile?['username'] as String? ?? '';
      final displayName = fullName.isNotEmpty
          ? fullName
          : username.isNotEmpty
              ? username
              : 'Venditore';

      final conv = Conversation(
        id: convRow['id'] as String,
        listingId: _listing.id,
        buyerId: convRow['buyer_id'] as String,
        sellerId: convRow['seller_id'] as String,
        lastMessage: convRow['last_message'] as String?,
        lastMessageAt: convRow['last_message_at'] != null
            ? DateTime.parse(convRow['last_message_at'] as String)
            : null,
        createdAt: DateTime.parse(convRow['created_at'] as String),
        otherUserName: displayName,
        otherUserUsername: username.isNotEmpty ? username : null,
        otherUserAvatarUrl: sellerProfile?['avatar_url'] as String?,
        listingTitle: _listing.title,
        listingImages: _listing.images.isNotEmpty ? [_listing.images.first] : null,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
      );
    } catch (e) {
      if (mounted) _snack('Errore nell\'apertura della chat: $e', error: true);
    }
  }

  Future<void> _changeStatus(ListingStatus status) async {
    try {
      await SupabaseService.updateListingStatus(_listing.id, status);
      if (mounted) setState(() => _listing = _listing.copyWith(status: status));
      _snack('Stato aggiornato');
    } catch (e) {
      if (mounted) _snack('Errore: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          error ? SwabbitTheme.accent3 : SwabbitTheme.green,
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
            bottom: 0, left: 0, right: 0,
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
          // Image/emoji background
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

          // Back
          Positioned(
            top: 16, left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Colors.white),
              ),
            ),
          ),

          // ❤ Favourite
          Positioned(
            top: 16, right: 16,
            child: GestureDetector(
              onTap: _favLoading ? null : _toggleFav,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isFav
                      ? SwabbitTheme.accent3.withOpacity(0.9)
                      : Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isFav
                      ? [
                          BoxShadow(
                              color: SwabbitTheme.accent3.withOpacity(0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 4))
                        ]
                      : [],
                ),
                child: _favLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          _isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(_isFav),
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),

          // Dots indicator
          if (_listing.images.length > 1)
            Positioned(
              bottom: 12, left: 0, right: 0,
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
                          ? Colors.white
                          : Colors.white38,
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

  // ── BADGES & TITLE ────────────────────────────────────────────────────────

  Widget _buildBadgesAndTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 6, children: [
          _ConditionBadge(_listing.condition),
          if (_listing.hasShipping)
            _Badge(
                label: 'Spedizione',
                icon: Icons.local_shipping_outlined,
                color: SwabbitTheme.accent2),
          if (_listing.isNegotiable)
            _Badge(
                label: 'Trattabile',
                icon: Icons.handshake_outlined,
                color: SwabbitTheme.yellow),
        ]),
        const SizedBox(height: 12),
        Text(
          _listing.title,
          style: const TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: SwabbitTheme.text,
              height: 1.2),
        ),
      ],
    );
  }

  // ── PRICE ROW ─────────────────────────────────────────────────────────────

  Widget _buildPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '€ ${_listing.price.toStringAsFixed(_listing.price.truncateToDouble() == _listing.price ? 0 : 2)}',
          style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: SwabbitTheme.accent),
        ),
        if (_listing.originalPrice != null &&
            _listing.originalPrice! > _listing.price) ...[
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '€ ${_listing.originalPrice!.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 16,
                  color: SwabbitTheme.text3,
                  decoration: TextDecoration.lineThrough),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: SwabbitTheme.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                  color: SwabbitTheme.green.withOpacity(0.3)),
            ),
            child: Text(
              '−${((1 - _listing.price / _listing.originalPrice!) * 100).round()}%',
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

  // ── TAGS ──────────────────────────────────────────────────────────────────

  Widget _buildTags() {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      if (_listing.location.isNotEmpty)
        _Tag(icon: Icons.location_on_outlined, label: _listing.location),
      if (_listing.category != null)
        _Tag(
            icon: Icons.category_outlined,
            label: _listing.category!.toUpperCase()),
      _Tag(
          icon: Icons.visibility_outlined,
          label: '${_listing.views} visualizzazioni'),
    ]);
  }

  // ── DESCRIPTION ───────────────────────────────────────────────────────────

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
        words.take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final isOwnListing = _isOwner;

    return GestureDetector(
      onTap: isOwnListing
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      UserProfileScreen(userId: _listing.userId),
                ),
              ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: SwabbitTheme.cardDecoration(),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: SwabbitTheme.accentGrad,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _listing.sellerAvatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      _listing.sellerAvatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarInitials(initials),
                    ),
                  )
                : _avatarInitials(initials),
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
                  Row(children: [
                    Icon(Icons.star_rounded,
                        size: 13,
                        color: _listing.sellerRating >= 4.5
                            ? SwabbitTheme.yellow
                            : SwabbitTheme.border),
                    const SizedBox(width: 4),
                    Text(
                        '${_listing.sellerRating.toStringAsFixed(1)} · ${_listing.sellerSales} vendite',
                        style: const TextStyle(
                            fontSize: 11, color: SwabbitTheme.text3)),
                  ]),
                ]),
          ),
          if (!isOwnListing)
            const Icon(Icons.chevron_right_rounded,
                color: SwabbitTheme.text3, size: 20),
        ]),
      ),
    );
  }

  Widget _avatarInitials(String initials) => Center(
        child: Text(
          initials.isEmpty ? '?' : initials.toUpperCase(),
          style: const TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w800,
              color: Colors.black,
              fontSize: 16),
        ),
      );

  // ── OWNER ACTIONS ─────────────────────────────────────────────────────────

  Widget _buildOwnerActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SwabbitTheme.cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  child: Text(s.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: active ? s.color : SwabbitTheme.text3)),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ── BOTTOM BAR ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: SwabbitTheme.bg,
        border: const Border(
            top: BorderSide(color: SwabbitTheme.border, width: 0.5)),
      ),
      child: _isOwner
          ? Row(children: [
              Expanded(
                child: Text(
                  'Questo è il tuo annuncio',
                  style: const TextStyle(
                      fontSize: 13, color: SwabbitTheme.text3),
                ),
              ),
            ])
          : Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _contactSeller,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: SwabbitTheme.accentGrad,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: SwabbitTheme.accent.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 18, color: Colors.black),
                        SizedBox(width: 8),
                        Text('Contatta venditore',
                            style: TextStyle(
                                fontFamily: 'Syne',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.black)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
    );
  }
}

// ── SMALL WIDGETS ─────────────────────────────────────────────────────────────

class _ConditionBadge extends StatelessWidget {
  final ListingCondition condition;
  const _ConditionBadge(this.condition);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: condition.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: condition.color.withOpacity(0.4)),
      ),
      child: Text(
        condition.label,
        style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: condition.color),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Badge(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color)),
      ]),
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: SwabbitTheme.text3),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: SwabbitTheme.text2)),
      ]),
    );
  }
}