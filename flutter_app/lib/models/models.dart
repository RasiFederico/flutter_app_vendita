import 'package:flutter/material.dart';
import '../main.dart';

// ─── ENUMS ────────────────────────────────────────────────────────────────────

enum ProductCondition { newProduct, used, refurbished }

enum ListingStatus { active, paused, sold }

// ─── MODELS ───────────────────────────────────────────────────────────────────

class Category {
  final String id;
  final String label;
  final String emoji;
  final LinearGradient gradient;

  const Category({
    required this.id,
    required this.label,
    required this.emoji,
    required this.gradient,
  });
}

class Product {
  final String id;
  final String title;
  final String subtitle;
  final double price;
  final double? originalPrice;
  final String emoji;
  final LinearGradient thumbGradient;
  final ProductCondition condition;
  final String location;
  final bool hasShipping;
  final bool isNegotiable;
  final String sellerId;
  final String sellerName;
  final double sellerRating;
  final int sellerSales;
  final int sellerFollowers;
  final int views;
  final int likes;
  final Map<String, String> specs;
  final String description;
  final bool isFeatured;

  const Product({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    this.originalPrice,
    required this.emoji,
    required this.thumbGradient,
    this.condition = ProductCondition.used,
    this.location = 'Milano',
    this.hasShipping = true,
    this.isNegotiable = false,
    required this.sellerId,
    required this.sellerName,
    this.sellerRating = 4.8,
    this.sellerSales = 23,
    this.sellerFollowers = 156,
    this.views = 100,
    this.likes = 12,
    this.specs = const {},
    this.description = '',
    this.isFeatured = false,
  });

  String get conditionLabel {
    switch (condition) {
      case ProductCondition.newProduct: return 'Nuovo';
      case ProductCondition.used: return 'Usato';
      case ProductCondition.refurbished: return 'Ricondizionato';
    }
  }

  Color get conditionColor {
    switch (condition) {
      case ProductCondition.newProduct: return SwabbitTheme.green;
      case ProductCondition.used: return SwabbitTheme.yellow;
      case ProductCondition.refurbished: return SwabbitTheme.accent;
    }
  }
}

class UserListing {
  final String productId;
  final String title;
  final double price;
  final String emoji;
  final LinearGradient thumbGradient;
  final ListingStatus status;
  final int views;
  final int likes;

  const UserListing({
    required this.productId,
    required this.title,
    required this.price,
    required this.emoji,
    required this.thumbGradient,
    this.status = ListingStatus.active,
    this.views = 0,
    this.likes = 0,
  });

  String get statusLabel {
    switch (status) {
      case ListingStatus.active: return 'Attivo';
      case ListingStatus.paused: return 'In pausa';
      case ListingStatus.sold: return 'Venduto';
    }
  }

  Color get statusColor {
    switch (status) {
      case ListingStatus.active: return SwabbitTheme.green;
      case ListingStatus.paused: return SwabbitTheme.yellow;
      case ListingStatus.sold: return SwabbitTheme.text3;
    }
  }
}

// ─── SAMPLE DATA ──────────────────────────────────────────────────────────────

class AppData {
  static const List<Category> categories = [
    Category(id: 'gpu',  label: 'GPU',      emoji: '🎮', gradient: SwabbitTheme.gpuGrad),
    Category(id: 'cpu',  label: 'CPU',      emoji: '⚙️', gradient: SwabbitTheme.cpuGrad),
    Category(id: 'ram',  label: 'RAM',      emoji: '🧠', gradient: SwabbitTheme.ramGrad),
    Category(id: 'ssd',  label: 'Storage',  emoji: '💾', gradient: SwabbitTheme.ssdGrad),
    Category(id: 'mb',   label: 'Schede M.', emoji: '🔌', gradient: SwabbitTheme.mbGrad),
    Category(id: 'cool', label: 'Cooling',  emoji: '❄️', gradient: SwabbitTheme.coolGrad),
  ];

  static final List<Product> products = [
    Product(
      id: '1',
      title: 'RTX 4090 Founders Edition',
      subtitle: 'NVIDIA GeForce RTX 4090 · 24GB GDDR6X',
      price: 1249,
      originalPrice: 1599,
      emoji: '🎮',
      thumbGradient: SwabbitTheme.gpuGrad,
      condition: ProductCondition.used,
      location: 'Milano',
      hasShipping: true,
      isNegotiable: true,
      sellerId: 'u1',
      sellerName: 'GigaRig',
      sellerRating: 4.9,
      sellerSales: 47,
      sellerFollowers: 342,
      views: 342,
      likes: 28,
      isFeatured: true,
      specs: {
        'VRAM': '24 GB GDDR6X',
        'TDP': '450W',
        'Uscite': '3x DP 1.4a, HDMI 2.1',
        'Lunghezza': '336mm',
      },
      description:
          'RTX 4090 FE in ottime condizioni, usata per 8 mesi per gaming. '
          'Nessun overclock, mai minata. Scatola e accessori originali inclusi. '
          'Temperatura massima registrata: 78°C. Disponibile per spedizione assicurata.',
    ),
    Product(
      id: '2',
      title: 'AMD Ryzen 9 7950X3D',
      subtitle: 'AMD Ryzen 9 · 16 Core / 32 Thread',
      price: 420,
      emoji: '⚙️',
      thumbGradient: SwabbitTheme.cpuGrad,
      condition: ProductCondition.used,
      location: 'Roma',
      hasShipping: true,
      sellerId: 'u1',
      sellerName: 'GigaRig',
      sellerRating: 4.9,
      sellerSales: 47,
      sellerFollowers: 342,
      views: 189,
      likes: 12,
      specs: {
        'Core / Thread': '16C / 32T',
        'Clock Base': '4.2 GHz',
        'Clock Max': '5.7 GHz',
        'Cache': '144MB (3D V-Cache)',
      },
      description: 'CPU top di gamma in perfetto stato. Usata con sistema di raffreddamento a liquido, '
          'mai overcloccata. Pasta termica rinnovata. Socket AM5. Ideale per workstation e gaming.',
    ),
    Product(
      id: '3',
      title: 'G.Skill Trident Z5 RGB 64GB',
      subtitle: 'DDR5-6400 · CL32 · 2x32GB',
      price: 195,
      emoji: '🧠',
      thumbGradient: SwabbitTheme.ramGrad,
      condition: ProductCondition.newProduct,
      location: 'Torino',
      hasShipping: true,
      sellerId: 'u2',
      sellerName: 'ByteDealer',
      sellerRating: 4.7,
      sellerSales: 12,
      sellerFollowers: 89,
      views: 97,
      likes: 6,
      specs: {
        'Capacità': '64 GB (2x32)',
        'Tipo': 'DDR5',
        'Velocità': '6400 MHz',
        'Latenza': 'CL32-39-39-102',
      },
      description: 'Kit DDR5 mai aperto, ancora sigillato. Acquistato in bundle con PC poi non assemblato.',
    ),
    Product(
      id: '4',
      title: 'WD Black SN850X 4TB NVMe',
      subtitle: 'PCIe Gen4 · NVMe M.2 2280',
      price: 230,
      emoji: '💾',
      thumbGradient: SwabbitTheme.ssdGrad,
      condition: ProductCondition.refurbished,
      location: 'Napoli',
      hasShipping: true,
      sellerId: 'u3',
      sellerName: 'NullPtr',
      sellerRating: 4.6,
      sellerSales: 8,
      sellerFollowers: 44,
      views: 208,
      likes: 19,
      specs: {
        'Capacità': '4 TB',
        'Interfaccia': 'PCIe Gen4 x4',
        'Lettura seq.': '7,300 MB/s',
        'Scrittura seq.': '6,600 MB/s',
      },
      description: 'SSD NVMe di alta capacità in ottimo stato. TBW residuo: ~3400 TB. '
          'Controllato con Crystal Disk Info — stato: Buono.',
    ),
    Product(
      id: '5',
      title: 'MSI MEG Z790 GODLIKE',
      subtitle: 'Intel LGA 1700 · ATX · DDR5',
      price: 580,
      emoji: '🔌',
      thumbGradient: SwabbitTheme.mbGrad,
      condition: ProductCondition.used,
      location: 'Firenze',
      hasShipping: false,
      isNegotiable: true,
      sellerId: 'u2',
      sellerName: 'ByteDealer',
      sellerRating: 4.7,
      sellerSales: 12,
      sellerFollowers: 89,
      views: 54,
      likes: 3,
      specs: {
        'Socket': 'LGA 1700',
        'Form Factor': 'ATX',
        'RAM': 'DDR5 · 4 slot · Max 192GB',
        'PCIe': '5.0 x16 + 4.0 x4',
      },
      description: 'Scheda madre top di gamma Z790, usata per 6 mesi. '
          'Inclusa scatola originale con tutti gli accessori. Solo ritiro a mano, no spedizione.',
    ),
    Product(
      id: '6',
      title: 'Arctic Liquid Freezer III 360',
      subtitle: 'AIO 360mm · AMD & Intel',
      price: 85,
      emoji: '❄️',
      thumbGradient: SwabbitTheme.coolGrad,
      condition: ProductCondition.used,
      location: 'Bologna',
      hasShipping: true,
      sellerId: 'u3',
      sellerName: 'NullPtr',
      sellerRating: 4.6,
      sellerSales: 8,
      sellerFollowers: 44,
      views: 41,
      likes: 4,
      specs: {
        'Radiatore': '360mm (3x120mm)',
        'Compatibilità': 'AM4/AM5/LGA1700',
        'Pompa': '2800 RPM',
        'Livello rumore': '≤0.3 Sone',
      },
      description: 'AIO in ottimo stato, pasta termica appena rinnovata. '
          'Inclusi tutti i supporti di montaggio originali. Rumorosità minima.',
    ),
  ];

  static final List<UserListing> myListings = [
    UserListing(
      productId: '1',
      title: 'RTX 4090 Founders Edition',
      price: 1249,
      emoji: '🎮',
      thumbGradient: SwabbitTheme.gpuGrad,
      status: ListingStatus.active,
      views: 342,
      likes: 28,
    ),
    UserListing(
      productId: '2',
      title: 'AMD Ryzen 9 7950X3D',
      price: 420,
      emoji: '⚙️',
      thumbGradient: SwabbitTheme.cpuGrad,
      status: ListingStatus.active,
      views: 189,
      likes: 12,
    ),
    UserListing(
      productId: '3',
      title: 'G.Skill Trident Z5 RGB 64GB',
      price: 195,
      emoji: '🧠',
      thumbGradient: SwabbitTheme.ramGrad,
      status: ListingStatus.active,
      views: 97,
      likes: 6,
    ),
    UserListing(
      productId: '5',
      title: 'MSI MEG Z790 GODLIKE',
      price: 580,
      emoji: '🔌',
      thumbGradient: SwabbitTheme.mbGrad,
      status: ListingStatus.paused,
      views: 54,
      likes: 3,
    ),
    UserListing(
      productId: '4',
      title: 'WD Black SN850X 4TB NVMe',
      price: 230,
      emoji: '💾',
      thumbGradient: SwabbitTheme.ssdGrad,
      status: ListingStatus.sold,
      views: 208,
      likes: 19,
    ),
    UserListing(
      productId: '6',
      title: 'Arctic Liquid Freezer III 360',
      price: 85,
      emoji: '❄️',
      thumbGradient: SwabbitTheme.coolGrad,
      status: ListingStatus.active,
      views: 41,
      likes: 4,
    ),
  ];
}