// lib/models/chat.dart

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool read;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.read,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] as String,
        conversationId: map['conversation_id'] as String,
        senderId: map['sender_id'] as String,
        content: map['content'] as String,
        read: map['read'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class Conversation {
  final String id;
  final String? listingId;
  final String buyerId;
  final String sellerId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  // Joined from profiles (other user)
  final String? otherUserName;
  final String? otherUserUsername;
  final String? otherUserAvatarUrl;

  // Joined from listings
  final String? listingTitle;
  final List<String>? listingImages;

  const Conversation({
    required this.id,
    this.listingId,
    required this.buyerId,
    required this.sellerId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.otherUserName,
    this.otherUserUsername,
    this.otherUserAvatarUrl,
    this.listingTitle,
    this.listingImages,
  });

  factory Conversation.fromMap(Map<String, dynamic> map, String currentUserId) {
    final isBuyer = (map['buyer_id'] as String) == currentUserId;
    final otherProfile = isBuyer
        ? map['seller_profile'] as Map<String, dynamic>?
        : map['buyer_profile'] as Map<String, dynamic>?;

    final listing = map['listings'] as Map<String, dynamic>?;

    final String fullName =
        '${otherProfile?['nome'] ?? ''} ${otherProfile?['cognome'] ?? ''}'
            .trim();
    final String username = otherProfile?['username'] as String? ?? '';
    final String displayName =
        fullName.isNotEmpty ? fullName : username.isNotEmpty ? username : 'Utente';

    return Conversation(
      id: map['id'] as String,
      listingId: map['listing_id'] as String?,
      buyerId: map['buyer_id'] as String,
      sellerId: map['seller_id'] as String,
      lastMessage: map['last_message'] as String?,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      otherUserName: displayName,
      otherUserUsername: username,
      otherUserAvatarUrl: otherProfile?['avatar_url'] as String?,
      listingTitle: listing?['title'] as String?,
      listingImages: (listing?['images'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}