import 'package:flutter/material.dart';
import '../main.dart';
import '../models/listing.dart';
import '../services/supabase_service.dart';

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

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    _trackView();
  }

  Future<void> _trackView() async {
    // Incrementa views (fire-and-forget)
    try {
      await SupabaseService.client
          .from('listings')
          .update({'views': _listing.views + 1})
          .eq('id', _listing.id);
    } catch (_) {}
  }

  bool get _isOwner =>
      SupabaseService.currentUser?.id == _listing.userId;

  // ── STATUS MANAGEMENT (solo owner) ────────────────────────────────────────

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
        content: const Text('Sei sicuro? L\'operazione è irreversibile.',
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
      await SupabaseService.deleteListing(_listing.id);
      if (!mounted) return;
      Navigator.pop(context, true); // segnala che è stato eliminato
    }
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
          CustomScrollView(
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
          // Bottom action bar
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
          // Immagini o placeholder
          _listing.images.isEmpty
              ? Container(
                  color: SwabbitTheme.surface2,
                  child: Center(
                    child: Text(_listing.categoryEmoji,
                        style: const TextStyle(fontSize: 80)),
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
                      child: Center(
                        child: Text(_listing.categoryEmoji,
                            style: const TextStyle(fontSize: 80)),
                      ),
                    ),
                  ),
                ),
          // Gradient overlay bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [SwabbitTheme.bg, SwabbitTheme.bg.withOpacity(0)],
                ),
              ),
            ),
          ),
          // Back + fav buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                _CircleBtn(
                  icon: _isFav ? Icons.favorite : Icons.favorite_border,
                  color: _isFav ? SwabbitTheme.accent3 : SwabbitTheme.text,
                  onTap: () => setState(() => _isFav = !_isFav),
                ),
              ],
            ),
          ),
          // Image indicator dots
          if (_listing.images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _listing.images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _imageIndex ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == _imageIndex
                          ? SwabbitTheme.accent
                          : SwabbitTheme.text3,
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

  // ── CONTENT ───────────────────────────────────────────────────────────────

  Widget _buildBadgesAndTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Badge(
              label: _listing.condition.label,
              color: _listing.condition.color,
            ),
            if (_listing.isNegotiable) ...[
              const SizedBox(width: 8),
              const _Badge(label: 'Trattabile', color: SwabbitTheme.accent),
            ],
            if (_listing.hasShipping) ...[
              const SizedBox(width: 8),
              const _Badge(
                  label: '📦 Spedizione', color: SwabbitTheme.surface3),
            ],
            if (_listing.status != ListingStatus.active) ...[
              const SizedBox(width: 8),
              _Badge(
                label: _listing.status.label,
                color: _listing.status.color,
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(_listing.title,
            style: const TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: SwabbitTheme.text,
              height: 1.25,
            )),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('€ ${_listing.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Syne',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: SwabbitTheme.text,
            )),
        if (_listing.originalPrice != null) ...[
          const SizedBox(width: 10),
          Text('€ ${_listing.originalPrice!.toStringAsFixed(2)}',
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: SwabbitTheme.text3,
                fontSize: 16,
              )),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: SwabbitTheme.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: SwabbitTheme.green.withOpacity(0.3)),
            ),
            child: Text(
              '-${((((_listing.originalPrice! - _listing.price) / _listing.originalPrice!) * 100)).round()}%',
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

  Widget _buildSellerCard() {
    final name = _listing.sellerName?.isNotEmpty == true
        ? _listing.sellerName!
        : 'Venditore';
    final initials = name.trim().split(' ').take(2).map((w) => w[0]).join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SwabbitTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: SwabbitTheme.accentGrad,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(initials.toUpperCase(),
                  style: const TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      fontSize: 15)),
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
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(Icons.star_rounded,
                          size: 12,
                          color: i < _listing.sellerRating.round()
                              ? SwabbitTheme.yellow
                              : SwabbitTheme.surface3),
                    ),
                    const SizedBox(width: 4),
                    Text('${_listing.sellerRating.toStringAsFixed(1)} · ${_listing.sellerSales} vendite',
                        style: const TextStyle(
                            fontSize: 11, color: SwabbitTheme.text3)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SwabbitTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SwabbitTheme.border),
      ),
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
            children: [
              if (_listing.status != ListingStatus.active)
                Expanded(
                  child: _ActionBtn(
                    label: 'Attiva',
                    color: SwabbitTheme.green,
                    onTap: () => _changeStatus(ListingStatus.active),
                  ),
                ),
              if (_listing.status == ListingStatus.active) ...[
                Expanded(
                  child: _ActionBtn(
                    label: 'Pausa',
                    color: SwabbitTheme.yellow,
                    onTap: () => _changeStatus(ListingStatus.paused),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'Venduto',
                    color: SwabbitTheme.text3,
                    onTap: () => _changeStatus(ListingStatus.sold),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'Elimina',
                  color: SwabbitTheme.accent3,
                  onTap: _deleteListing,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    if (_isOwner) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: SwabbitTheme.bg.withOpacity(0.95),
        border: const Border(top: BorderSide(color: SwabbitTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: SwabbitTheme.text,
                side: const BorderSide(color: SwabbitTheme.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('💬 Messaggio',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: SwabbitTheme.accentGrad,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: SwabbitTheme.accent.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: TextButton(
                onPressed: () {},
                child: const Text('Compra ora',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.black)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Syne')),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SwabbitTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: SwabbitTheme.text3),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: SwabbitTheme.text2,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _CircleBtn(
      {required this.icon,
      required this.onTap,
      this.color = SwabbitTheme.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: SwabbitTheme.bg.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(color: SwabbitTheme.border),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: color)),
        ),
      ),
    );
  }
}