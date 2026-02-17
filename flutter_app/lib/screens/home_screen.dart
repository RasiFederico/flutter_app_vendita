import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';
import 'product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = -1;
  final Set<String> _favorites = {};

  void _toggleFavorite(String id) => setState(() {
    _favorites.contains(id) ? _favorites.remove(id) : _favorites.add(id);
  });

  void _openProduct(BuildContext context, Product product) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ProductScreen(product: product),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOut),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── HEADER ────────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader()),
            // ── SEARCH BAR ────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            // ── CATEGORIES ────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildCategories()),
            // ── FEATURED BANNER ───────────────────────────────────────
            SliverToBoxAdapter(child: _buildFeaturedBanner(context)),
            // ── SECTION TITLE ─────────────────────────────────────────
            SliverToBoxAdapter(child: _buildSectionTitle('Annunci recenti')),
            // ── PRODUCT GRID ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildProductCard(context, AppData.products[index]),
                  childCount: AppData.products.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // LOGO
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'Swab', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, fontSize: 26, color: SwabbitTheme.text, letterSpacing: -0.5)),
                TextSpan(text: 'bit', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, fontSize: 26, color: SwabbitTheme.accent, letterSpacing: -0.5)),
              ],
            ),
          ),
          const Spacer(),
          // NOTIFICATION BUTTON
          Stack(
            children: [
              _IconButton(icon: Icons.notifications_none_rounded, onTap: () {}),
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: SwabbitTheme.accent3,
                    shape: BoxShape.circle,
                    border: Border.all(color: SwabbitTheme.surface2, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          _IconButton(icon: Icons.tune_rounded, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: SwabbitTheme.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SwabbitTheme.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: SwabbitTheme.text3, size: 18),
              SizedBox(width: 10),
              Text('Cerca GPU, CPU, RAM...', style: TextStyle(color: SwabbitTheme.text3, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Categorie'),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: AppData.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final cat = AppData.categories[i];
              final isSelected = _selectedCategoryIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryIndex = isSelected ? -1 : i),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58, height: 58,
                      decoration: BoxDecoration(
                        gradient: cat.gradient,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? SwabbitTheme.accent : SwabbitTheme.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected ? [BoxShadow(color: SwabbitTheme.accent.withOpacity(0.25), blurRadius: 16)] : [],
                      ),
                      child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(height: 6),
                    Text(cat.label, style: const TextStyle(fontSize: 11, color: SwabbitTheme.text2, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFeaturedBanner(BuildContext context) {
    final featured = AppData.products.firstWhere((p) => p.isFeatured);
    return GestureDetector(
      onTap: () => _openProduct(context, featured),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a0933), Color(0xFF0d1a33), Color(0xFF001a1a)],
          ),
          borderRadius: BorderRadius.circular(SwabbitTheme.radius),
          border: Border.all(color: SwabbitTheme.accent2.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            // Glow
            Positioned(
              top: -40, right: -20,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [SwabbitTheme.accent2.withOpacity(0.2), Colors.transparent]),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: SwabbitTheme.accent2, borderRadius: BorderRadius.circular(6)),
                  child: const Text('IN EVIDENZA', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: SwabbitTheme.displayStyle.copyWith(fontSize: 20, height: 1.2),
                    children: const [
                      TextSpan(text: 'RTX '),
                      TextSpan(text: '4090', style: TextStyle(color: SwabbitTheme.accent)),
                      TextSpan(text: '\nFounders Ed.'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text('24GB GDDR6X · Ottime condizioni', style: TextStyle(fontSize: 13, color: SwabbitTheme.text2)),
                const SizedBox(height: 16),
                Text(
                  '€ ${featured.price.toStringAsFixed(0)}',
                  style: SwabbitTheme.monoStyle.copyWith(fontSize: 22, color: SwabbitTheme.accent),
                ),
              ],
            ),
            Positioned(
              top: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SwabbitTheme.border),
                ),
                child: Text(
                  featured.originalPrice != null ? '−${((1 - featured.price / featured.originalPrice!) * 100).round()}%' : 'TOP',
                  style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 12, fontWeight: FontWeight.w700, color: SwabbitTheme.green),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(title, style: SwabbitTheme.displayStyle.copyWith(fontSize: 17)),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final isFav = _favorites.contains(product.id);
    return GestureDetector(
      onTap: () => _openProduct(context, product),
      child: Container(
        decoration: SwabbitTheme.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: BoxDecoration(gradient: product.thumbGradient)),
                  Center(child: Text(product.emoji, style: const TextStyle(fontSize: 52))),
                  // Fav button
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(product.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 14,
                            color: isFav ? SwabbitTheme.accent3 : SwabbitTheme.text2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Condition badge
                  Positioned(
                    bottom: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: product.conditionColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: product.conditionColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        product.conditionLabel.toUpperCase(),
                        style: TextStyle(fontFamily: 'SpaceMono', fontSize: 9, fontWeight: FontWeight.w700, color: product.conditionColor, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SwabbitTheme.text, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '€ ${product.price.toStringAsFixed(0)}',
                      style: SwabbitTheme.monoStyle.copyWith(fontSize: 15, color: SwabbitTheme.accent),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 10, color: SwabbitTheme.text3),
                        const SizedBox(width: 2),
                        Text(product.location, style: const TextStyle(fontSize: 11, color: SwabbitTheme.text3)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: SwabbitTheme.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SwabbitTheme.border),
        ),
        child: Icon(icon, color: SwabbitTheme.text2, size: 18),
      ),
    );
  }
}