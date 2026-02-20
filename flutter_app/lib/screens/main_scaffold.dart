import 'package:flutter/material.dart';
import '../main.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'create_listing_screen.dart';

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
    SizedBox(), // sell placeholder — gestito separatamente
    SizedBox(), // saved placeholder
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    if (index == 2) {
      _openCreateListing();
      return;
    }
    setState(() => _currentIndex = index);
  }

  Future<void> _openCreateListing() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CreateListingScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
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
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: SwabbitTheme.surface,
        border: const Border(top: BorderSide(color: SwabbitTheme.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => _onNavTap(0),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Cerca',
                isActive: _currentIndex == 1,
                onTap: () => _onNavTap(1),
              ),
              // Sell button — centrale
              GestureDetector(
                onTap: () => _onNavTap(2),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: SwabbitTheme.accentGrad,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: SwabbitTheme.accent.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded,
                      size: 26, color: Colors.black),
                ),
              ),
              _NavItem(
                icon: Icons.bookmark_rounded,
                label: 'Salvati',
                isActive: _currentIndex == 3,
                onTap: () => _onNavTap(3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profilo',
                isActive: _currentIndex == 4,
                onTap: () => _onNavTap(4),
              ),
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
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: isActive ? SwabbitTheme.accent : SwabbitTheme.text3),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 10,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? SwabbitTheme.accent : SwabbitTheme.text3,
                )),
          ],
        ),
      ),
    );
  }
}