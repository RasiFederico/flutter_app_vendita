// lib/screens/chat_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/chat.dart';
import '../services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<ChatMessage>>? _sub;

  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;

  Conversation get conv => widget.conversation;
  String get currentUserId => SupabaseService.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final msgs = await SupabaseService.getMessages(conv.id);
      if (mounted) setState(() => _messages = msgs);
      await SupabaseService.markMessagesAsRead(conv.id);
    } catch (e) {
      debugPrint('ChatScreen load error: $e');
    }
    if (mounted) setState(() => _loading = false);
    _scrollToBottom();
  }

  void _subscribeRealtime() {
    _sub = SupabaseService.messagesStream(conv.id).listen((msgs) {
      if (!mounted) return;
      setState(() => _messages = msgs);
      SupabaseService.markMessagesAsRead(conv.id);
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    _controller.clear();
    setState(() => _sending = true);
    try {
      await SupabaseService.sendMessage(
        conversationId: conv.id,
        content: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Errore nell\'invio del messaggio'),
            backgroundColor: SwabbitTheme.accent3,
          ),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final name = conv.otherUserName ?? 'Utente';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: SwabbitTheme.bg,
      appBar: _buildAppBar(name, initials),
      body: Column(
        children: [
          // Listing banner
          if (conv.listingTitle != null) _buildListingBanner(),
          // Messages
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: SwabbitTheme.accent, strokeWidth: 2))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),
          // Input
          _buildInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String name, String initials) {
    return AppBar(
      backgroundColor: SwabbitTheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: SwabbitTheme.text, size: 18),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: SwabbitTheme.accentGrad,
              borderRadius: BorderRadius.circular(11),
            ),
            child: conv.otherUserAvatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      conv.otherUserAvatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _AvatarInitial(initials),
                    ),
                  )
                : _AvatarInitial(initials),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: SwabbitTheme.text,
                ),
              ),
              if (conv.otherUserUsername != null &&
                  conv.otherUserUsername!.isNotEmpty)
                Text(
                  '@${conv.otherUserUsername}',
                  style: const TextStyle(
                      fontSize: 11, color: SwabbitTheme.text3),
                ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: SwabbitTheme.border),
      ),
    );
  }

  Widget _buildListingBanner() {
    final hasImg =
        conv.listingImages != null && conv.listingImages!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SwabbitTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SwabbitTheme.border),
      ),
      child: Row(
        children: [
          if (hasImg)
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                conv.listingImages![0],
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SwabbitTheme.surface3,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.image_outlined,
                      color: SwabbitTheme.text3, size: 18),
                ),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SwabbitTheme.surface3,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: SwabbitTheme.text3, size: 18),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ANNUNCIO',
                  style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 9,
                      color: SwabbitTheme.text3,
                      letterSpacing: 0.5),
                ),
                Text(
                  conv.listingTitle!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SwabbitTheme.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: SwabbitTheme.text3, size: 18),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.waving_hand_rounded,
              size: 40, color: SwabbitTheme.accent),
          const SizedBox(height: 12),
          const Text(
            'Inizia la conversazione!',
            style: TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: SwabbitTheme.text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Scrivi un messaggio qui sotto.',
            style: TextStyle(fontSize: 13, color: SwabbitTheme.text2),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final isMe = msg.senderId == currentUserId;
        final showDate = i == 0 ||
            _messages[i].createdAt.day != _messages[i - 1].createdAt.day;
        return Column(
          children: [
            if (showDate) _buildDateDivider(msg.createdAt),
            _MessageBubble(message: msg, isMe: isMe),
          ],
        );
      },
    );
  }

  Widget _buildDateDivider(DateTime dt) {
    final now = DateTime.now();
    String label;
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      label = 'Oggi';
    } else if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day - 1) {
      label = 'Ieri';
    } else {
      label = '${dt.day}/${dt.month}/${dt.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: SwabbitTheme.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: SwabbitTheme.text3)),
          ),
          const Expanded(child: Divider(color: SwabbitTheme.border)),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: SwabbitTheme.surface,
        border: const Border(
            top: BorderSide(color: SwabbitTheme.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: SwabbitTheme.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SwabbitTheme.border),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  style: const TextStyle(
                      color: SwabbitTheme.text, fontSize: 14),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Scrivi un messaggio...',
                    hintStyle: TextStyle(
                        color: SwabbitTheme.text3, fontSize: 14),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: SwabbitTheme.accentGrad,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: SwabbitTheme.accent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _sending
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.black, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BUBBLE ──────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? SwabbitTheme.accentGrad : null,
          color: isMe ? null : SwabbitTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
          border: isMe ? null : Border.all(color: SwabbitTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.black : SwabbitTheme.text,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.black.withOpacity(0.5)
                        : SwabbitTheme.text3,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 3),
                  Icon(
                    message.read
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 12,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
          fontSize: 15,
          color: Colors.black,
        ),
      ),
    );
  }
}