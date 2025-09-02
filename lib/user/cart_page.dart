import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project/user/product_page.dart';

import 'checkout.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final user = FirebaseAuth.instance.currentUser!;

  Future<void> _removeItem(String docId, String title) async {
    await FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('🗑️ "$title" removed from cart')));
  }

  Future<void> _updateQuantity(
      String docId,
      int newQuantity,
      dynamic unitPrice,
      ) async {
    if (newQuantity > 0) {
      double price = 0;
      if (unitPrice is int) {
        price = unitPrice.toDouble();
      } else if (unitPrice is double) {
        price = unitPrice;
      } else {
        price = double.tryParse(unitPrice.toString()) ?? 0;
      }

      await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(docId)
          .update({
        'quantity': newQuantity,
        'totalPrice': price * newQuantity,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "🛒  My Cart",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(width: 1.5, color: Colors.white24),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .doc(user.uid)
            .collection('items')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                '🛒 Your cart is empty!',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          final items = snapshot.data!.docs;
          double totalPrice = items.fold(
            0,
                (sum, doc) => sum + (doc['totalPrice'] as num),
          );

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.transparent, // transparent background
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.red, Colors.yellow],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(2), // 👈 thickness of gradient border
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // glass effect
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1), // translucent bg
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  size: 28,
                                  color: Colors.white70, // overridden by gradient
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      onDismissed: (_) => _removeItem(doc.id, data['title']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withOpacity(0.4),
                              Colors.red.withOpacity(0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  width: 1.2,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      base64Decode(data['image']),
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              data['title'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Colors.orange,
                                                    Colors.red,
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                "Rs. ${data['unitPrice']}",
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        Text(
                                          "Weight: ${data['selectedWeight']}",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: Colors.white70,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove, color: Colors.white70, size: 15),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () {
                                                  final currentQty = data['quantity'] as int; // snapshot value
                                                  double unitPrice = 0;
                                                  if (data['unitPrice'] is int) {
                                                    unitPrice = (data['unitPrice'] as int).toDouble();
                                                  } else if (data['unitPrice'] is double) {
                                                    unitPrice = data['unitPrice'] as double;
                                                  } else {
                                                    unitPrice = double.tryParse(data['unitPrice'].toString()) ?? 0;
                                                  }

                                                  if (currentQty > 1) {
                                                    _updateQuantity(doc.id, currentQty - 1, unitPrice);
                                                  }
                                                },
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${data['quantity']}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              IconButton(
                                                icon: const Icon(Icons.add, color: Colors.white70, size: 15),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () {
                                                  final currentQty = data['quantity'] as int; // snapshot value
                                                  double unitPrice = 0;
                                                  if (data['unitPrice'] is int) {
                                                    unitPrice = (data['unitPrice'] as int).toDouble();
                                                  } else if (data['unitPrice'] is double) {
                                                    unitPrice = data['unitPrice'] as double;
                                                  } else {
                                                    unitPrice = double.tryParse(data['unitPrice'].toString()) ?? 0;
                                                  }

                                                  _updateQuantity(doc.id, currentQty + 1, unitPrice);
                                                },
                                              ),

                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.7),
                      Colors.red.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rs ${totalPrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CheckoutPage()),
                        );
                      },
                      child: const Text(
                        "Proceed",
                        style: TextStyle(
                          color: Colors.white,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}




