import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String itemId;
  final String userEmail;
  final String comment;
  final int rating;
  final DateTime timestamp;
  final bool isDemo;

  CommentModel({
    required this.id,
    required this.itemId,
    required this.userEmail,
    required this.comment,
    required this.rating,
    required this.timestamp,
    this.isDemo = false,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  factory CommentModel.fromMap(Map<String, dynamic> data, String id) {
    final ts = data['timestamp'];
    DateTime parsedTime;
    if (ts is Timestamp) {
      parsedTime = ts.toDate();
    } else if (ts is DateTime) {
      parsedTime = ts;
    } else if (ts is String) {
      parsedTime = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    final rawRating = data['rating'];
    final normalizedRating = rawRating is int
        ? rawRating
        : (rawRating is num ? rawRating.round() : 0);

    return CommentModel(
      id: id,
      itemId: (data['itemId'] ?? '').toString(),
      userEmail: (data['userEmail'] ?? '').toString(),
      comment: (data['comment'] ?? '').toString(),
      rating: normalizedRating.clamp(1, 5),
      timestamp: parsedTime,
      isDemo: data['isDemo'] == true,
    );
  }
}
