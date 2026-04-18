import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _itemsCollection =>
      _firestore.collection('items');

  Stream<List<ItemModel>> getItemsStream() {
    return _itemsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map<ItemModel>((doc) => ItemModel.fromMap(doc.data(), doc.id))
              .where((item) => item.title.isNotEmpty)
              .toList(),
        );
  }

  Future<void> addItem({
    required String title,
    required String description,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('You must be logged in to add an item.');
    }

    final newDoc = _itemsCollection.doc();
    await newDoc.set({
      'id': newDoc.id,
      'title': title,
      'description': description,
      'ownerEmail': user.email,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItem(String itemId) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('You must be logged in to delete an item.');
    }

    final doc = await _itemsCollection.doc(itemId).get();
    if (!doc.exists) {
      throw Exception('This item no longer exists.');
    }

    final ownerEmail = doc.data()?['ownerEmail'] as String?;
    if (ownerEmail != user.email) {
      throw Exception('Only the owner can delete this item.');
    }

    await _itemsCollection.doc(itemId).delete();
  }
}
