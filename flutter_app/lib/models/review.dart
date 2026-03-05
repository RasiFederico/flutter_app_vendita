// lib/models/review.dart

class Review {
  final String id;
  final String reviewerId;
  final String reviewedId;
  final int rating;          // 1–5
  final String? description;
  final DateTime createdAt;

  // Joined from profiles (reviewer)
  final String? reviewerName;
  final String? reviewerUsername;
  final String? reviewerAvatarUrl;

  const Review({
    required this.id,
    required this.reviewerId,
    required this.reviewedId,
    required this.rating,
    this.description,
    required this.createdAt,
    this.reviewerName,
    this.reviewerUsername,
    this.reviewerAvatarUrl,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    final profile = map['reviewer_profile'] as Map<String, dynamic>?;
    final nome    = (profile?['nome']     as String? ?? '').trim();
    final cognome = (profile?['cognome']  as String? ?? '').trim();
    final full    = '$nome $cognome'.trim();
    final username = (profile?['username'] as String? ?? '').trim();

    return Review(
      id:              map['id'] as String,
      reviewerId:      map['reviewer_id'] as String,
      reviewedId:      map['reviewed_id'] as String,
      rating:          (map['rating'] as num).toInt(),
      description:     map['description'] as String?,
      createdAt:       DateTime.parse(map['created_at'] as String),
      reviewerName:    full.isNotEmpty ? full : (username.isNotEmpty ? username : null),
      reviewerUsername: username.isNotEmpty ? username : null,
      reviewerAvatarUrl: profile?['avatar_url'] as String?,
    );
  }
}