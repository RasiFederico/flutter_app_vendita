import 'package:flutter/material.dart';
import '../main.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    SearchScreen(),
    SizedBox(), // sell placeholder
    SizedBox(), // saved placeholder
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    if (index == 2) {
      _showSellModal();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _showSellModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SwabbitTheme.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _SellSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _SwabbitBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ─── BOTTOM NAV ───────────────────────────────────────────────────────────────

class _SwabbitBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SwabbitBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SwabbitTheme.surface.withOpacity(0.95),
        border: const Border(top: BorderSide(color: SwabbitTheme.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded,       label: 'Home',   index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.search_rounded,     label: 'Cerca',  index: 1, current: currentIndex, onTap: onTap),
              _SellNavItem(onTap: () => onTap(2)),
              _NavItem(icon: Icons.favorite_border_rounded, label: 'Salvati', index: 3, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_outline_rounded,  label: 'Profilo', index: 4, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon, required this.label, required this.index,
    required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? SwabbitTheme.accent.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? SwabbitTheme.accent : SwabbitTheme.text3, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActive ? SwabbitTheme.accent : SwabbitTheme.text3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellNavItem extends StatelessWidget {
  final VoidCallback onTap;
  const _SellNavItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: SwabbitTheme.accentGrad,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SwabbitTheme.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: SwabbitTheme.accent.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.black, size: 26),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -6),
              child: const Text(
                'Vendi',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: SwabbitTheme.text3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SELL MODAL ───────────────────────────────────────────────────────────────

class _SellSheet extends StatelessWidget {
  const _SellSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: SwabbitTheme.text3, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 24),
          Text('Pubblica annuncio', style: SwabbitTheme.displayStyle.copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          const Text('Scegli come vuoi vendere il tuo componente', style: TextStyle(color: SwabbitTheme.text2, fontSize: 14)),
          const SizedBox(height: 24),
          _SellOption(
            icon: Icons.photo_camera_rounded,
            title: 'Scatta foto',
            subtitle: 'Usa la fotocamera per aggiungere immagini',
            gradient: SwabbitTheme.accentGrad,
          ),
          const SizedBox(height: 12),
          _SellOption(
            icon: Icons.edit_rounded,
            title: 'Inserisci manualmente',
            subtitle: 'Descrivi il componente e imposta il prezzo',
            gradient: SwabbitTheme.cpuGrad,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SellOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;

  const _SellOption({required this.icon, required this.title, required this.subtitle, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SwabbitTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: SwabbitTheme.text, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: SwabbitTheme.text2, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: SwabbitTheme.text3),
        ],
      ),
    );
  }
}