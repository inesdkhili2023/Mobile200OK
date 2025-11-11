import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/image_display.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Panier'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () { /* No action needed */ },
          ),
        ],
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text("Votre panier est vide"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final cartItem = cart.items.values.toList()[i];
                      return CartItemTile(item: cartItem);
                    },
                  ),
                ),
                const OrderSummary(),
              ],
            ),
    );
  }
}

class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ImageDisplay(imageUrl: item.image, width: 80, height: 80),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${item.price.toStringAsFixed(2)} DT', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.remove), onPressed: () => cart.removeSingleItem(item.id)),
                Text('${item.quantity}'),
                IconButton(icon: const Icon(Icons.add), onPressed: () => cart.addToCart(item.toProduct())),
              ],
            ),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => cart.removeItem(item.id)),
          ],
        ),
      ),
    );
  }
}

class OrderSummary extends StatefulWidget {
  const OrderSummary({super.key});

  @override
  State<OrderSummary> createState() => _OrderSummaryState();
}

class _OrderSummaryState extends State<OrderSummary> {
  bool _isLoading = false;

  Future<void> _checkout(BuildContext context) async {
    final cart = context.read<CartProvider>();
    
    // Show email input dialog
    final emailController = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Email for Receipt'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(hintText: 'your.email@example.com'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, emailController.text),
            child: const Text('Send Receipt'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final success = await cart.checkout(userEmail: email);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Order confirmed! Receipt sent to $email'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/'); // Return to home
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Failed to send receipt. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sous-total', style: TextStyle(fontSize: 16)),
              Text('${cart.totalAmount.toStringAsFixed(2)} DT', style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TVA (19%)', style: TextStyle(fontSize: 16)),
              Text('${(cart.totalAmount * 0.19).toStringAsFixed(2)} DT', style: const TextStyle(fontSize: 16)),
            ],
          ),
          const Divider(height: 20, thickness: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('${(cart.totalAmount * 1.19).toStringAsFixed(2)} DT', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _isLoading ? null : () => _checkout(context),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Passer la commande'),
          ),
        ],
      ),
    );
  }
}
