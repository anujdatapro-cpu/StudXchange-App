import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final String category;
  final String ownerEmail;
  final DateTime timestamp;
  final String? imageUrl;
  final String? imagePath;
  final String? status;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.category,
    required this.ownerEmail,
    required this.timestamp,
    this.imageUrl,
    this.imagePath,
    this.status,
  });

  // Create a copy with updated values
  ItemModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? location,
    String? category,
    String? ownerEmail,
    DateTime? timestamp,
    String? imageUrl,
    String? imagePath,
    String? status,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      location: location ?? this.location,
      category: category ?? this.category,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
    );
  }

  // Convert to map for easy storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'category': category,
      'ownerEmail': ownerEmail,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'status': status ?? 'available',
    };
  }

  static String _asString(dynamic value, {required String fallback}) {
    if (value == null) return fallback;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? fallback : trimmed;
    }
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      return parsed ?? fallback;
    }
    return fallback;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory ItemModel.fromMap(Map<String, dynamic> data, String id) {
    // Handle timestamp from Firestore (Timestamp) or local (String)
    DateTime parsedTimestamp;
    final ts = data['timestamp'];
    if (ts == null) {
      parsedTimestamp = DateTime.now();
    } else if (ts is Timestamp) {
      parsedTimestamp = ts.toDate();
    } else if (ts is DateTime) {
      parsedTimestamp = ts;
    } else if (ts is String) {
      parsedTimestamp = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedTimestamp = DateTime.now();
    }

    return ItemModel(
      id: id,
      title: _asString(data['title'], fallback: 'Untitled Item'),
      description: _asString(data['description'], fallback: 'No description'),
      price: _asDouble(data['price']),
      location: _asString(data['location'], fallback: 'Unknown'),
      category: _asString(data['category'], fallback: 'Others'),
      // Handle both 'ownerEmail' and 'owner' field names
      ownerEmail: _asString(data['ownerEmail'] ?? data['owner'], fallback: ''),
      timestamp: parsedTimestamp,
      imageUrl: _asNullableString(data['imageUrl']),
      imagePath: _asNullableString(data['imagePath']),
      status: _asNullableString(data['status']) ?? 'available',
    );
  }

  // Create from Firestore DocumentSnapshot (proper way)
  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Handle Firestore Timestamp properly
    DateTime parsedTimestamp;
    final ts = data['timestamp'];
    if (ts == null) {
      parsedTimestamp = DateTime.now();
    } else if (ts is Timestamp) {
      parsedTimestamp = ts.toDate();
    } else if (ts is DateTime) {
      parsedTimestamp = ts;
    } else if (ts is String) {
      parsedTimestamp = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedTimestamp = DateTime.now();
    }

    return ItemModel(
      id: doc.id,
      title: _asString(data['title'], fallback: 'Untitled Item'),
      description: _asString(data['description'], fallback: 'No description'),
      price: _asDouble(data['price']),
      location: _asString(data['location'], fallback: 'Unknown'),
      category: _asString(data['category'], fallback: 'Others'),
      // Handle both 'ownerEmail' and 'owner' field names
      ownerEmail: _asString(data['ownerEmail'] ?? data['owner'], fallback: ''),
      timestamp: parsedTimestamp,
      imageUrl: _asNullableString(data['imageUrl']),
      imagePath: _asNullableString(data['imagePath']),
      status: _asNullableString(data['status']) ?? 'available',
    );
  }

  // Create from Firestore DocumentSnapshot with ID and data (backward compatible)
  factory ItemModel.fromFirestoreData(String id, Map<String, dynamic> data) {
    // Handle Firestore Timestamp properly
    DateTime parsedTimestamp;
    final ts = data['timestamp'];
    if (ts == null) {
      parsedTimestamp = DateTime.now();
    } else if (ts is Timestamp) {
      parsedTimestamp = ts.toDate();
    } else if (ts is DateTime) {
      parsedTimestamp = ts;
    } else if (ts is String) {
      parsedTimestamp = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedTimestamp = DateTime.now();
    }

    return ItemModel(
      id: id,
      title: _asString(data['title'], fallback: 'Untitled Item'),
      description: _asString(data['description'], fallback: 'No description'),
      price: _asDouble(data['price']),
      location: _asString(data['location'], fallback: 'Unknown'),
      category: _asString(data['category'], fallback: 'Others'),
      // Handle both 'ownerEmail' and 'owner' field names
      ownerEmail: _asString(data['ownerEmail'] ?? data['owner'], fallback: ''),
      timestamp: parsedTimestamp,
      imageUrl: _asNullableString(data['imageUrl']),
      imagePath: _asNullableString(data['imagePath']),
      status: _asNullableString(data['status']) ?? 'available',
    );
  }

  // Format price with currency symbol
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  // Get relative time
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
