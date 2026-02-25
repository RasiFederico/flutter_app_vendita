import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../services/supabase_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _cognomeCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _luogoCtrl;
  late final TextEditingController _telefonoCtrl;

  bool _loading = false;
  bool _avatarLoading = false;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nomeCtrl = TextEditingController(text: p['nome'] ?? '');
    _cognomeCtrl = TextEditingController(text: p['cognome'] ?? '');
    _usernameCtrl = TextEditingController(text: p['username'] ?? '');
    _bioCtrl = TextEditingController(text: p['bio'] ?? '');
    _luogoCtrl = TextEditingController(text: p['luogo'] ?? '');
    _telefonoCtrl = TextEditingController(text: p['telefono'] ?? '');
    _currentAvatarUrl = p['avatar_url']?.toString();
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

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (xfile == null) return;

    setState(() => _avatarLoading = true);
    try {
      final url = await SupabaseService.uploadProfileAvatar(xfile);
      // Aggiorna anche il profilo nel DB con la nuova URL
      await SupabaseService.updateProfile(
        nome: _nomeCtrl.text.trim(),
        cognome: _cognomeCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : null,
        luogo:
            _luogoCtrl.text.trim().isNotEmpty ? _luogoCtrl.text.trim() : null,
        telefono: _telefonoCtrl.text.trim().isNotEmpty
            ? _telefonoCtrl.text.trim()
            : null,
        avatarUrl: url,
      );
      if (mounted) setState(() => _currentAvatarUrl = url);
      _snack('Foto profilo aggiornata!');
    } catch (e) {
      _snack('Errore caricamento foto: $e', error: true);
    } finally {
      if (mounted) setState(() => _avatarLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await SupabaseService.updateProfile(
        nome: _nomeCtrl.text.trim(),
        cognome: _cognomeCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : null,
        luogo:
            _luogoCtrl.text.trim().isNotEmpty ? _luogoCtrl.text.trim() : null,
        telefono: _telefonoCtrl.text.trim().isNotEmpty
            ? _telefonoCtrl.text.trim()
            : null,
        avatarUrl: _currentAvatarUrl,
      );
      _snack('Profilo salvato!');
      Navigator.of(context).pop(true);
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

  String get _initials {
    final n =
        _nomeCtrl.text.isNotEmpty ? _nomeCtrl.text[0].toUpperCase() : '';
    final c = _cognomeCtrl.text.isNotEmpty
        ? _cognomeCtrl.text[0].toUpperCase()
        : '';
    return '$n$c';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      appBar: AppBar(
        backgroundColor: SwabbitTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: SwabbitTheme.text, size: 20),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── AVATAR ──────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _avatarLoading ? null : _pickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: SwabbitTheme.accentGrad,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: SwabbitTheme.accent.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: _avatarLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2))
                              : _currentAvatarUrl != null
                                  ? Image.network(
                                      _currentAvatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _initialsAvatar(),
                                    )
                                  : _initialsAvatar(),
                        ),
                      ),
                      // Camera badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: SwabbitTheme.accent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: SwabbitTheme.bg, width: 2.5),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 14, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Tocca per cambiare foto',
                    style: const TextStyle(
                        fontSize: 12, color: SwabbitTheme.text3),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── FIELDS ──────────────────────────────────────────────
              _sectionTitle('Dati personali'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _nomeCtrl,
                      label: 'Nome *',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _cognomeCtrl,
                      label: 'Cognome *',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _usernameCtrl,
                label: 'Username *',
                hint: '@username',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
              ),
              const SizedBox(height: 24),
              _sectionTitle('Informazioni aggiuntive'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _bioCtrl,
                label: 'Bio',
                hint: 'Scrivi qualcosa di te...',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _luogoCtrl,
                label: 'Luogo',
                hint: 'Es. Milano, Italia',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _telefonoCtrl,
                label: 'Telefono',
                hint: '+39 ...',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialsAvatar() {
    return Center(
      child: Text(
        _initials.isEmpty ? '?' : _initials,
        style: const TextStyle(
            fontFamily: 'Syne',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.black),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontFamily: 'Syne',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: SwabbitTheme.text3,
            letterSpacing: 0.5));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: SwabbitTheme.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            const TextStyle(color: SwabbitTheme.text3, fontSize: 13),
        hintStyle:
            const TextStyle(color: SwabbitTheme.text3, fontSize: 13),
        filled: true,
        fillColor: SwabbitTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwabbitTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwabbitTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: SwabbitTheme.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwabbitTheme.accent3),
        ),
      ),
    );
  }
}