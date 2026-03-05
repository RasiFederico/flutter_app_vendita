// lib/screens/chat_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/chat.dart';
import '../services/supabase_service.dart';
import '../services/audio_service.dart';

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

  // Teniamo traccia degli ID già visti per distinguere nuovi messaggi
  // in arrivo dallo stream dal caricamento iniziale.
  final Set<String> _seenIds = {};
  bool _initialLoadDone = false;

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
      if (mounted) {
        setState(() {
          _messages = msgs;
          // Segna tutti i messaggi iniziali come già visti
          _seenIds.addAll(msgs.map((m) => m.id));
          _initialLoadDone = true;
        });
        await SupabaseService.markMessagesAsRead(conv.id);
      }
    } catch (e) {
      debugPrint('ChatScreen load error: $e');
    }
    if (mounted) setState(() => _loading = false);
    _scrollToBottom();
  }

  void _subscribeRealtime() {
    _sub = SupabaseService.messagesStream(conv.id).listen((msgs) {
      if (!mounted) return;

      if (_initialLoadDone) {
        // Trova i messaggi realmente nuovi (non ancora visti)
        final newMsgs =
            msgs.where((m) => !_seenIds.contains(m.id)).toList();

        for (final msg in newMsgs) {
          _seenIds.add(msg.id);
          // Suona solo se il messaggio è di qualcun altro (non mio)
          if (msg.senderId != currentUserId) {
            AudioService.playMessageReceive();
          }
        }
      }

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

    // Suona subito, prima della risposta di rete: più reattivo
    AudioService.playMessageSend();

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
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(name, initials),
            if (conv.listingTitle != null) _buildListingBanner(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: SwabbitTheme.accent))
                  : _messages.isEmpty
                      ? _buildEmpty(name)
                      : _buildMessageList(),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(String name, String initials) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: SwabbitTheme.surface,
        border: Border(bottom: BorderSide(color: SwabbitTheme.border, width: 0.5)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: SwabbitTheme.text2),
        ),
        const SizedBox(width: 12),
        // Avatar
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
                  child: Image.network(conv.otherUserAvatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                            child: Text(initials,
                                style: const TextStyle(
                                    fontFamily: 'Syne',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Colors.black)),
                          )),
                )
              : Center(
                  child: Text(initials,
                      style: const TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.black)),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: SwabbitTheme.text)),
              if (conv.otherUserUsername != null)
                Text('@${conv.otherUserUsername}',
                    style: const TextStyle(
                        fontSize: 11, color: SwabbitTheme.text3)),
            ],
          ),
        ),
      ]),
    );
  }

  // ── LISTING BANNER ────────────────────────────────────────────────────────

  Widget _buildListingBanner() {
    final img = conv.listingImages?.isNotEmpty == true
        ? conv.listingImages!.first
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: SwabbitTheme.surface2,
        border: Border(bottom: BorderSide(color: SwabbitTheme.border, width: 0.5)),
      ),
      child: Row(children: [
        if (img != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(img,
                width: 36, height: 36, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(width: 36, height: 36, color: SwabbitTheme.surface)),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            conv.listingTitle ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SwabbitTheme.text2),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: SwabbitTheme.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: SwabbitTheme.accent.withOpacity(0.2)),
          ),
          child: const Text('Annuncio',
              style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: SwabbitTheme.accent)),
        ),
      ]),
    );
  }

  // ── EMPTY ─────────────────────────────────────────────────────────────────

  Widget _buildEmpty(String name) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: SwabbitTheme.accentGrad,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.black, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Inizia la conversazione con $name',
            style: const TextStyle(
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

  // ── MESSAGE LIST ──────────────────────────────────────────────────────────

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

  // ── INPUT ─────────────────────────────────────────────────────────────────

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
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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

// ── BUBBLE ────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? SwabbitTheme.accentGrad : null,
          color: isMe ? null : SwabbitTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: isMe ? null : Border.all(color: SwabbitTheme.border),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                  fontSize: 14,
                  color: isMe ? Colors.black : SwabbitTheme.text,
                  height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.black.withOpacity(0.5)
                      : SwabbitTheme.text3),
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