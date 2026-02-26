// lib/models/models.dart

import 'package:flutter/material.dart';
import '../main.dart';

export 'listing.dart';
export 'chat.dart'; // ← NUOVO

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
      case ProductCondition.newProduct:
        return 'Nuovo';
      case ProductCondition.used:
        return 'Usato';
      case ProductCondition.refurbished:
        return 'Ricondizionato';
    }
  }

  Color get conditionColor {
    switch (condition) {
      case ProductCondition.newProduct:
        return SwabbitTheme.green;
      case ProductCondition.used:
        return SwabbitTheme.yellow;
      case ProductCondition.refurbished:
        return SwabbitTheme.accent;
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
      case ListingStatus.active:
        return 'Attivo';
      case ListingStatus.paused:
        return 'In pausa';
      case ListingStatus.sold:
        return 'Venduto';
    }
  }

  Color get statusColor {
    switch (status) {
      case ListingStatus.active:
        return SwabbitTheme.green;
      case ListingStatus.paused:
        return SwabbitTheme.yellow;
      case ListingStatus.sold:
        return SwabbitTheme.text3;
    }
  }
}

// ─── SAMPLE DATA ──────────────────────────────────────────────────────────────

class AppData {
  static const List<Category> categories = [
    Category(
        id: 'gpu',
        label: 'GPU',
        emoji: '🎮',
        gradient: SwabbitTheme.gpuGrad),
    Category(
        id: 'cpu',
        label: 'CPU',
        emoji: '⚙️',
        gradient: SwabbitTheme.cpuGrad),
    Category(
        id: 'ram',
        label: 'RAM',
        emoji: '🧠',
        gradient: SwabbitTheme.ramGrad),
    Category(
        id: 'ssd',
        label: 'Storage',
        emoji: '💾',
        gradient: SwabbitTheme.ssdGrad),
    Category(
        id: 'mb',
        label: 'Schede M.',
        emoji: '🔌',
        gradient: SwabbitTheme.mbGrad),
    Category(
        id: 'cool',
        label: 'Cooling',
        emoji: '❄️',
        gradient: SwabbitTheme.coolGrad),
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
      originalPrice: 699,
      emoji: '⚙️',
      thumbGradient: SwabbitTheme.cpuGrad,
      condition: ProductCondition.used,
      location: 'Roma',
      hasShipping: true,
      isNegotiable: false,
      sellerId: 'u2',
      sellerName: 'ByteHunter',
      sellerRating: 4.7,
      sellerSales: 31,
      sellerFollowers: 210,
      views: 189,
      likes: 12,
      specs: {
        'Core': '16C / 32T',
        'Cache': '144 MB 3D V-Cache',
        'TDP': '120W',
        'Socket': 'AM5',
      },
      description:
          'Processore in perfette condizioni. Utilizzato su build professionale per 6 mesi. '
          'Mai overclockato. Cooler non incluso.',
    ),
    Product(
      id: '3',
      title: 'G.Skill Trident Z5 RGB 64GB',
      subtitle: 'DDR5-6000 · CL30 · 2×32GB',
      price: 195,
      originalPrice: 280,
      emoji: '🧠',
      thumbGradient: SwabbitTheme.ramGrad,
      condition: ProductCondition.used,
      location: 'Torino',
      hasShipping: true,
      isNegotiable: true,
      sellerId: 'u3',
      sellerName: 'MemMaster',
      sellerRating: 5.0,
      sellerSales: 12,
      sellerFollowers: 88,
      views: 97,
      likes: 6,
      specs: {
        'Capacità': '2 × 32 GB',
        'Velocità': 'DDR5-6000',
        'Latenza': 'CL30-38-38-96',
        'Voltaggio': '1.35V',
      },
      description:
          'Kit RAM in ottime condizioni, funzionante con profilo XMP a 6000 MHz. '
          'Mai overcloccato oltre le specifiche.',
    ),
    Product(
      id: '4',
      title: 'WD Black SN850X 4TB NVMe',
      subtitle: 'PCIe Gen4 · M.2 2280',
      price: 230,
      originalPrice: 320,
      emoji: '💾',
      thumbGradient: SwabbitTheme.ssdGrad,
      condition: ProductCondition.used,
      location: 'Napoli',
      hasShipping: true,
      isNegotiable: false,
      sellerId: 'u4',
      sellerName: 'StorageKing',
      sellerRating: 4.6,
      sellerSales: 58,
      sellerFollowers: 120,
      views: 208,
      likes: 19,
      specs: {
        'Capacità': '4 TB',
        'Interfaccia': 'PCIe Gen4 x4',
        'Lettura seq.': '7300 MB/s',
        'Scrittura seq.': '6600 MB/s',
      },
      description:
          'SSD ad altissime prestazioni. Circa 2TB di scrittura totale. '
          'Perfetto per gaming e editing video.',
    ),
    Product(
      id: '5',
      title: 'MSI MEG Z790 GODLIKE',
      subtitle: 'Intel Z790 · E-ATX · LGA1700',
      price: 580,
      originalPrice: 899,
      emoji: '🔌',
      thumbGradient: SwabbitTheme.mbGrad,
      condition: ProductCondition.refurbished,
      location: 'Firenze',
      hasShipping: true,
      isNegotiable: true,
      sellerId: 'u5',
      sellerName: 'PCWizard',
      sellerRating: 4.8,
      sellerSales: 25,
      sellerFollowers: 195,
      views: 54,
      likes: 3,
      specs: {
        'Socket': 'LGA 1700',
        'Form factor': 'E-ATX',
        'RAM': 'DDR5, max 192GB',
        'PCIe': '5.0 x16',
      },
      description:
          'Scheda madre top di gamma. Ricondizionata professionalmente con BIOS aggiornato. '
          'Tutti i connettori funzionanti. Garanzia residua 6 mesi.',
    ),
    Product(
      id: '6',
      title: 'Arctic Liquid Freezer III 360',
      subtitle: 'AIO 360mm · ARGB · Intel + AMD',
      price: 85,
      originalPrice: 130,
      emoji: '❄️',
      thumbGradient: SwabbitTheme.coolGrad,
      condition: ProductCondition.used,
      location: 'Bologna',
      hasShipping: true,
      isNegotiable: false,
      sellerId: 'u6',
      sellerName: 'CoolBot',
      sellerRating: 4.9,
      sellerSales: 18,
      sellerFollowers: 74,
      views: 41,
      likes: 4,
      specs: {
        'Radiatore': '360mm',
        'Ventole': '3 × 120mm ARGB',
        'Compatibilità': 'LGA1700, AM5, AM4',
        'Rumorosità': '0.5 Sone',
      },
      description:
          'AIO in perfette condizioni, usato 4 mesi. '
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