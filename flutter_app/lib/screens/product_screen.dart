import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';

class ProductScreen extends StatefulWidget {
  final Product product;
  const ProductScreen({super.key, required this.product});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  bool _isFav = false;
  bool _descExpanded = false;

  Product get p => widget.product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── APP BAR / GALLERY ──────────────────────────────────
              SliverToBoxAdapter(child: _buildGallery(context)),
              // ── BODY ──────────────────────────────────────────────
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
                      _buildSpecs(),
                      const SizedBox(height: 20),
                      _buildDescription(),
                      const SizedBox(height: 20),
                      _buildSellerCard(),
                      const SizedBox(height: 100), // bottom padding for FAB
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ── BOTTOM ACTIONS ────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomActions(context),
          ),
        ],
      ),
    );
  }

  // ── GALLERY ─────────────────────────────────────────────────────────────────

  Widget _buildGallery(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF120820), const Color(0xFF0a1020), const Color(0xFF001a1a)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.4, 0),
                        radius: 0.8,
                        colors: [SwabbitTheme.accent2.withOpacity(0.15), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.4, 0),
                        radius: 0.8,
                        colors: [SwabbitTheme.accent.withOpacity(0.1), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    p.emoji,
                    style: TextStyle(fontSize: 110, shadows: [Shadow(color: SwabbitTheme.accent.withOpacity(0.3), blurRadius: 40)]),
                  ),
                ),
              ],
            ),
          ),
          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _GlassButton(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_rounded, color: SwabbitTheme.text, size: 20),
                    ),
                    const Spacer(),
                    _GlassButton(
                      onTap: () {},
                      child: const Icon(Icons.share_rounded, color: SwabbitTheme.text, size: 18),
                    ),
                    const SizedBox(width: 8),
                    _GlassButton(
                      onTap: () {},
                      child: const Icon(Icons.more_horiz_rounded, color: SwabbitTheme.text, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Dots
          Positioned(
            bottom: 14,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: i == 0 ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == 0 ? SwabbitTheme.accent : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  // ── BADGES & TITLE ───────────────────────────────────────────────────────────

  Widget _buildBadgesAndTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _Badge(p.conditionLabel, color: p.conditionColor),
            if (p.hasShipping) const _Badge('Spedizione', color: SwabbitTheme.green),
            if (p.isNegotiable) const _Badge('Trattabile', color: SwabbitTheme.yellow),
          ],
        ),
        const SizedBox(height: 12),
        Text(p.title, style: SwabbitTheme.displayStyle.copyWith(fontSize: 22, height: 1.2)),
        const SizedBox(height: 6),
        Text(p.subtitle, style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 12, color: SwabbitTheme.text2)),
      ],
    );
  }

  // ── PRICE ROW ────────────────────────────────────────────────────────────────

  Widget _buildPriceRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SwabbitTheme.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.originalPrice != null)
                Text(
                  '€ ${p.originalPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 13, color: SwabbitTheme.text3, decoration: TextDecoration.lineThrough),
                ),
              Text(
                '€ ${p.price.toStringAsFixed(0)}',
                style: SwabbitTheme.monoStyle.copyWith(fontSize: 28, color: SwabbitTheme.accent),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              // Share button
              _ActionButton(
                onTap: () {},
                icon: Icons.ios_share_rounded,
              ),
              const SizedBox(width: 8),
              // Favorite button
              GestureDetector(
                onTap: () => setState(() => _isFav = !_isFav),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: _isFav ? SwabbitTheme.accent3.withOpacity(0.1) : SwabbitTheme.surface3,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isFav ? SwabbitTheme.accent3.withOpacity(0.4) : SwabbitTheme.border),
                  ),
                  child: Icon(
                    _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isFav ? SwabbitTheme.accent3 : SwabbitTheme.text2,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SPECS ────────────────────────────────────────────────────────────────────

  Widget _buildSpecs() {
    if (p.specs.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Specifiche', style: SwabbitTheme.displayStyle.copyWith(fontSize: 15)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: p.specs.entries.map((e) => Container(
            padding: const EdgeInsets.all(12),
            decoration: SwabbitTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(e.key.toUpperCase(), style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 9, color: SwabbitTheme.text3, letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SwabbitTheme.text), overflow: TextOverflow.ellipsis),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ── DESCRIPTION ──────────────────────────────────────────────────────────────

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SwabbitTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Descrizione', style: SwabbitTheme.displayStyle.copyWith(fontSize: 15)),
          const SizedBox(height: 8),
          Text(
            p.description,
            maxLines: _descExpanded ? null : 3,
            overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: SwabbitTheme.text2, height: 1.7),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Text(
              _descExpanded ? 'Mostra meno' : 'Mostra tutto',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SwabbitTheme.accent),
            ),
          ),
        ],
      ),
    );
  }

  // ── SELLER CARD ──────────────────────────────────────────────────────────────

  Widget _buildSellerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SwabbitTheme.cardDecoration(),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: SwabbitTheme.accentGrad,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SwabbitTheme.accent.withOpacity(0.3), width: 2),
                ),
                child: Center(
                  child: Text(
                    p.sellerName[0].toUpperCase(),
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.sellerName, style: const TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700, color: SwabbitTheme.text)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('4.9 ★', style: TextStyle(fontSize: 11, color: SwabbitTheme.yellow, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: SwabbitTheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: SwabbitTheme.accent.withOpacity(0.2)),
                          ),
                          child: const Text('VERIFICATO', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 9, fontWeight: FontWeight.w700, color: SwabbitTheme.accent)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stats
          Row(
            children: [
              _SellerStat('${p.sellerSales}', 'Vendite', color: SwabbitTheme.green),
              _SellerStat('${p.sellerFollowers}', 'Follower', color: SwabbitTheme.yellow),
              _SellerStat('98%', 'Risposta', color: SwabbitTheme.text),
            ],
          ),
          const SizedBox(height: 14),
          // Buttons
          Row(
            children: [
              Expanded(
                child: _ChatButton(
                  label: 'Chatta',
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () {},
                  color: SwabbitTheme.accent,
                  textColor: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              _ActionButton(onTap: () {}, icon: Icons.phone_outlined),
            ],
          ),
        ],
      ),
    );
  }

  // ── BOTTOM ACTIONS ───────────────────────────────────────────────────────────

  Widget _buildBottomActions(BuildContext context) {
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
              child: _ChatButton(
                label: 'Contatta venditore',
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () {},
                color: SwabbitTheme.accent,
                textColor: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            _ChatButton(
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

// ─── HELPER WIDGETS ───────────────────────────────────────────────────────────

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
      child: Text(label.toUpperCase(), style: TextStyle(fontFamily: 'SpaceMono', fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
    );
  }
}

class _SellerStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SellerStat(this.value, this.label, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: SwabbitTheme.surface3, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontFamily: 'SpaceMono', fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 9, color: SwabbitTheme.text3, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _GlassButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  const _ActionButton({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: SwabbitTheme.surface3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SwabbitTheme.border),
        ),
        child: Icon(icon, color: SwabbitTheme.text2, size: 20),
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  const _ChatButton({required this.label, required this.icon, required this.onTap, required this.color, required this.textColor, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(SwabbitTheme.radiusSm),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Syne', color: textColor)),
          ],
        ),
      ),
    );
  }
}