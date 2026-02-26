import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/listing.dart';
import '../models/chat.dart';

// ─── Costanti — sostituisci con i tuoi valori da supabase.com ────────────────
const String supabaseUrl = '';
const String supabaseAnonKey = ''; // anon/public key

/// Nome del bucket Storage per le immagini degli annunci
const String _listingBucket = 'listing-images';

/// Nome del bucket Storage per gli avatar utente
const String _avatarBucket = 'avatars';

class SupabaseService {
  SupabaseService._();
  static final SupabaseClient client = Supabase.instance.client;

  // ── AUTH ──────────────────────────────────────────────────────────────────

  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;
  static bool get isLoggedIn => currentUser != null;
  
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

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

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
        .select('id, nome, cognome, username, bio, luogo, telefono, avatar_url, rating, sales_count, created_at, updated_at')
        .eq('id', user.id)
        .maybeSingle();
    return res;
  }

  /// Legge il profilo pubblico di un qualsiasi utente per id
  static Future<Map<String, dynamic>?> getUserProfileById(String userId) async {
    final res = await client
        .from('profiles')
        .select('id, nome, cognome, username, bio, luogo, telefono, avatar_url, rating, sales_count, created_at, updated_at')
        .eq('id', userId)
        .maybeSingle();
    return res;
  }

  /// Aggiorna il profilo (opzionalmente con avatar_url)
  static Future<void> updateProfile({
    required String nome,
    required String cognome,
    required String username,
    String? bio,
    String? luogo,
    String? telefono,
    String? avatarUrl,
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
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ── ANNUNCI (LISTINGS) ────────────────────────────────────────────────────

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

    final res = await client.from('listings').insert(payload).select().single();
    return Listing.fromMap(res);
  }

  /// Recupera tutti gli annunci dell'utente corrente (tutti gli status).
  /// Include il join con profiles per mostrare il nome del venditore.
  static Future<List<Listing>> getMyListings() async {
    final user = currentUser;
    if (user == null) return [];

    final res = await client
        .from('listings')
        .select('*, profiles(nome, cognome, username, avatar_url, rating, sales_count)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (res as List).map((e) => Listing.fromMap(e)).toList();
  }

  /// Recupera gli annunci attivi di un utente specifico (per profilo pubblico).
  static Future<List<Listing>> getUserListings(String userId) async {
    final res = await client
        .from('listings')
        .select('*, profiles(nome, cognome, username, avatar_url, rating, sales_count)')
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return (res as List).map((e) => Listing.fromMap(e)).toList();
  }

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
        .select('*, profiles(nome, cognome, username, avatar_url, rating, sales_count)')
        .eq('status', 'active');

    if (query != null && query.trim().isNotEmpty) {
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

    final res = await q.order('created_at', ascending: false).limit(limit);
    return (res as List).map((e) => Listing.fromMap(e)).toList();
  }

  static Future<List<Listing>> getRecentListings({int limit = 20}) async {
    final res = await client
        .from('listings')
        .select('*, profiles(nome, cognome, username, avatar_url, rating, sales_count)')
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(limit);

    return (res as List).map((e) => Listing.fromMap(e)).toList();
  }

  static Future<Listing?> getListingById(String id) async {
    final res = await client
        .from('listings')
        .select('*, profiles(nome, cognome, username, avatar_url, rating, sales_count)')
        .eq('id', id)
        .maybeSingle();

    return res != null ? Listing.fromMap(res) : null;
  }

  static Future<void> updateListingStatus(String id, ListingStatus status) async {
    await client
        .from('listings')
        .update({'status': status.dbValue, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('user_id', currentUser!.id);
  }

  /// Elimina un annuncio e le relative immagini dallo Storage.
  static Future<void> deleteListing(String id) async {
    final user = currentUser;
    if (user == null) return;

    // 1. Recupera le URL delle immagini prima di eliminare
    final row = await client
        .from('listings')
        .select('images')
        .eq('id', id)
        .eq('user_id', user.id)
        .maybeSingle();

    if (row != null) {
      final images = (row['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (images.isNotEmpty) {
        // 2. Estrai i path relativi dal bucket (es. "userId/filename.jpg")
        final paths = images
            .map((url) {
              try {
                final uri = Uri.parse(url);
                // Il path dopo "/object/public/listing-images/" è il path nel bucket
                final segments = uri.pathSegments;
                final bucketIdx = segments.indexOf(_listingBucket);
                if (bucketIdx >= 0 && bucketIdx + 1 < segments.length) {
                  return segments.sublist(bucketIdx + 1).join('/');
                }
              } catch (_) {}
              return null;
            })
            .whereType<String>()
            .toList();

        if (paths.isNotEmpty) {
          try {
            await client.storage.from(_listingBucket).remove(paths);
          } catch (_) {
            // Se il file era già stato rimosso, ignora l'errore
          }
        }
      }
    }

    // 3. Elimina il record dal database
    await client
        .from('listings')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  // ── STORAGE IMMAGINI ──────────────────────────────────────────────────────

  static Future<String> uploadListingImage(XFile xfile) async {
    final user = currentUser;
    if (user == null) throw Exception('Devi essere loggato per caricare immagini.');

    final bytes = await xfile.readAsBytes();
    final ext = xfile.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await client.storage
        .from(_listingBucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime, upsert: true));

    return client.storage.from(_listingBucket).getPublicUrl(path);
  }

  // ── STORAGE AVATAR ────────────────────────────────────────────────────────

  /// Carica/sostituisce la foto profilo dell'utente corrente.
  /// Ritorna la URL pubblica.
  static Future<String> uploadProfileAvatar(XFile xfile) async {
    final user = currentUser;
    if (user == null) throw Exception('Devi essere loggato per caricare un avatar.');

    final bytes = await xfile.readAsBytes();
    final ext = xfile.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    // Usa sempre lo stesso filename così sovrascrive il vecchio avatar
    final path = '${user.id}/avatar.$ext';

    await client.storage
        .from(_avatarBucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime, upsert: true));

    // Aggiungi un cache-buster per forzare il refresh dell'immagine
    final url = client.storage.from(_avatarBucket).getPublicUrl(path);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  // ── CHAT ─────────────────────────────────────────────────────────────────────

  /// Crea o recupera una conversazione esistente tra buyer e seller per un annuncio.
  static Future<Conversation> getOrCreateConversation({
    required String sellerId,
    required String listingId,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Devi essere loggato');
    final buyerId = user.id;

    // Cerca se esiste già
    final existing = await client
        .from('conversations')
        .select('id, listing_id, buyer_id, seller_id, last_message, last_message_at, created_at')
        .eq('listing_id', listingId)
        .eq('buyer_id', buyerId)
        .eq('seller_id', sellerId)
        .maybeSingle();

    late Map<String, dynamic> convRow;
    if (existing != null) {
      convRow = existing;
    } else {
      convRow = await client
          .from('conversations')
          .insert({
            'listing_id': listingId,
            'buyer_id': buyerId,
            'seller_id': sellerId,
          })
          .select('id, listing_id, buyer_id, seller_id, last_message, last_message_at, created_at')
          .single();
    }

    return _hydrateConversation(convRow, buyerId);
  }

  /// Lista di tutte le conversazioni dell'utente corrente.
  static Future<List<Conversation>> getConversations() async {
    final user = currentUser;
    if (user == null) return [];

    final rows = await client
        .from('conversations')
        .select('id, listing_id, buyer_id, seller_id, last_message, last_message_at, created_at')
        .or('buyer_id.eq.${user.id},seller_id.eq.${user.id}')
        .order('last_message_at', ascending: false);

    final list = rows as List<dynamic>;
    return Future.wait(
      list.map((r) => _hydrateConversation(r as Map<String, dynamic>, user.id)),
    );
  }

  /// Arricchisce una riga di conversations con profilo dell'altro utente + listing.
  static Future<Conversation> _hydrateConversation(
      Map<String, dynamic> row, String currentUserId) async {
    final isBuyer = (row['buyer_id'] as String) == currentUserId;
    final otherUserId =
        isBuyer ? row['seller_id'] as String : row['buyer_id'] as String;

    // Carica profilo dell'altro utente
    Map<String, dynamic>? otherProfile;
    try {
      otherProfile = await client
          .from('profiles')
          .select('nome, cognome, username, avatar_url')
          .eq('id', otherUserId)
          .maybeSingle();
    } catch (_) {}

    // Carica listing (opzionale)
    Map<String, dynamic>? listing;
    final listingId = row['listing_id'] as String?;
    if (listingId != null) {
      try {
        listing = await client
            .from('listings')
            .select('title, images')
            .eq('id', listingId)
            .maybeSingle();
      } catch (_) {}
    }

    // Costruisci il nome da mostrare
    final nome = (otherProfile?['nome'] as String? ?? '').trim();
    final cognome = (otherProfile?['cognome'] as String? ?? '').trim();
    final fullName = '$nome $cognome'.trim();
    final username = (otherProfile?['username'] as String? ?? '').trim();
    final displayName =
        fullName.isNotEmpty ? fullName : username.isNotEmpty ? username : 'Utente';

    return Conversation(
      id: row['id'] as String,
      listingId: listingId,
      buyerId: row['buyer_id'] as String,
      sellerId: row['seller_id'] as String,
      lastMessage: row['last_message'] as String?,
      lastMessageAt: row['last_message_at'] != null
          ? DateTime.parse(row['last_message_at'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
      otherUserName: displayName,
      otherUserUsername: username.isNotEmpty ? username : null,
      otherUserAvatarUrl: otherProfile?['avatar_url'] as String?,
      listingTitle: listing?['title'] as String?,
      listingImages: (listing?['images'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  /// Messaggi di una conversazione, ordinati dal più vecchio al più recente.
  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    final res = await client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (res as List).map((e) => ChatMessage.fromMap(e)).toList();
  }

  /// Invia un messaggio e aggiorna last_message sulla conversazione.
  static Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Devi essere loggato');

    final res = await client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': user.id,
          'content': content.trim(),
        })
        .select()
        .single();

    await client.from('conversations').update({
      'last_message': content.trim(),
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);

    return ChatMessage.fromMap(res);
  }

  /// Segna tutti i messaggi non letti di una conversazione come letti.
  static Future<void> markMessagesAsRead(String conversationId) async {
    final user = currentUser;
    if (user == null) return;
    await client
        .from('messages')
        .update({'read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', user.id)
        .eq('read', false);
  }

  /// Stream real-time dei messaggi di una conversazione.
  static Stream<List<ChatMessage>> messagesStream(String conversationId) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map((e) => ChatMessage.fromMap(e)).toList());
  }

  /// Stream real-time delle conversazioni dell'utente.
  static Stream<List<Map<String, dynamic>>> conversationsStream() {
    final user = currentUser;
    if (user == null) return const Stream.empty();
    return client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .map((rows) => rows
            .where((r) =>
                r['buyer_id'] == user.id || r['seller_id'] == user.id)
            .toList());
  }
}