import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/wishlist_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/image_display.dart';
import '../models/product_model.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}



class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Tous'; // Track selected category

  @override
  void initState() {
    super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) async {
       final productProvider = context.read<ProductProvider>();
       await productProvider.loadProducts();
       // Sync wishlist with products
       final wishlistProvider = context.read<WishlistProvider>();
       wishlistProvider.syncFavorites(productProvider.products);
    });
  }





  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.read<CartProvider>();
    final wishlistProvider = context.watch<WishlistProvider>();

    // Filter by search query and category
    var filteredProducts = productProvider.products
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    // Filter by category
    if (_selectedCategory != 'Tous') {
      filteredProducts = filteredProducts
          .where((p) => p.name.toLowerCase().contains(_selectedCategory.toLowerCase()))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique Outils'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${wishlistProvider.favorites.length}'),
              child: const Icon(Icons.favorite),
            ),
            onPressed: () => context.go('/wishlist'),
            tooltip: 'Wishlist',
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.go('/cart'),
            tooltip: 'Panier',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
        ),
      ),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 10),
          CategoryFilters(
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() => _selectedCategory = category);
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text('Aucun produit trouvé'),
                  )
                : GridView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: filteredProducts.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2 / 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (ctx, i) => ProductGridTile(
                product: filteredProducts[i],
                onAddToCart: () =>
                    cartProvider.addToCart(filteredProducts[i]),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/product-form'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CategoryFilters extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;
  
  const CategoryFilters({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ['Tous', 'Marteaux', 'Tournevis', 'Clés', 'Perceuse'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                onCategorySelected(category);
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.blue[100],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ProductGridTile extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductGridTile({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final isFavorite = wishlist.isFavorite(product.id);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: ImageDisplay(
                  imageUrl: product.image,
                  height: 120,
                  width: double.infinity,
                ),
              ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                ),
                onPressed: () => wishlist.toggleFavorite(product),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${product.price.toStringAsFixed(2)} DT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          child: IconButton(
                            iconSize: 16,
                            icon: const Icon(Icons.add),
                            onPressed: onAddToCart,
                          ),
                        ),
                        const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.orange,
                          child: IconButton(
                            iconSize: 16,
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () {
                              context.go('/product-form', extra: product);
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.red,
                          child: IconButton(
                            iconSize: 16,
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Supprimer'),
                                  content: const Text('Êtes-vous sûr ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && context.mounted) {
                                await context.read<ProductProvider>().deleteProduct(product.id);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
