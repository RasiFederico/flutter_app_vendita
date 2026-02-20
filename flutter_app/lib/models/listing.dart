import 'package:flutter/material.dart';
import '../../main.dart'; // SwabbitTheme

// ─── ENUMS ────────────────────────────────────────────────────────────────────

enum ListingCondition { newItem, used, refurbished }

extension ListingConditionX on ListingCondition {
  String get dbValue {
    switch (this) {
      case ListingCondition.newItem:    return 'new';
      case ListingCondition.used:       return 'used';
      case ListingCondition.refurbished: return 'refurbished';
    }
  }

  String get label {
    switch (this) {
      case ListingCondition.newItem:    return 'Nuovo';
      case ListingCondition.used:       return 'Usato';
      case ListingCondition.refurbished: return 'Ricondizionato';
    }
  }

  Color get color {
    switch (this) {
      case ListingCondition.newItem:    return SwabbitTheme.green;
      case ListingCondition.used:       return SwabbitTheme.accent;
      case ListingCondition.refurbished: return SwabbitTheme.yellow;
    }
  }

  static ListingCondition fromDb(String? v) {
    switch (v) {
      case 'new':          return ListingCondition.newItem;
      case 'refurbished':  return ListingCondition.refurbished;
      default:             return ListingCondition.used;
    }
  }
}

enum ListingStatus { active, paused, sold }

extension ListingStatusX on ListingStatus {
  String get dbValue {
    switch (this) {
      case ListingStatus.active: return 'active';
      case ListingStatus.paused: return 'paused';
      case ListingStatus.sold:   return 'sold';
    }
  }

  String get label {
    switch (this) {
      case ListingStatus.active: return 'Attivo';
      case ListingStatus.paused: return 'In pausa';
      case ListingStatus.sold:   return 'Venduto';
    }
  }

  Color get color {
    switch (this) {
      case ListingStatus.active: return SwabbitTheme.green;
      case ListingStatus.paused: return SwabbitTheme.yellow;
      case ListingStatus.sold:   return SwabbitTheme.text3;
    }
  }

  static ListingStatus fromDb(String? v) {
    switch (v) {
      case 'paused': return ListingStatus.paused;
      case 'sold':   return ListingStatus.sold;
      default:       return ListingStatus.active;
    }
  }
}

// ─── MODEL ────────────────────────────────────────────────────────────────────

class Listing {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double price;
  final double? originalPrice;
  final ListingCondition condition;
  final String? category;
  final String location;
  final bool hasShipping;
  final bool isNegotiable;
  final ListingStatus status;
  final List<String> images;   // public URLs from Supabase Storage
  final int views;
  final int likes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Joined from profiles (nullable — dipende dalla query)
  final String? sellerName;
  final String? sellerUsername;
  final double sellerRating;
  final int sellerSales;

  const Listing({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.price,
    this.originalPrice,
    this.condition = ListingCondition.used,
    this.category,
    this.location = '',
    this.hasShipping = false,
    this.isNegotiable = false,
    this.status = ListingStatus.active,
    this.images = const [],
    this.views = 0,
    this.likes = 0,
    required this.createdAt,
    this.updatedAt,
    this.sellerName,
    this.sellerUsername,
    this.sellerRating = 5.0,
    this.sellerSales = 0,
  });

  /// Costruisce un Listing dalla riga restituita da Supabase.
  /// Supporta join opzionale con `profiles`.
  factory Listing.fromMap(Map<String, dynamic> map) {
    // join con profiles (se presente)
    final profile = map['profiles'] as Map<String, dynamic>?;
    final String sellerName = profile != null
        ? '${profile['nome'] ?? ''} ${profile['cognome'] ?? ''}'.trim()
        : '';
    final String sellerUsername = profile?['username'] ?? '';
    final double sellerRating =
        (profile?['rating'] as num?)?.toDouble() ?? 5.0;
    final int sellerSales = (profile?['sales_count'] as num?)?.toInt() ?? 0;

    return Listing(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num).toDouble(),
      originalPrice: map['original_price'] != null
          ? (map['original_price'] as num).toDouble()
          : null,
      condition: ListingConditionX.fromDb(map['condition'] as String?),
      category: map['category'] as String?,
      location: map['location'] as String? ?? '',
      hasShipping: map['has_shipping'] as bool? ?? false,
      isNegotiable: map['is_negotiable'] as bool? ?? false,
      status: ListingStatusX.fromDb(map['status'] as String?),
      images: (map['images'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      views: (map['views'] as num?)?.toInt() ?? 0,
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      sellerName: sellerName,
      sellerUsername: sellerUsername,
      sellerRating: sellerRating,
      sellerSales: sellerSales,
    );
  }

  /// Converte in Map per l'insert/update su Supabase.
  Map<String, dynamic> toInsertMap() => {
        'user_id': userId,
        'title': title,
        'description': description,
        'price': price,
        if (originalPrice != null) 'original_price': originalPrice,
        'condition': condition.dbValue,
        if (category != null) 'category': category,
        'location': location,
        'has_shipping': hasShipping,
        'is_negotiable': isNegotiable,
        'status': status.dbValue,
        'images': images,
      };

  /// Emoji suggerita in base alla categoria
  String get categoryEmoji {
    switch (category?.toLowerCase()) {
      case 'gpu':        return '🎮';
      case 'cpu':        return '⚙️';
      case 'ram':        return '🧠';
      case 'storage':    return '💾';
      case 'motherboard': return '🔌';
      case 'cooling':    return '❄️';
      case 'psu':        return '🔋';
      case 'case':       return '🖥️';
      case 'monitor':    return '🖵';
      case 'periferiche': return '🖱️';
      default:           return '📦';
    }
  }

  Listing copyWith({ListingStatus? status, int? views, int? likes}) => Listing(
        id: id,
        userId: userId,
        title: title,
        description: description,
        price: price,
        originalPrice: originalPrice,
        condition: condition,
        category: category,
        location: location,
        hasShipping: hasShipping,
        isNegotiable: isNegotiable,
        status: status ?? this.status,
        images: images,
        views: views ?? this.views,
        likes: likes ?? this.likes,
        createdAt: createdAt,
        updatedAt: updatedAt,
        sellerName: sellerName,
        sellerUsername: sellerUsername,
        sellerRating: sellerRating,
        sellerSales: sellerSales,
      );
}