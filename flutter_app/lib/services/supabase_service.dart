import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Costanti — sostituisci con i tuoi valori da supabase.com ────────────────
const String supabaseUrl = '';
const String supabaseAnonKey = ''; // anon/public key

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
}