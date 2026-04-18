import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Bookings'),
        bottom: TabBar(
          controller: _controller,
          indicatorColor: colors.accent,
          labelColor: colors.primaryText,
          unselectedLabelColor: colors.secondaryText,
          tabs: const [Tab(text: 'My Orders'), Tab(text: 'My Sales')],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          _BookingList(stream: FirebaseService.getOrders(email)),
          _BookingList(stream: FirebaseService.getSales(email)),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  const _BookingList({required this.stream});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: colors.accent));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load bookings: ${snapshot.error}',
              style: TextStyle(color: Colors.red[300]),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text('No data', style: TextStyle(color: colors.secondaryText)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final status = (data['status'] ?? 'pending').toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Item ID: ${(data['itemId'] ?? '').toString()}',
                          style: TextStyle(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buyer: ${(data['buyerEmail'] ?? '').toString()}',
                          style: TextStyle(color: colors.secondaryText, fontSize: 12),
                        ),
                        Text(
                          'Seller: ${(data['sellerEmail'] ?? '').toString()}',
                          style: TextStyle(color: colors.secondaryText, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: status == 'confirmed'
                          ? Colors.green.withAlpha(36)
                          : colors.overlay,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status == 'confirmed' ? 'Confirmed' : 'Pending',
                      style: TextStyle(
                        color: status == 'confirmed' ? Colors.green : colors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
