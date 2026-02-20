import 'package:flutter/material.dart';
import '../main.dart';
import '../models/listing.dart';
import '../services/supabase_service.dart';
import 'listing_screen.dart';

// Categorie filtro
const _filterCategories = [
  ('Tutte', null, '🔍'),
  ('GPU', 'gpu', '🎮'),
  ('CPU', 'cpu', '⚙️'),
  ('RAM', 'ram', '🧠'),
  ('Storage', 'storage', '💾'),
  ('Motherboard', 'motherboard', '🔌'),
  ('Cooling', 'cooling', '❄️'),
  ('PSU', 'psu', '🔋'),
  ('Case', 'case', '🖥️'),
  ('Monitor', 'monitor', '🖵'),
  ('Periferiche', 'periferiche', '🖱️'),
  ('Altro', 'altro', '📦'),
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _query = '';
  String? _selectedCategory;
  ListingCondition? _selectedCondition;
  double? _maxPrice;

  List<Listing> _results = [];
  bool _loading = false;
  bool _hasSearched = false;

  // Debounce timer
  DateTime? _lastSearch;

  @override
  void initState() {
    super.initState();
    // Carica annunci recenti all'apertura
    _loadRecent();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    setState(() => _loading = true);
    try {
      final res = await SupabaseService.getRecentListings(limit: 20);
      if (mounted) setState(() => _results = res);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _hasSearched = true;
    });
    try {
      final res = await SupabaseService.searchListings(
        query: _query.trim().isEmpty ? null : _query.trim(),
        category: _selectedCategory,
        condition: _selectedCondition,
        maxPrice: _maxPrice,
      );
      if (mounted) setState(() => _results = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Errore di ricerca: $e'),
              backgroundColor: SwabbitTheme.accent3),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onQueryChanged(String v) {
    setState(() => _query = v);
    final now = DateTime.now();
    _lastSearch = now;
    Future.delayed(const Duration(milliseconds: 450), () {
      if (_lastSearch == now && mounted) _search();
    });
  }

  void _openListing(Listing listing) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ListingScreen(listing: listing)),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SwabbitTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FiltersSheet(
        currentCondition: _selectedCondition,
        currentMaxPrice: _maxPrice,
        onApply: (condition, maxPrice) {
          setState(() {
            _selectedCondition = condition;
            _maxPrice = maxPrice;
          });
          _search();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildCategoryChips(),
            Expanded(child: _buildResults(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      decoration:
          BoxDecoration(color: SwabbitTheme.bg.withOpacity(0.95)),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: SwabbitTheme.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: SwabbitTheme.accent, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: SwabbitTheme.accent.withOpacity(0.1),
                      blurRadius: 20)
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: SwabbitTheme.accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(
                          color: SwabbitTheme.text, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'RTX 4090, Ryzen 9...',
                        hintStyle: TextStyle(
                            color: SwabbitTheme.text3, fontSize: 14),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onChanged: _onQueryChanged,
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        setState(() {
                          _query = '';
                          _hasSearched = false;
                        });
                        _loadRecent();
                      },
                      child: const Icon(Icons.close_rounded,
                          color: SwabbitTheme.text3, size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Filter button
          GestureDetector(
            onTap: _showFilters,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_selectedCondition != null || _maxPrice != null)
                    ? SwabbitTheme.accent.withOpacity(0.15)
                    : SwabbitTheme.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (_selectedCondition != null || _maxPrice != null)
                      ? SwabbitTheme.accent
                      : SwabbitTheme.border,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: (_selectedCondition != null || _maxPrice != null)
                    ? SwabbitTheme.accent
                    : SwabbitTheme.text2,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filterCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, id, emoji) = _filterCategories[i];
          final selected = _selectedCategory == id;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = id);
              _search();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: selected ? SwabbitTheme.accentGrad : null,
                color: selected ? null : SwabbitTheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? SwabbitTheme.accent
                      : SwabbitTheme.border,
                ),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(label,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.black
                            : SwabbitTheme.text2,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: SwabbitTheme.accent));
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _hasSearched
                  ? 'Nessun risultato per "$_query"'
                  : 'Inizia a cercare',
              style: const TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: SwabbitTheme.text),
            ),
            const SizedBox(height: 6),
            const Text('Prova con parole chiave diverse',
                style:
                    TextStyle(fontSize: 13, color: SwabbitTheme.text2)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            _hasSearched && _query.isNotEmpty
                ? '${_results.length} risultati per "$_query"'
                : 'Annunci recenti',
            style: const TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: SwabbitTheme.text2),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: SwabbitTheme.accent,
            onRefresh: () => _hasSearched ? _search() : _loadRecent(),
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: _results.length,
              itemBuilder: (ctx, i) => _buildCard(ctx, _results[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, Listing listing) {
    return GestureDetector(
      onTap: () => _openListing(listing),
      child: Container(
        decoration: SwabbitTheme.cardDecoration(),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / Placeholder
            Expanded(
              child: listing.images.isNotEmpty
                  ? Image.network(
                      listing.images.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _placeholderThumb(listing),
                    )
                  : _placeholderThumb(listing),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: SwabbitTheme.text)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('€ ${listing.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontFamily: 'Syne',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: SwabbitTheme.accent)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: listing.condition.color
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(listing.condition.label,
                            style: TextStyle(
                                color: listing.condition.color,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  if (listing.location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 10, color: SwabbitTheme.text3),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(listing.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: SwabbitTheme.text3)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderThumb(Listing listing) {
    return Container(
      color: SwabbitTheme.surface2,
      child: Center(
          child: Text(listing.categoryEmoji,
              style: const TextStyle(fontSize: 40))),
    );
  }
}

// ── Filters Bottom Sheet ───────────────────────────────────────────────────────

class _FiltersSheet extends StatefulWidget {
  final ListingCondition? currentCondition;
  final double? currentMaxPrice;
  final void Function(ListingCondition?, double?) onApply;

  const _FiltersSheet({
    required this.currentCondition,
    required this.currentMaxPrice,
    required this.onApply,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  ListingCondition? _condition;
  double _maxPrice = 5000;
  bool _useMaxPrice = false;

  @override
  void initState() {
    super.initState();
    _condition = widget.currentCondition;
    if (widget.currentMaxPrice != null) {
      _useMaxPrice = true;
      _maxPrice = widget.currentMaxPrice!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filtri',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: SwabbitTheme.text)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _condition = null;
                    _useMaxPrice = false;
                    _maxPrice = 5000;
                  });
                },
                child: const Text('Reset',
                    style: TextStyle(color: SwabbitTheme.accent3)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Condizione',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: SwabbitTheme.text2)),
          const SizedBox(height: 10),
          Row(
            children: ListingCondition.values.map((c) {
              final sel = _condition == c;
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _condition = sel ? null : c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? c.color.withOpacity(0.15)
                          : SwabbitTheme.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? c.color : SwabbitTheme.border,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(c.label,
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                sel ? c.color : SwabbitTheme.text2,
                          )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Prezzo massimo',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: SwabbitTheme.text2)),
              Switch(
                value: _useMaxPrice,
                onChanged: (v) => setState(() => _useMaxPrice = v),
                activeColor: SwabbitTheme.accent,
              ),
            ],
          ),
          if (_useMaxPrice) ...[
            Text('€ ${_maxPrice.round()}',
                style: const TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: SwabbitTheme.accent)),
            Slider(
              value: _maxPrice,
              min: 0,
              max: 5000,
              divisions: 50,
              activeColor: SwabbitTheme.accent,
              inactiveColor: SwabbitTheme.surface3,
              onChanged: (v) => setState(() => _maxPrice = v),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onApply(
                  _condition,
                  _useMaxPrice ? _maxPrice : null,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: SwabbitTheme.accentGrad,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('Applica filtri',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.black)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}