// lib/screens/chat_list_screen.dart

import 'package:flutter/material.dart';
import '../main.dart';
import '../models/chat.dart';
import '../services/supabase_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Conversation> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SupabaseService.getConversations();
      if (mounted) setState(() => _conversations = res);
    } catch (e) {
      debugPrint('ChatList error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Messaggi',
            style: TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: SwabbitTheme.text,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SwabbitTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SwabbitTheme.border),
            ),
            child: const Icon(Icons.edit_square, size: 18, color: SwabbitTheme.text2),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: SwabbitTheme.accent, strokeWidth: 2),
      );
    }
    if (_conversations.isEmpty) {
      return _buildEmpty();
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: SwabbitTheme.accent,
      backgroundColor: SwabbitTheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _conversations.length,
        itemBuilder: (ctx, i) => _ConversationTile(
          conversation: _conversations[i],
          onTap: () => _openChat(_conversations[i]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: SwabbitTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SwabbitTheme.border),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 32, color: SwabbitTheme.text3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nessun messaggio',
            style: TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: SwabbitTheme.text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Contatta un venditore da un annuncio\nper iniziare una conversazione.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: SwabbitTheme.text2, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _openChat(Conversation conv) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
    ).then((_) => _load());
  }
}

// ─── TILE ────────────────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final conv = conversation;
    final name = conv.otherUserName ?? 'Utente';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hasThumb =
        conv.listingImages != null && conv.listingImages!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: SwabbitTheme.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: SwabbitTheme.accentGrad,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: conv.otherUserAvatarUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            conv.otherUserAvatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _AvatarInitial(initials),
                          ),
                        )
                      : _AvatarInitial(initials),
                ),
                // Listing thumbnail badge
                if (hasThumb)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: SwabbitTheme.bg, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.5),
                        child: Image.network(
                          conv.listingImages![0],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: SwabbitTheme.surface3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Syne',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: SwabbitTheme.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.lastMessageAt != null)
                        Text(
                          _formatTime(conv.lastMessageAt!),
                          style: const TextStyle(
                              fontSize: 11, color: SwabbitTheme.text3),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (conv.listingTitle != null)
                    Text(
                      conv.listingTitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: SwabbitTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    conv.lastMessage ?? 'Nessun messaggio',
                    style: const TextStyle(
                        fontSize: 13, color: SwabbitTheme.text2),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'ora';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}g';
    return '${dt.day}/${dt.month}';
  }
}

class _AvatarInitial extends StatelessWidget {
  final String initial;
  const _AvatarInitial(this.initial);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: 'Syne',
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: Colors.black,
        ),
      ),
    );
  }
}