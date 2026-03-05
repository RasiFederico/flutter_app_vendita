// lib/services/audio_service.dart
//
// Servizio centralizzato per la riproduzione dei suoni dell'app.
// Usa il package `audioplayers` per riprodurre file .mp3 dalla cartella assets/audio/.
//
// File audio attesi in assets/audio/:
//   • favorite_add.mp3    → quando si aggiunge un annuncio ai preferiti
//   • favorite_remove.mp3 → quando si rimuove un annuncio dai preferiti
//   • message_send.mp3    → quando si invia un messaggio
//   • message_receive.mp3 → quando si riceve un messaggio

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();

  // Pool di player leggeri: uno per categoria evita sovrapposizioni indesiderate
  static final AudioPlayer _favPlayer  = AudioPlayer();
  static final AudioPlayer _chatPlayer = AudioPlayer();

  // ── PUBLIC API ─────────────────────────────────────────────────────────────

  /// Suono aggiunta ai preferiti (❤ on)
  static Future<void> playFavoriteAdd() async {
    await _play(_favPlayer, 'audio/favorite_add.mp3');
  }

  /// Suono rimozione dai preferiti (❤ off)
  static Future<void> playFavoriteRemove() async {
    await _play(_favPlayer, 'audio/favorite_remove.mp3');
  }

  /// Suono invio messaggio
  static Future<void> playMessageSend() async {
    await _play(_chatPlayer, 'audio/message_send.mp3');
  }

  /// Suono ricezione messaggio
  static Future<void> playMessageReceive() async {
    await _play(_chatPlayer, 'audio/message_receive.mp3');
  }

  // ── INTERNAL ──────────────────────────────────────────────────────────────

  static Future<void> _play(AudioPlayer player, String assetPath) async {
    try {
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Ignoriamo gli errori audio silenziosamente: non bloccano l'UX
    }
  }
}