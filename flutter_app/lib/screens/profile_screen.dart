import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';
import 'product_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: SafeArea(
        child: NestedScrollView(
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
              const Text('Profilo', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, fontSize: 22, color: SwabbitTheme.text)),
              const Spacer(),
              _IconBtn(icon: Icons.settings_outlined, onTap: () {}),
              const SizedBox(width: 8),
              _IconBtn(icon: Icons.logout_rounded, onTap: () {}),
            ],
          ),
          const SizedBox(height: 24),
          // Avatar + info
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: SwabbitTheme.accentGrad,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: SwabbitTheme.accent.withOpacity(0.3), width: 2),
                    ),
                    child: const Center(
                      child: Text('G', style: TextStyle(fontFamily: 'Syne', fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(color: SwabbitTheme.green, shape: BoxShape.circle, border: Border.all(color: SwabbitTheme.bg, width: 2)),
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
                        const Text('GigaRig', style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: SwabbitTheme.text)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: SwabbitTheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: SwabbitTheme.accent.withOpacity(0.2)),
                          ),
                          child: const Text('PRO', style: TextStyle(fontFamily: 'SpaceMono', fontSize: 9, fontWeight: FontWeight.w700, color: SwabbitTheme.accent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('@gigarig · Membro dal 2022', style: TextStyle(fontSize: 12, color: SwabbitTheme.text2)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ...List.generate(5, (i) => const Text('★', style: TextStyle(color: SwabbitTheme.yellow, fontSize: 13))),
                        const SizedBox(width: 4),
                        const Text('4.9 (47 vendite)', style: TextStyle(fontSize: 11, color: SwabbitTheme.text2)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Modifica profilo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: SwabbitTheme.text2,
                side: const BorderSide(color: SwabbitTheme.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          _StatCard(value: '47', label: 'Vendite', color: SwabbitTheme.green),
          const SizedBox(width: 10),
          _StatCard(value: '342', label: 'Follower', color: SwabbitTheme.yellow),
          const SizedBox(width: 10),
          _StatCard(value: '€ 4.2k', label: 'Fatturato', color: SwabbitTheme.accent),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SwabbitTheme.surface2,
        borderRadius: BorderRadius.circular(SwabbitTheme.radiusSm),
        border: Border.all(color: SwabbitTheme.border),
      ),
      child: Row(
        children: ['Annunci', 'Recensioni', 'Info'].asMap().entries.map((entry) {
          final i = entry.key;
          final isActive = _tabController.index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? SwabbitTheme.surface3 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: isActive ? SwabbitTheme.text : SwabbitTheme.text3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListingsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        ...AppData.myListings.map((listing) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ListingCard(listing: listing, onTap: () {
            final product = AppData.products.firstWhere((p) => p.id == listing.productId, orElse: () => AppData.products.first);
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(product: product)));
          }),
        )),
        const SizedBox(height: 8),
        // Add listing button
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: SwabbitTheme.accent.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(SwabbitTheme.radius),
              gradient: LinearGradient(colors: [SwabbitTheme.accent.withOpacity(0.05), SwabbitTheme.accent2.withOpacity(0.05)]),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, color: SwabbitTheme.accent, size: 20),
                SizedBox(width: 8),
                Text('Pubblica nuovo annuncio', style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w700, color: SwabbitTheme.accent)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    final reviews = [
      _ReviewData('Luca M.', 5, 'Venditore fantastico, spedizione rapida e componente come descritto. Consigliatissimo!', '2 giorni fa'),
      _ReviewData('Sara K.', 5, 'RTX perfetta, imballaggio eccellente. Risponde velocemente ai messaggi.', '1 settimana fa'),
      _ReviewData('Marco B.', 4, 'Prodotto ottimo, solo un piccolo graffio non segnalato. Resta un buon venditore.', '2 settimane fa'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: reviews.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: SwabbitTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(gradient: SwabbitTheme.cpuGrad, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(r.name[0], style: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14))),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SwabbitTheme.text)),
                      Text(r.date, style: const TextStyle(fontSize: 10, color: SwabbitTheme.text3)),
                    ],
                  ),
                  const Spacer(),
                  Row(children: List.generate(r.rating, (_) => const Text('★', style: TextStyle(color: SwabbitTheme.yellow, fontSize: 12)))),
                ],
              ),
              const SizedBox(height: 10),
              Text(r.comment, style: const TextStyle(fontSize: 13, color: SwabbitTheme.text2, height: 1.6)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: SwabbitTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('About', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 15, color: SwabbitTheme.text)),
              SizedBox(height: 8),
              Text(
                'Appassionato di hardware da oltre 10 anni. Compro e vendo componenti di alta qualità. '
                'Spedisco sempre assicurato con tracking. Risposte rapide garantite.',
                style: TextStyle(fontSize: 13, color: SwabbitTheme.text2, height: 1.7),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: SwabbitTheme.cardDecoration(),
          child: Column(
            children: [
              _InfoRow(icon: Icons.location_on_outlined, label: 'Sede', value: 'Milano, Italia'),
              const Divider(color: SwabbitTheme.border, height: 24),
              _InfoRow(icon: Icons.local_shipping_outlined, label: 'Spedizione', value: 'Assicurata con tracking'),
              const Divider(color: SwabbitTheme.border, height: 24),
              _InfoRow(icon: Icons.schedule_outlined, label: 'Risposta media', value: '< 1 ora'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── HELPER WIDGETS ───────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: SwabbitTheme.surface2,
          borderRadius: BorderRadius.circular(11),
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
  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: SwabbitTheme.cardDecoration(),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontFamily: 'SpaceMono', fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 9, color: SwabbitTheme.text3, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final UserListing listing;
  final VoidCallback onTap;
  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: SwabbitTheme.cardDecoration(),
        child: Row(
          children: [
            // Thumb
            Stack(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    gradient: listing.thumbGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(listing.emoji, style: const TextStyle(fontSize: 28))),
                ),
                Positioned(
                  top: 4, right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: listing.statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: listing.statusColor.withOpacity(0.4)),
                    ),
                    child: Text(listing.statusLabel, style: TextStyle(fontFamily: 'SpaceMono', fontSize: 7, fontWeight: FontWeight.w700, color: listing.statusColor)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SwabbitTheme.text), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('€ ${listing.price.toStringAsFixed(0)}', style: SwabbitTheme.monoStyle.copyWith(fontSize: 14, color: SwabbitTheme.accent)),
                ],
              ),
            ),
            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(children: [
                  const Icon(Icons.remove_red_eye_outlined, size: 11, color: SwabbitTheme.text3),
                  const SizedBox(width: 3),
                  Text('${listing.views}', style: const TextStyle(fontSize: 11, color: SwabbitTheme.text3)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.favorite_outline_rounded, size: 11, color: SwabbitTheme.text3),
                  const SizedBox(width: 3),
                  Text('${listing.likes}', style: const TextStyle(fontSize: 11, color: SwabbitTheme.text3)),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: SwabbitTheme.accent, size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: SwabbitTheme.text3)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SwabbitTheme.text)),
      ],
    );
  }
}

class _ReviewData {
  final String name;
  final int rating;
  final String comment;
  final String date;
  const _ReviewData(this.name, this.rating, this.comment, this.date);
}