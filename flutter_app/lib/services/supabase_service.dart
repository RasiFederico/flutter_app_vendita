import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/listing.dart';

// ─── Costanti — sostituisci con i tuoi valori da supabase.com ────────────────
const String supabaseUrl = '';
const String supabaseAnonKey = ''; // anon/public key

/// Nome del bucket Storage per le immagini degli annunci
const String _listingBucket = 'listing-images';

class SupabaseService {
  SupabaseService._();
  static final SupabaseClient client = Supabase.instance.client;

  // ── AUTH ──────────────────────────────────────────────────────────────────

  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;
  static bool get isLoggedIn => currentUser != null;

  /// Registrazione con email + password. Crea automaticamente il profilo.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nome,
    required String cognome,
    required String username,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'nome': nome, 'cognome': cognome, 'username': username},
    );
    if (res.user != null) {
      await _upsertProfile(
        userId: res.user!.id,
        nome: nome,
        cognome: cognome,
        username: username,
      );
    }
    return res;
  }

  /// Login con email + password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  /// Logout
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ── PROFILO ───────────────────────────────────────────────────────────────

  static Future<void> _upsertProfile({
    required String userId,
    required String nome,
    required String cognome,
    required String username,
  }) async {
    await client.from('profiles').upsert({
      'id': userId,
      'nome': nome,
      'cognome': cognome,
      'username': username,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Legge il profilo dell'utente corrente
  static Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final res = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return res;
  }

  /// Aggiorna il profilo
  static Future<void> updateProfile({
    required String nome,
    required String cognome,
    required String username,
    String? bio,
    String? luogo,
    String? telefono,
  }) async {
    final user = currentUser;
    if (user == null) return;
    await client.from('profiles').upsert({
      'id': user.id,
      'nome': nome,
      'cognome': cognome,
      'username': username,
      'bio': bio,
      'luogo': luogo,
      'telefono': telefono,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ── ANNUNCI (LISTINGS) ────────────────────────────────────────────────────

  /// Crea un nuovo annuncio per l'utente corrente.
  /// Ritorna il Listing creato con l'id assegnato da Supabase.
  static Future<Listing> createListing({
    required String title,
    required String description,
    required double price,
    double? originalPrice,
    required ListingCondition condition,
    String? category,
    required String location,
    bool hasShipping = false,
    bool isNegotiable = false,
    List<String> images = const [],
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Devi essere loggato per creare un annuncio.');

    final payload = {
      'user_id': user.id,
      'title': title,
      'description': description,
      'price': price,
      if (originalPrice != null) 'original_price': originalPrice,
      'condition': condition.dbValue,
      if (category != null) 'category': category,
      'location': location,
      'has_shipping': hasShipping,
      'is_negotiable': isNegotiable,
      'status': 'active',
      'images': images,
    };

    final res = await client
        .from('listings')
        .insert(payload)
        .select()
        .single();

    return Listing.fromMap(res);
  }

  /// Recupera tutti gli annunci dell'utente corrente (tutti gli status).
  static Future<List<Listing>> getMyListings() async {
    final user = currentUser;
    if (user == null) return [];

    final res = await client
        .from('listings')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (res as List).map((e) => Listing.fromMap(e)).toList();
  }

  /// Recupera gli annunci di un altro utente (solo status active).
  static Future<List<Listing>> getUserListings(String userId) async {
    final res = await client
        .from('listings')
        .select()
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return (res as List).map((e) => Listing.fromMap(e)).toList();
  }

  /// Cerca annunci con testo libero e filtri opzionali.
  /// Usa ilike su title e description per la ricerca testuale.
  static Future<List<Listing>> searchListings({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    ListingCondition? condition,
    String? location,
    int limit = 40,
  }) async {
    var q = client
        .from('listings')
        .select('*, profiles(nome, cognome, username, rating, sales_count)')
        .eq('status', 'active');

    if (query != null && query.trim().isNotEmpty) {
      // Ricerca su title OPPURE description (OR con ilike)
      q = q.or('title.ilike.%${query.trim()}%,description.ilike.%${query.trim()}%');
    }
    if (category != null && category.isNotEmpty) {
      q = q.eq('category', category);
    }
    if (minPrice != null) q = q.gte('price', minPrice);
    if (maxPrice != null) q = q.lte('price', maxPrice);
    if (condition != null) q = q.eq('condition', condition.dbValue);
    if (location != null && location.isNotEmpty) {
      q = q.ilike('location', '%$location%');
    }

    final res = await q
        .order('created_at', ascending: false)
        .limit(limit);

    return (res as List).map((e) => Listing.fromMap(e)).toList();
  }

  /// Recupera annunci recenti (home feed).
  static Future<List<Listing>> getRecentListings({int limit = 20}) async {
    final res = await client
        .from('listings')
        .select('*, profiles(nome, cognome, username, rating, sales_count)')
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(limit);

    return (res as List).map((e) => Listing.fromMap(e)).toList();
  }

  /// Singolo annuncio con profilo venditore.
  static Future<Listing?> getListingById(String id) async {
    final res = await client
        .from('listings')
        .select('*, profiles(nome, cognome, username, rating, sales_count)')
        .eq('id', id)
        .maybeSingle();

    return res != null ? Listing.fromMap(res) : null;
  }

  /// Aggiorna lo status di un annuncio (solo proprietario).
  static Future<void> updateListingStatus(String id, ListingStatus status) async {
    await client
        .from('listings')
        .update({'status': status.dbValue, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('user_id', currentUser!.id);
  }

  /// Elimina un annuncio (solo proprietario).
  static Future<void> deleteListing(String id) async {
    await client
        .from('listings')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUser!.id);
  }

  // ── STORAGE IMMAGINI ──────────────────────────────────────────────────────

  /// Carica un'immagine nel bucket 'listing-images'.
  /// Accetta un [XFile] da image_picker — funziona su iOS, Android e Web.
  /// Ritorna la URL pubblica del file.
  static Future<String> uploadListingImage(XFile xfile) async {
    final user = currentUser;
    if (user == null) throw Exception('Devi essere loggato per caricare immagini.');

    final ext = xfile.path.contains('.')
        ? xfile.path.split('.').last.toLowerCase()
        : 'jpg';
    final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

    // readAsBytes() funziona su tutte le piattaforme (niente dart:io)
    final bytes = await xfile.readAsBytes();

    await client.storage
        .from(_listingBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _mimeType(ext),
            upsert: false,
          ),
        );

    return client.storage.from(_listingBucket).getPublicUrl(path);
  }

  /// Elimina una o più immagini dallo storage dato il path pubblico.
  static Future<void> deleteListingImages(List<String> publicUrls) async {
    final paths = publicUrls.map((url) {
      // Estrae il path relativo dalla URL pubblica
      final marker = '$_listingBucket/';
      final idx = url.indexOf(marker);
      return idx >= 0 ? url.substring(idx + marker.length) : url;
    }).toList();

    await client.storage.from(_listingBucket).remove(paths);
  }

  static String _mimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      case 'webp': return 'image/webp';
      default:     return 'application/octet-stream';
    }
  }
}