import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../models/listing.dart';
import '../services/supabase_service.dart';
import 'listing_screen.dart';

// Categorie disponibili
const _categories = [
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

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _originalPriceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  ListingCondition _condition = ListingCondition.used;
  String? _category;
  bool _hasShipping = false;
  bool _isNegotiable = false;

  final List<XFile> _localImages = [];
  final Map<String, Uint8List> _imageBytes = {}; // path → bytes, per preview
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _originalPriceCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ── IMAGE PICKER ──────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    if (_localImages.length >= 6) {
      _snack('Puoi caricare al massimo 6 immagini', error: true);
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked.isEmpty) return;
    final remaining = 6 - _localImages.length;
    final toAdd = picked.take(remaining).toList();

    // Leggi i bytes subito (cross-platform: funziona su iOS, Android e Web)
    for (final xf in toAdd) {
      final bytes = await xf.readAsBytes();
      _imageBytes[xf.path] = bytes;
    }

    setState(() => _localImages.addAll(toAdd));
  }

  void _removeImage(int index) {
    final xf = _localImages[index];
    _imageBytes.remove(xf.path);
    setState(() => _localImages.removeAt(index));
  }

  // ── SUBMIT ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      setState(() => _errorMessage = 'Seleziona una categoria.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 1. Carica immagini su Storage
      final imageUrls = <String>[];
      for (final xf in _localImages) {
        final url = await SupabaseService.uploadListingImage(xf);
        imageUrls.add(url);
      }

      // 2. Crea annuncio nel DB
      final listing = await SupabaseService.createListing(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        originalPrice: _originalPriceCtrl.text.trim().isNotEmpty
            ? double.tryParse(_originalPriceCtrl.text.trim())
            : null,
        condition: _condition,
        category: _category,
        location: _locationCtrl.text.trim(),
        hasShipping: _hasShipping,
        isNegotiable: _isNegotiable,
        images: imageUrls,
      );

      if (!mounted) return;
      // Vai alla schermata dell'annuncio appena creato
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ListingScreen(listing: listing)),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Errore: $e');
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

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    _buildSectionTitle('Immagini'),
                    _buildImagePicker(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Dettagli'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _titleCtrl,
                      label: 'Titolo *',
                      hint: 'Es. RTX 4090 Founders Edition',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Il titolo è obbligatorio'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _descCtrl,
                      label: 'Descrizione',
                      hint: 'Condizioni, accessori inclusi, motivo della vendita...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Categoria'),
                    const SizedBox(height: 12),
                    _buildCategoryGrid(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Prezzo'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _priceCtrl,
                            label: 'Prezzo (€) *',
                            hint: '350',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Inserisci il prezzo';
                              if (double.tryParse(v) == null) return 'Prezzo non valido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _originalPriceCtrl,
                            label: 'Prezzo originale (€)',
                            hint: '500',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _CheckTile(
                          label: 'Trattabile',
                          value: _isNegotiable,
                          onChanged: (v) => setState(() => _isNegotiable = v),
                        ),
                        const SizedBox(width: 12),
                        _CheckTile(
                          label: 'Spedizione',
                          value: _hasShipping,
                          onChanged: (v) => setState(() => _hasShipping = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Condizione'),
                    const SizedBox(height: 12),
                    _buildConditionSelector(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Luogo'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _locationCtrl,
                      label: 'Città / Regione *',
                      hint: 'Es. Milano, Roma, Napoli...',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Inserisci la città'
                          : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SwabbitTheme.accent3.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: SwabbitTheme.accent3.withOpacity(0.4)),
                        ),
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: SwabbitTheme.accent3, fontSize: 13)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SwabbitTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SwabbitTheme.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: SwabbitTheme.text),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Crea annuncio',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: SwabbitTheme.text)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String label) {
    return Text(label,
        style: const TextStyle(
            fontFamily: 'Syne',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: SwabbitTheme.text));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: SwabbitTheme.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: SwabbitTheme.text2, fontSize: 13),
        hintStyle: const TextStyle(color: SwabbitTheme.text3, fontSize: 13),
        filled: true,
        fillColor: SwabbitTheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide: const BorderSide(color: SwabbitTheme.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SwabbitTheme.accent3),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add button
          if (_localImages.length < 6)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 88,
                height: 88,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: SwabbitTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: SwabbitTheme.accent.withOpacity(0.5),
                      style: BorderStyle.solid,
                      width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined,
                        color: SwabbitTheme.accent, size: 28),
                    const SizedBox(height: 4),
                    Text('${_localImages.length}/6',
                        style: const TextStyle(
                            fontSize: 10, color: SwabbitTheme.text3)),
                  ],
                ),
              ),
            ),
          // Image thumbnails
          ..._localImages.asMap().entries.map((entry) {
            final i = entry.key;
            final xf = entry.value;
            final bytes = _imageBytes[xf.path];
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: SwabbitTheme.surface2,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: bytes != null
                      ? Image.memory(bytes, width: 88, height: 88, fit: BoxFit.cover)
                      : const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: SwabbitTheme.accent)),
                ),
                Positioned(
                  top: -4,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _removeImage(i),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: SwabbitTheme.accent3,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ),
                if (i == 0)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: SwabbitTheme.accent.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Cover',
                          style: TextStyle(fontSize: 9, color: Colors.black)),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final (label, id, emoji) = cat;
        final selected = _category == id;
        return GestureDetector(
          onTap: () => setState(() => _category = id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: selected ? SwabbitTheme.accentGrad : null,
              color: selected ? null : SwabbitTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? SwabbitTheme.accent : SwabbitTheme.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.black : SwabbitTheme.text,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConditionSelector() {
    return Row(
      children: ListingCondition.values.map((c) {
        final selected = _condition == c;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _condition = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? c.color.withOpacity(0.15)
                    : SwabbitTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? c.color : SwabbitTheme.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(c.label,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? c.color : SwabbitTheme.text2,
                    )),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: _loading
          ? Container(
              decoration: BoxDecoration(
                gradient: SwabbitTheme.accentGrad,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                  ),
                ),
              ),
            )
          : GestureDetector(
              onTap: _submit,
              child: Container(
                decoration: BoxDecoration(
                  gradient: SwabbitTheme.accentGrad,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: SwabbitTheme.accent.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: const Center(
                  child: Text('Pubblica annuncio',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.black)),
                ),
              ),
            ),
    );
  }
}

// ── Helper widget ─────────────────────────────────────────────────────────────

class _CheckTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: value
                ? SwabbitTheme.accent.withOpacity(0.1)
                : SwabbitTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value ? SwabbitTheme.accent : SwabbitTheme.border,
              width: value ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                value ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 16,
                color: value ? SwabbitTheme.accent : SwabbitTheme.text3,
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: value ? SwabbitTheme.accent : SwabbitTheme.text2,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}