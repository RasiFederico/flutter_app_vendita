import 'package:flutter/material.dart';
import '../main.dart';
import '../services/supabase_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _cognomeCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _luogoCtrl;
  late final TextEditingController _telefonoCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nomeCtrl     = TextEditingController(text: p['nome'] ?? '');
    _cognomeCtrl  = TextEditingController(text: p['cognome'] ?? '');
    _usernameCtrl = TextEditingController(text: p['username'] ?? '');
    _bioCtrl      = TextEditingController(text: p['bio'] ?? '');
    _luogoCtrl    = TextEditingController(text: p['luogo'] ?? '');
    _telefonoCtrl = TextEditingController(text: p['telefono'] ?? '');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cognomeCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _luogoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nomeCtrl.text.isEmpty || _cognomeCtrl.text.isEmpty || _usernameCtrl.text.isEmpty) {
      _snack('Nome, cognome e username sono obbligatori', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.updateProfile(
        nome:      _nomeCtrl.text.trim(),
        cognome:   _cognomeCtrl.text.trim(),
        username:  _usernameCtrl.text.trim(),
        bio:       _bioCtrl.text.trim(),
        luogo:     _luogoCtrl.text.trim(),
        telefono:  _telefonoCtrl.text.trim(),
      );
      if (!mounted) return;
      _snack('Profilo aggiornato!');
      Navigator.of(context).pop(true); // true = aggiornato
    } catch (e) {
      _snack('Errore: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? SwabbitTheme.accent3 : SwabbitTheme.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      appBar: AppBar(
        backgroundColor: SwabbitTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: SwabbitTheme.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Modifica profilo',
            style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: SwabbitTheme.text)),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: SwabbitTheme.accent, strokeWidth: 2))
                : const Text('Salva',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w700,
                        color: SwabbitTheme.accent,
                        fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar placeholder
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: SwabbitTheme.accentGrad,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Center(
                      child: Text(
                        _nomeCtrl.text.isNotEmpty
                            ? _nomeCtrl.text[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.black),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: SwabbitTheme.accent2,
                        shape: BoxShape.circle,
                        border: Border.all(color: SwabbitTheme.bg, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_outlined,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _sectionTitle('Informazioni personali'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_nomeCtrl, 'Nome *', Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(child: _field(_cognomeCtrl, 'Cognome *', Icons.person_outline)),
              ],
            ),
            const SizedBox(height: 12),
            _field(_usernameCtrl, 'Username *', Icons.alternate_email),
            const SizedBox(height: 12),
            _field(_luogoCtrl, 'Città / Luogo', Icons.location_on_outlined),
            const SizedBox(height: 12),
            _field(_telefonoCtrl, 'Telefono', Icons.phone_outlined,
                keyboardType: TextInputType.phone),

            const SizedBox(height: 24),
            _sectionTitle('Bio'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: SwabbitTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SwabbitTheme.border),
              ),
              child: TextField(
                controller: _bioCtrl,
                maxLines: 4,
                maxLength: 180,
                style: const TextStyle(color: SwabbitTheme.text, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Racconta qualcosa di te...',
                  hintStyle: TextStyle(color: SwabbitTheme.text3, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  counterStyle: TextStyle(color: SwabbitTheme.text3, fontSize: 11),
                ),
              ),
            ),

            const SizedBox(height: 32),
            // Salva button in fondo
            GestureDetector(
              onTap: _loading ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: SwabbitTheme.accentGrad,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: SwabbitTheme.accent.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('Salva modifiche',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontFamily: 'Syne',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: SwabbitTheme.text2,
          letterSpacing: 0.5));

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: SwabbitTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SwabbitTheme.border),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: SwabbitTheme.text, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: SwabbitTheme.text2, fontSize: 13),
          prefixIcon: Icon(icon, color: SwabbitTheme.text3, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}