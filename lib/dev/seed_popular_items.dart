import '../services/firebase_service.dart';

/// Inserts a set of popular demo items into Firestore.
///
/// Safe to run multiple times (but will create duplicates).
Future<void> seedPopularItems() async {
  const ownerEmail = 'demo@vit.edu';

  final items = <Map<String, dynamic>>[
    {
      'title': 'Laptop',
      'description': 'Lightweight performance laptop, perfect for coding and classes.',
      'price': 39999.0,
      'category': 'Electronics',
      'imageUrl':
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Charger',
      'description': 'Fast charger (USB-C PD). Works with most modern laptops/phones.',
      'price': 899.0,
      'category': 'Electronics',
      'imageUrl':
          'https://images.unsplash.com/photo-1583863788434-e58a36330f19?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Tablet',
      'description': 'Great for notes, PDFs, and online classes. Includes a case.',
      'price': 12999.0,
      'category': 'Electronics',
      'imageUrl':
          'https://images.unsplash.com/photo-1561154464-82e9adf32736?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Hostel Room',
      'description': 'Hostel essentials bundle: storage boxes, hanger set, and lamp.',
      'price': 1599.0,
      'category': 'Furniture',
      'imageUrl':
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Furniture',
      'description': 'Sturdy study table with a compact footprint—ideal for hostel.',
      'price': 2499.0,
      'category': 'Furniture',
      'imageUrl':
          'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Arduino Kit',
      'description': 'Arduino starter kit with breadboard, jumpers, sensors, and LEDs.',
      'price': 1799.0,
      'category': 'Electronics',
      'imageUrl':
          'https://images.unsplash.com/photo-1553406830-ef2513450d76?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'ESP32 Sensor',
      'description': 'ESP32 dev board + basic sensor pack for IoT projects.',
      'price': 699.0,
      'category': 'Electronics',
      'imageUrl':
          'https://images.unsplash.com/photo-1555617117-08fda9c4e1b4?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Soldering Iron',
      'description': 'Temperature-controlled soldering iron—clean joints, quick heat-up.',
      'price': 1199.0,
      'category': 'Electronics',
      'imageUrl':
          'https://images.unsplash.com/photo-1563770660941-20978e870e26?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Glue Gun',
      'description': 'Hot glue gun for DIY, prototypes, and quick repairs.',
      'price': 349.0,
      'category': 'Stationery',
      'imageUrl':
          'https://images.unsplash.com/photo-1593113598332-cd59a93e5ed9?auto=format&fit=crop&w=1200&q=80',
    },
  ];

  for (final item in items) {
    await FirebaseService.addItem(
      title: item['title'] as String,
      description: item['description'] as String,
      price: item['price'] as double,
      imageUrl: item['imageUrl'] as String,
      ownerEmail: ownerEmail,
      category: item['category'] as String,
    );
  }
}

