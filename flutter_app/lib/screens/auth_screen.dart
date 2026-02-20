import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../services/supabase_service.dart';
import 'main_scaffold.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = false;

  // Login fields
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginPassVisible = false;

  // Register fields
  final _regNomeCtrl = TextEditingController();
  final _regCognomeCtrl = TextEditingController();
  final _regUsernameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regPass2Ctrl = TextEditingController();
  bool _regPassVisible = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNomeCtrl.dispose();
    _regCognomeCtrl.dispose();
    _regUsernameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regPass2Ctrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? SwabbitTheme.accent3 : SwabbitTheme.green,
    ));
  }

  Future<void> _login() async {
    if (_loginEmailCtrl.text.isEmpty || _loginPassCtrl.text.isEmpty) {
      _showSnack('Compila tutti i campi', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.signIn(
        email: _loginEmailCtrl.text.trim(),
        password: _loginPassCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
    } on AuthException catch (e) {
      _showSnack(e.message, error: true);
    } catch (e) {
      _showSnack('Errore: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (_regNomeCtrl.text.isEmpty ||
        _regCognomeCtrl.text.isEmpty ||
        _regUsernameCtrl.text.isEmpty ||
        _regEmailCtrl.text.isEmpty ||
        _regPassCtrl.text.isEmpty) {
      _showSnack('Compila tutti i campi obbligatori', error: true);
      return;
    }
    if (_regPassCtrl.text != _regPass2Ctrl.text) {
      _showSnack('Le password non coincidono', error: true);
      return;
    }
    if (_regPassCtrl.text.length < 6) {
      _showSnack('La password deve avere almeno 6 caratteri', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.signUp(
        email: _regEmailCtrl.text.trim(),
        password: _regPassCtrl.text,
        nome: _regNomeCtrl.text.trim(),
        cognome: _regCognomeCtrl.text.trim(),
        username: _regUsernameCtrl.text.trim(),
      );
      if (!mounted) return;
      _showSnack('Registrazione avvenuta! Controlla la tua email per confermare.');
      _tab.animateTo(0);
    } on AuthException catch (e) {
      _showSnack(e.message, error: true);
    } catch (e) {
      _showSnack('Errore: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              _buildLogo(),
              const SizedBox(height: 32),
              _buildTabSelector(),
              const SizedBox(height: 28),
              _tab.index == 0 ? _buildLoginForm() : _buildRegisterForm(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: SwabbitTheme.accentGrad,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: SwabbitTheme.accent.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text('S',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.black)),
          ),
        ),
        const SizedBox(height: 14),
        const Text('SWABBIT',
            style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: SwabbitTheme.text,
                letterSpacing: 2)),
        const SizedBox(height: 4),
        const Text('Il marketplace per i tech enthusiast',
            style: TextStyle(fontSize: 13, color: SwabbitTheme.text2)),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SwabbitTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SwabbitTheme.border),
      ),
      child: Row(
        children: [
          _tabBtn('Accedi', 0),
          _tabBtn('Registrati', 1),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int idx) {
    final active = _tab.index == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tab.animateTo(idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: active ? SwabbitTheme.accentGrad : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.black : SwabbitTheme.text2,
                )),
          ),
        ),
      ),
    );
  }

  // ── LOGIN FORM ─────────────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    return Column(
      children: [
        _field(
          controller: _loginEmailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _loginPassCtrl,
          label: 'Password',
          icon: Icons.lock_outline,
          obscure: !_loginPassVisible,
          suffix: IconButton(
            icon: Icon(
              _loginPassVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: SwabbitTheme.text2,
              size: 20,
            ),
            onPressed: () => setState(() => _loginPassVisible = !_loginPassVisible),
          ),
        ),
        const SizedBox(height: 24),
        _primaryBtn('Accedi', _loading ? null : _login),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _tab.animateTo(1),
          child: const Text('Non hai un account? Registrati',
              style: TextStyle(fontSize: 13, color: SwabbitTheme.accent)),
        ),
      ],
    );
  }

  // ── REGISTER FORM ──────────────────────────────────────────────────────────

  Widget _buildRegisterForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _field(
                controller: _regNomeCtrl,
                label: 'Nome *',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                controller: _regCognomeCtrl,
                label: 'Cognome *',
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _field(
          controller: _regUsernameCtrl,
          label: 'Username *',
          icon: Icons.alternate_email,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _regEmailCtrl,
          label: 'Email *',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _regPassCtrl,
          label: 'Password *',
          icon: Icons.lock_outline,
          obscure: !_regPassVisible,
          suffix: IconButton(
            icon: Icon(
              _regPassVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: SwabbitTheme.text2,
              size: 20,
            ),
            onPressed: () => setState(() => _regPassVisible = !_regPassVisible),
          ),
        ),
        const SizedBox(height: 14),
        _field(
          controller: _regPass2Ctrl,
          label: 'Conferma password *',
          icon: Icons.lock_outline,
          obscure: !_regPassVisible,
        ),
        const SizedBox(height: 24),
        _primaryBtn('Crea account', _loading ? null : _register),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _tab.animateTo(0),
          child: const Text('Hai già un account? Accedi',
              style: TextStyle(fontSize: 13, color: SwabbitTheme.accent)),
        ),
      ],
    );
  }

  // ── SHARED WIDGETS ─────────────────────────────────────────────────────────

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: SwabbitTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SwabbitTheme.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: SwabbitTheme.text, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: SwabbitTheme.text2, fontSize: 13),
          prefixIcon: Icon(icon, color: SwabbitTheme.text3, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: onTap != null ? SwabbitTheme.accentGrad : null,
          color: onTap == null ? SwabbitTheme.surface3 : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: SwabbitTheme.accent.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2))
              : Text(label,
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  )),
        ),
      ),
    );
  }
}