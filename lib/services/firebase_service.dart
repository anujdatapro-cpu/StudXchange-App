import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import '../models/item_model.dart';

class FirebaseService {
  static final _db = FirebaseFirestore.instance;

  static void _ensureItemRequiredFields(
      DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic> data) {
    final patch = <String, dynamic>{};
    if (!data.containsKey('title')) patch['title'] = 'Untitled Item';
    if (!data.containsKey('description')) patch['description'] = 'No description';
    if (!data.containsKey('price')) patch['price'] = 0.0;
    if (!data.containsKey('category')) patch['category'] = 'Others';
    if (!data.containsKey('imageUrl')) patch['imageUrl'] = '';
    if (!data.containsKey('ownerEmail')) patch['ownerEmail'] = '';
    if (!data.containsKey('timestamp')) {
      patch['timestamp'] = FieldValue.serverTimestamp();
    }
    if (patch.isNotEmpty) {
      ref.set(patch, SetOptions(merge: true));
    }
  }

  // ADD ITEM
  static Future<void> addItem({
    required String title,
    required String description,
    required double price,
    required String imageUrl,
    required String ownerEmail,
    required String category,
  }) async {
    final docRef = await _db.collection('items').add({
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'ownerEmail': ownerEmail,
      'category': category,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await docRef.update({'id': docRef.id});

    final users = await _db.collection('users').limit(120).get();
    for (final user in users.docs) {
      final email = (user.data()['email'] ?? '').toString();
      if (email.isEmpty || email == ownerEmail) continue;
      await addNotification(
        userEmail: email,
        title: 'New item listed',
        message: '$title is now available on StudXchange.',
      );
    }
  }

  // GET ALL ITEMS
  static Stream<List<ItemModel>> getItems() {
    return _db
        .collection('items')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map<ItemModel>((doc) {
            final data = doc.data();
            _ensureItemRequiredFields(doc.reference, data);
            return ItemModel.fromMap(data, doc.id);
          }).toList(),
        );
  }

  static Stream<List<ItemModel>> getItemsByCategory(String category) {
    final normalized = category.trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'all') {
      return getItems();
    }
    return _db
        .collection('items')
        .where('category', isEqualTo: normalized)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map<ItemModel>((doc) {
            final data = doc.data();
            _ensureItemRequiredFields(doc.reference, data);
            return ItemModel.fromMap(data, doc.id);
          }).toList(),
        );
  }

  static Stream<List<ItemModel>> searchItems(String query) {
    final normalized = query.trim().toLowerCase();
    return _db
        .collection('items')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map<ItemModel>((doc) {
            final data = doc.data();
            _ensureItemRequiredFields(doc.reference, data);
            return ItemModel.fromMap(data, doc.id);
          }).toList();
          if (normalized.isEmpty) return items;
          return items.where((item) {
            return item.title.toLowerCase().contains(normalized) ||
                item.description.toLowerCase().contains(normalized) ||
                item.category.toLowerCase().contains(normalized);
          }).toList();
        });
  }

  // GET USER ITEMS
  static Stream<List<ItemModel>> getUserItems(String email) {
    return _db
        .collection('items')
        .where('ownerEmail', isEqualTo: email)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map<ItemModel>((doc) {
            final data = doc.data();
            _ensureItemRequiredFields(doc.reference, data);
            return ItemModel.fromMap(data, doc.id);
          }).toList(),
        );
  }

  // DELETE ITEM
  static Future<void> deleteItem(String id) async {
    await _db.collection('items').doc(id).delete();
  }

  // ADD COMMENT
  static Future<void> addComment(
      String itemId, String userEmail, String comment, int rating) async {
    await _db.collection('comments').add({
      'itemId': itemId,
      'userEmail': userEmail,
      'comment': comment,
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // GET COMMENTS
  static Stream<List<CommentModel>> getComments(String itemId) {
    return _db
        .collection('comments')
        .where('itemId', isEqualTo: itemId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  static Stream<List<CommentModel>> getCommentsByUser(String userEmail) {
    return _db
        .collection('comments')
        .where('userEmail', isEqualTo: userEmail)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  static Future<String> getUserNameByEmail(String email) async {
    if (email.trim().isEmpty) return 'Student';
    final doc = await _db.collection('users').doc(email).get();
    final data = doc.data();
    final name = (data?['name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    return email.split('@').first;
  }

  static Future<void> ensureDemoReviewsForItem(String itemId) async {
    final existing = await _db
        .collection('comments')
        .where('itemId', isEqualTo: itemId)
        .get();

    if (existing.docs.length >= 5) return;

    final templates = <Map<String, dynamic>>[
      {'comment': 'Great product, works perfectly', 'rating': 5},
      {'comment': 'Worth the price', 'rating': 4},
      {'comment': 'Condition is good', 'rating': 4},
      {'comment': 'Delivery was fast', 'rating': 5},
      {'comment': 'Exactly as described, happy purchase', 'rating': 5},
      {'comment': 'Good quality overall', 'rating': 4},
      {'comment': 'Works fine for daily use', 'rating': 3},
      {'comment': 'Seller was responsive and polite', 'rating': 5},
    ];
    final demoUsers = <String>[
      'priya.shah@vitpune.ac.in',
      'rohan.kale@vitpune.ac.in',
      'aarya.patil@vitpune.ac.in',
      'neha.joshi@vitpune.ac.in',
      'aditya.more@vitpune.ac.in',
      'sneha.nikam@vitpune.ac.in',
      'arjun.mehta@vitpune.ac.in',
      'kavya.deshmukh@vitpune.ac.in',
    ];

    final needed = 6 - existing.docs.length;
    if (needed <= 0) return;

    final batch = _db.batch();
    for (var i = 0; i < needed; i++) {
      final review = templates[i % templates.length];
      final email = demoUsers[i % demoUsers.length];
      final ref = _db.collection('comments').doc();
      batch.set(ref, {
        'itemId': itemId,
        'userEmail': email,
        'comment': review['comment'],
        'rating': review['rating'],
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(Duration(hours: (i + 1) * 3)),
        ),
        'isDemo': true,
      });
    }
    await batch.commit();
  }

  // NOTIFICATIONS
  static Future<void> addNotification({
    required String userEmail,
    required String title,
    required String message,
  }) async {
    await _db.collection('notifications').add({
      'userEmail': userEmail,
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'isRead': false,
    });
  }

  static Stream<int> getUnreadNotificationCount(String userEmail) {
    return _db
        .collection('notifications')
        .where('userEmail', isEqualTo: userEmail)
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Stream<QuerySnapshot> getNotifications(String userEmail) {
    return _db
        .collection('notifications')
        .where('userEmail', isEqualTo: userEmail)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> markNotificationsRead(String userEmail) async {
    final snapshot = await _db
        .collection('notifications')
        .where('userEmail', isEqualTo: userEmail)
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true, 'read': true});
    }
    await batch.commit();
  }

  static Future<void> saveFcmToken({
    required String userEmail,
    required String token,
  }) async {
    await _db.collection('users').doc(userEmail).set({
      'email': userEmail,
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String chatIdFor(String a, String b) {
    final sorted = [a.trim().toLowerCase(), b.trim().toLowerCase()]..sort();
    return '${sorted[0]}__${sorted[1]}';
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserChats(
      String userEmail) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userEmail)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getChatMessages(
      String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  static Future<void> sendChatMessage({
    required String chatId,
    required String senderEmail,
    required String receiverEmail,
    required String message,
  }) async {
    final text = message.trim();
    if (text.isEmpty) return;
    final chatRef = _db.collection('chats').doc(chatId);
    await chatRef.set({
      'chatId': chatId,
      'participants': [senderEmail, receiverEmail],
      'lastMessage': text,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'senderEmail': senderEmail,
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await addNotification(
      userEmail: receiverEmail,
      title: 'New message',
      message: 'You received a new message from ${senderEmail.split('@').first}',
    );
  }

  static Future<void> createBooking({
    required String itemId,
    required String buyerEmail,
    required String sellerEmail,
  }) async {
    await _db.collection('bookings').add({
      'itemId': itemId,
      'buyerEmail': buyerEmail,
      'sellerEmail': sellerEmail,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
    await addNotification(
      userEmail: sellerEmail,
      title: 'New booking request',
      message: 'A buyer requested booking for your listed item.',
    );
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getOrders(String buyer) {
    return _db
        .collection('bookings')
        .where('buyerEmail', isEqualTo: buyer)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getSales(String seller) {
    return _db
        .collection('bookings')
        .where('sellerEmail', isEqualTo: seller)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> ensureMarketplaceItemsCount({int total = 37}) async {
    final existing = await _db.collection('items').get();
    final current = existing.docs.length;
    if (current >= total) return;

    final usersSnapshot = await _db.collection('users').limit(50).get();
    final userEmails = usersSnapshot.docs
        .map((e) => (e.data()['email'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toList();
    if (userEmails.isEmpty) return;

    final seeds = <Map<String, dynamic>>[
      {'title': 'Lenovo ThinkPad E14 i5', 'description': 'Perfect for coding, 16GB RAM, SSD.', 'price': 38900.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'HP Pavilion Gaming Laptop', 'description': 'GTX graphics, ideal for CAD and gaming.', 'price': 49999.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=1200&q=80'},
      {'title': '65W USB-C Fast Charger', 'description': 'Supports laptops and phones, compact design.', 'price': 1350.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1583863788434-e58a36330f19?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'iPad 9th Gen', 'description': 'Great for note taking and watching lectures.', 'price': 24900.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Study Table Foldable', 'description': 'Compact hostel study table in good condition.', 'price': 2200.0, 'category': 'Furniture', 'imageUrl': 'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Ergonomic Mesh Chair', 'description': 'Comfortable for long coding sessions.', 'price': 3200.0, 'category': 'Furniture', 'imageUrl': 'https://images.unsplash.com/photo-1505843513577-22bb7d21e455?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Hostel Single Bed Mattress', 'description': 'Orthopedic foam mattress, lightly used.', 'price': 2800.0, 'category': 'Furniture', 'imageUrl': 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Arduino UNO Starter Bundle', 'description': 'Includes breadboard, jumper wires, LEDs.', 'price': 1850.0, 'category': 'Projects', 'imageUrl': 'https://images.unsplash.com/photo-1553406830-ef2513450d76?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'ESP32 Dev Kit + Sensors', 'description': 'DHT11, ultrasonic, relay modules included.', 'price': 1400.0, 'category': 'Projects', 'imageUrl': 'https://images.unsplash.com/photo-1555617117-08fda9c4e1b4?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Digital Multimeter', 'description': 'Accurate readings for electronics labs.', 'price': 750.0, 'category': 'Tools', 'imageUrl': 'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Circuit Design Lab Manual', 'description': 'Latest edition with solved examples.', 'price': 420.0, 'category': 'Study', 'imageUrl': 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Engineering Mathematics Book', 'description': 'Second-hand, neat condition, all pages intact.', 'price': 600.0, 'category': 'Study', 'imageUrl': 'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Scientific Calculator Casio FX-991ES', 'description': 'Approved for exams, works perfectly.', 'price': 900.0, 'category': 'Study', 'imageUrl': 'https://images.unsplash.com/photo-1564466809058-bf4114d55352?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Backpack 32L Water Resistant', 'description': 'Laptop compartment and bottle holders.', 'price': 1300.0, 'category': 'Hostel', 'imageUrl': 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Cycle Hero Sprint', 'description': 'Good for campus commute, recently serviced.', 'price': 4200.0, 'category': 'Hostel', 'imageUrl': 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Power Bank 20000mAh', 'description': 'Fast charging, ideal during long days on campus.', 'price': 1600.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Portable SSD 512GB', 'description': 'High-speed storage for projects and media.', 'price': 4100.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Raspberry Pi 4 Model B', 'description': '4GB RAM board with power adapter.', 'price': 5900.0, 'category': 'Projects', 'imageUrl': 'https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Lab Coat (Medium)', 'description': 'Clean and barely used for chemistry lab.', 'price': 350.0, 'category': 'Study', 'imageUrl': 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Mini Projector for Presentations', 'description': 'Good brightness for classroom demos.', 'price': 8700.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1582711012124-a56cf4b6b43b?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Desk Lamp Adjustable', 'description': 'Blue light filter, flexible arm.', 'price': 650.0, 'category': 'Hostel', 'imageUrl': 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Whiteboard 2x1.5 ft', 'description': 'Useful for daily revision planning.', 'price': 1100.0, 'category': 'Study', 'imageUrl': 'https://images.unsplash.com/photo-1513258496099-48168024aec0?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Graphic Tablet for Design', 'description': 'Ideal for UI design and digital art.', 'price': 5200.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1586953208448-b95a79798f07?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Mechanical Keyboard', 'description': 'RGB backlit keyboard, tactile switches.', 'price': 2900.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1511467687858-23d96c32e4ae?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Wireless Mouse Logitech', 'description': 'Silent clicks and long battery life.', 'price': 1250.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'USB Microscope Lab Use', 'description': 'Useful for material science mini projects.', 'price': 3400.0, 'category': 'Tools', 'imageUrl': 'https://images.unsplash.com/photo-1518152006812-edab29b069ac?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Resistance Band Set', 'description': 'Fitness gear for hostel room workouts.', 'price': 500.0, 'category': 'Hostel', 'imageUrl': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Bluetooth Speaker', 'description': 'Compact speaker with deep bass.', 'price': 1800.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1589003077984-894e133dabab?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Drafting Set for Engineering Drawing', 'description': 'Includes compass, protractor, divider.', 'price': 420.0, 'category': 'Study', 'imageUrl': 'https://images.unsplash.com/photo-1456324504439-367cee3b3c32?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Portable Induction Cooktop', 'description': 'Useful for quick hostel cooking.', 'price': 2300.0, 'category': 'Hostel', 'imageUrl': 'https://images.unsplash.com/photo-1586201375761-83865001e17b?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Water Bottle Stainless Steel', 'description': '1L insulated bottle, leak proof.', 'price': 450.0, 'category': 'Hostel', 'imageUrl': 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Noise Cancelling Headphones', 'description': 'Great for focused study in noisy areas.', 'price': 7800.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1484704849700-f032a568e944?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'WiFi Router Dual Band', 'description': 'Strong range for hostel/shared flat.', 'price': 2600.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1593642533144-3d62aa4783ec?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Electronics Toolkit Precision', 'description': 'Screwdrivers, tweezers, pry tools set.', 'price': 980.0, 'category': 'Tools', 'imageUrl': 'https://images.unsplash.com/photo-1581147036325-3bce2d6f36b1?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Clamp Meter', 'description': 'Lab grade clamp meter, accurate and stable.', 'price': 3200.0, 'category': 'Tools', 'imageUrl': 'https://images.unsplash.com/photo-1518773553398-650c184e0bb3?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Laptop Cooling Pad', 'description': 'Keeps temperatures down during coding marathons.', 'price': 1050.0, 'category': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1516387938699-a93567ec168e?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Data Structures Notes Bundle', 'description': 'Printed notes + handwritten summaries.', 'price': 280.0, 'category': 'Study', 'imageUrl': 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Mini Bookshelf', 'description': '3-tier rack for books and files.', 'price': 1900.0, 'category': 'Furniture', 'imageUrl': 'https://images.unsplash.com/photo-1589998059171-988d887df646?auto=format&fit=crop&w=1200&q=80'},
      {'title': 'Drawing Tablet Stand', 'description': 'Adjustable stand for tab/device drawing.', 'price': 700.0, 'category': 'Furniture', 'imageUrl': 'https://images.unsplash.com/photo-1588702547919-26089e690ecc?auto=format&fit=crop&w=1200&q=80'},
    ];

    final needed = total - current;
    for (var i = 0; i < needed; i++) {
      final item = seeds[i % seeds.length];
      await addItem(
        title: item['title'] as String,
        description: item['description'] as String,
        price: item['price'] as double,
        imageUrl: item['imageUrl'] as String,
        ownerEmail: userEmails[i % userEmails.length],
        category: item['category'] as String,
      );
    }
  }

  static Stream<Set<String>> getWishlistItemIds(String userEmail) {
    if (userEmail.trim().isEmpty) {
      return Stream<Set<String>>.value(<String>{});
    }
    return _db
        .collection('wishlist')
        .where('userEmail', isEqualTo: userEmail)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => (doc.data()['itemId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    });
  }

  static Future<void> toggleWishlist({
    required String userEmail,
    required String itemId,
  }) async {
    if (userEmail.trim().isEmpty || itemId.trim().isEmpty) return;

    final existing = await _db
        .collection('wishlist')
        .where('userEmail', isEqualTo: userEmail)
        .where('itemId', isEqualTo: itemId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.delete();
      return;
    }

    await _db.collection('wishlist').add({
      'userEmail': userEmail,
      'itemId': itemId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<ItemModel>> getWishlistItems(String userEmail) {
    if (userEmail.trim().isEmpty) {
      return Stream<List<ItemModel>>.value(const <ItemModel>[]);
    }
    return _db
        .collection('wishlist')
        .where('userEmail', isEqualTo: userEmail)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final itemIds = snapshot.docs
          .map((doc) => (doc.data()['itemId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();
      if (itemIds.isEmpty) return <ItemModel>[];

      final itemDocs = await Future.wait(
        itemIds.map((id) => _db.collection('items').doc(id).get()),
      );

      return itemDocs.where((doc) => doc.exists).map((doc) {
        final data = doc.data() ?? <String, dynamic>{};
        return ItemModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  static Future<List<ItemModel>> getRecommendations({
    required String userEmail,
    List<String> recentItemIds = const [],
    int limit = 12,
  }) async {
    final interests = <String>{};

    if (userEmail.trim().isNotEmpty) {
      final wishlistSnap = await _db
          .collection('wishlist')
          .where('userEmail', isEqualTo: userEmail)
          .limit(25)
          .get();
      final wishlistItemIds = wishlistSnap.docs
          .map((doc) => (doc.data()['itemId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();
      if (wishlistItemIds.isNotEmpty) {
        final wishItems = await Future.wait(
          wishlistItemIds.map((id) => _db.collection('items').doc(id).get()),
        );
        for (final itemDoc in wishItems) {
          final category = (itemDoc.data()?['category'] ?? '').toString().trim();
          if (category.isNotEmpty) interests.add(category);
        }
      }
    }

    if (recentItemIds.isNotEmpty) {
      final recentDocs = await Future.wait(
        recentItemIds.map((id) => _db.collection('items').doc(id).get()),
      );
      for (final itemDoc in recentDocs) {
        final category = (itemDoc.data()?['category'] ?? '').toString().trim();
        if (category.isNotEmpty) interests.add(category);
      }
    }

    final latest = await _db
        .collection('items')
        .orderBy('timestamp', descending: true)
        .limit(40)
        .get();
    final latestItems = latest.docs
        .map((doc) => ItemModel.fromMap(doc.data(), doc.id))
        .toList();

    if (interests.isEmpty) {
      return latestItems.take(limit).toList();
    }

    final preferred = latestItems
        .where((item) => interests.contains(item.category))
        .toList();
    if (preferred.length >= limit) {
      return preferred.take(limit).toList();
    }

    final merged = <ItemModel>[...preferred];
    for (final item in latestItems) {
      if (merged.any((e) => e.id == item.id)) continue;
      merged.add(item);
      if (merged.length >= limit) break;
    }
    return merged;
  }
}