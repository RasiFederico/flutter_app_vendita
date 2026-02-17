import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';
import 'product_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  int _activeFilter = 0;
  String _query = '';

  static const _filters = ['Tutti', 'GPU', 'CPU', 'RAM', 'Storage', 'Schede M.', 'Cooling'];

  List<Product> get _filtered {
    var list = AppData.products;
    if (_activeFilter > 0) {
      final cats = ['gpu', 'cpu', 'ram', 'ssd', 'mb', 'cool'];
      final catId = cats[_activeFilter - 1];
      // Simple filter by emoji/gradient mapping
      list = list.where((p) {
        if (catId == 'gpu') return p.emoji == '🎮';
        if (catId == 'cpu') return p.emoji == '⚙️';
        if (catId == 'ram') return p.emoji == '🧠';
        if (catId == 'ssd') return p.emoji == '💾';
        if (catId == 'mb')  return p.emoji == '🔌';
        if (catId == 'cool') return p.emoji == '❄️';
        return true;
      }).toList();
    }
    if (_query.isNotEmpty) {
      list = list.where((p) => p.title.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── STICKY HEADER ────────────────────────────────────────
            _buildHeader(context),
            // ── FILTER CHIPS ─────────────────────────────────────────
            _buildFilterChips(),
            // ── RESULTS ──────────────────────────────────────────────
            Expanded(child: _buildResults(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      decoration: BoxDecoration(
        color: SwabbitTheme.bg.withOpacity(0.95),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: SwabbitTheme.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SwabbitTheme.accent, width: 1.5),
                boxShadow: [BoxShadow(color: SwabbitTheme.accent.withOpacity(0.1), blurRadius: 20)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: SwabbitTheme.accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(color: SwabbitTheme.text, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'RTX 4090, Ryzen 9...',
                        hintStyle: TextStyle(color: SwabbitTheme.text3, fontSize: 14),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () { _controller.clear(); setState(() => _query = ''); },
                      child: const Icon(Icons.close_rounded, color: SwabbitTheme.text3, size: 16),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Filter button
          Stack(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: SwabbitTheme.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SwabbitTheme.border),
                ),
                child: const Icon(Icons.tune_rounded, color: SwabbitTheme.text2, size: 20),
              ),
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(color: SwabbitTheme.accent3, shape: BoxShape.circle),
                  child: const Center(child: Text('2', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isActive = _activeFilter == i;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? SwabbitTheme.accent.withOpacity(0.12) : SwabbitTheme.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? SwabbitTheme.accent : SwabbitTheme.border),
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive ? SwabbitTheme.accent : SwabbitTheme.text2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final results = _filtered;
    if (results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔍', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text('Nessun risultato', style: TextStyle(color: SwabbitTheme.text2, fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Prova con un\'altra ricerca', style: TextStyle(color: SwabbitTheme.text3, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Text('${results.length} risultati', style: const TextStyle(color: SwabbitTheme.text2, fontSize: 13)),
              const Spacer(),
              const Text('Ordina per ', style: TextStyle(color: SwabbitTheme.text3, fontSize: 12)),
              const Text('Prezzo ↑', style: TextStyle(color: SwabbitTheme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _buildResultCard(context, results[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: SwabbitTheme.cardDecoration(),
        child: Row(
          children: [
            // Thumb
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: product.thumbGradient,
                borderRadius: BorderRadius.circular(SwabbitTheme.radiusSm),
              ),
              child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 34))),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.conditionColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: product.conditionColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          product.conditionLabel.toUpperCase(),
                          style: TextStyle(fontFamily: 'SpaceMono', fontSize: 8, fontWeight: FontWeight.w700, color: product.conditionColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SwabbitTheme.text, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  if (product.originalPrice != null)
                    Text(
                      '€ ${product.originalPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 11, color: SwabbitTheme.text3, decoration: TextDecoration.lineThrough),
                    ),
                  Text(
                    '€ ${product.price.toStringAsFixed(0)}',
                    style: SwabbitTheme.monoStyle.copyWith(fontSize: 17, color: SwabbitTheme.accent),
                  ),
                ],
              ),
            ),
            // Tags
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (product.location.isNotEmpty) _Tag(product.location, color: SwabbitTheme.accent2),
                if (product.hasShipping) ...[const SizedBox(height: 4), const _Tag('Spedisce', color: SwabbitTheme.green)],
                if (product.isNegotiable) ...[const SizedBox(height: 4), const _Tag('Trattabile', color: SwabbitTheme.yellow)],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(text, style: TextStyle(fontFamily: 'SpaceMono', fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
    );
  }
}